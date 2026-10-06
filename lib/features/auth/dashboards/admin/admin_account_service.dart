import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Spark-compatible account management. All profile writes use the admin's
/// default Firestore session; secondary Auth never replaces that session.
class AdminAccountService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> run(String action, Map<String, dynamic> input) async {
    final actor = FirebaseAuth.instance.currentUser;
    if (actor == null) throw Exception('Sign in as an admin.');
    final profile = await _db.collection('users').doc(actor.uid).get();
    if (profile.data()?['role'] != 'admin' || profile.data()?['status'] != 'active') {
      throw Exception('An active admin account is required.');
    }
    if (action == 'adminCreateAccount') {
      await _create(input, actor.uid);
      return;
    }
    String? uid = input['uid'] as String?;
    final doctorId = input['doctorId'] as String?;
    final directory = doctorId == null ? null : await _db.collection('doctors').doc(doctorId).get();
    if (doctorId != null && directory?.exists != true) throw Exception('Doctor no longer exists.');
    uid ??= directory?.data()?['uid'] as String?;
    if (uid == null && doctorId != null) {
      final sameId = await _db.collection('users').doc(doctorId).get();
      if (sameId.data()?['role'] == 'doctor') uid = doctorId;
    }
    final user = uid == null ? null : await _db.collection('users').doc(uid).get();
    if (user?.exists != true) uid = null;
    if (uid == null && directory == null) throw Exception('Account no longer exists.');
    if (uid == actor.uid || (uid != null && !['patient', 'doctor'].contains(user?.data()?['role']))) {
      throw Exception('Only patient and doctor accounts can be managed here.');
    }
    final refs = <String, DocumentReference<Map<String, dynamic>>>{};
    if (directory != null) refs[directory.id] = directory.reference;
    if (uid != null && user?.data()?['role'] == 'doctor') {
      final linked = await _db.collection('doctors').where('uid', isEqualTo: uid).get();
      for (final d in linked.docs) { refs[d.id] = d.reference; }
      final sameId = await _db.collection('doctors').doc(uid).get();
      if (sameId.exists) refs[sameId.id] = sameId.reference;
      if (refs.isEmpty && action != 'adminDeleteAccount') refs[uid] = _db.collection('doctors').doc(uid);
    }
    final batch = _db.batch();
    if (action == 'adminDeleteAccount') {
      if (uid != null) {
        batch.set(_db.collection('adminDeletedUsers').doc(uid), {'deletedAt': FieldValue.serverTimestamp(), 'deletedBy': actor.uid});
        batch.delete(_db.collection('users').doc(uid));
      }
      for (final ref in refs.values) { batch.delete(ref); }
    } else {
      final fields = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
      if (action == 'adminSetAccountStatus') {
        if (!['active', 'suspended'].contains(input['status'])) throw Exception('Invalid status.');
        fields['status'] = input['status'];
      } else if (action == 'adminUpdateAccount') {
        fields.addAll(_details(input));
        // Auth email cannot be changed for another user on Spark. Keep login
        // email stable; name and other profile/directory fields remain editable.
        if (uid != null && fields['email'] != user?.data()?['email']) {
          throw Exception('Login email cannot be changed here. The user can change it through Firebase Authentication.');
        }
      } else {
        throw Exception('Unknown account action.');
      }
      if (uid != null) batch.update(_db.collection('users').doc(uid), fields);
      for (final ref in refs.values) {
        batch.set(ref, {...fields, if (uid != null) 'uid': uid}, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }

  Map<String, dynamic> _details(Map<String, dynamic> input) => {
    for (final key in ['name', 'email', 'phone', 'specialization', 'qualification', 'experience', 'hospital', 'availability'])
      if (input[key] is String) key: (input[key] as String).trim(),
  };

  Future<void> _create(Map<String, dynamic> input, String actor) async {
    final role = input['role'];
    if (!['patient', 'doctor'].contains(role)) throw Exception('Choose patient or doctor.');
    final app = await Firebase.initializeApp(
      name: 'admin-create-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final auth = FirebaseAuth.instanceFor(app: app);
    User? created;
    bool committed = false;
    try {
      if (kIsWeb) await auth.setPersistence(Persistence.NONE);
      final fields = _details(input);
      final credential = await auth.createUserWithEmailAndPassword(email: fields['email'] as String, password: input['password'] as String);
      created = credential.user!;
      await created.updateDisplayName(fields['name'] as String);
      final record = {...fields, 'uid': created.uid, 'role': role, 'status': 'active', 'createdAt': FieldValue.serverTimestamp(), 'createdBy': actor};
      final batch = _db.batch();
      batch.set(_db.collection('users').doc(created.uid), record);
      if (role == 'doctor') batch.set(_db.collection('doctors').doc(created.uid), record);
      if (role == 'patient') batch.set(_db.collection('healthProfiles').doc(created.uid), {'uid': created.uid, 'createdAt': FieldValue.serverTimestamp()});
      await batch.commit();
      committed = true;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code == 'email-already-in-use'
        ? 'This email already has a login account. Use a different email or manage it in Firebase Console.'
        : e.message ?? 'Could not create the login account.');
    } finally {
      if (!committed && created != null) {
        // The secondary session can delete only the account it just created.
        await created.delete().catchError((Object _) {});
      }
      await auth.signOut();
      await app.delete();
    }
  }
}
