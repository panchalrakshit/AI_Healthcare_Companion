import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorProfile extends StatefulWidget {
  final FirebaseFirestore db;
  final String uid;
  final Map<String, dynamic> profile;
  const DoctorProfile({super.key, required this.db, required this.uid, required this.profile});
  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}
class _DoctorProfileState extends State<DoctorProfile> {
  late final _directory = widget.db.collection('doctors').where('uid', isEqualTo: widget.uid).snapshots();
  late final _sameId = widget.db.collection('doctors').doc(widget.uid).snapshots();
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _directory, builder: (context, directory) {
    if (directory.hasError) return const Center(child: Text('Could not load doctor profile.'));
    if (!directory.hasData) return const Center(child: CircularProgressIndicator());
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: _sameId, builder: (context, sameId) {
      if (sameId.hasError) return const Center(child: Text('Could not load doctor directory.'));
      if (!sameId.hasData) return const Center(child: CircularProgressIndicator());
      final docs = <String, DocumentSnapshot<Map<String, dynamic>>>{for (final d in directory.data!.docs) d.id: d};
      if (sameId.data!.exists) docs[sameId.data!.id] = sameId.data!;
      final data = {...(docs.values.isEmpty ? <String, dynamic>{} : docs.values.first.data()!), ...widget.profile};
      return ListView(padding: const EdgeInsets.all(22), children: [
        const Text('My profile', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)), const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(radius: 34, backgroundColor: Color(0xFFE2F4F0), child: Icon(Icons.medical_services_outlined, size: 34, color: Color(0xFF087B75))), const SizedBox(height: 16),
          for (final key in ['name', 'email', 'phone', 'specialization', 'qualification', 'experience', 'hospital', 'availability']) Padding(padding: const EdgeInsets.only(bottom: 14), child: Text('${key.toUpperCase()}\n${data[key] ?? 'Not recorded'}')),
          Wrap(spacing: 10, runSpacing: 10, children: [FilledButton.icon(onPressed: () => _edit(data, docs.values.toList()), icon: const Icon(Icons.edit_outlined), label: const Text('Edit profile')),
            OutlinedButton(onPressed: () async {
              try { await FirebaseAuth.instance.sendPasswordResetEmail(email: FirebaseAuth.instance.currentUser!.email!); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.'))); }
              catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send password reset email.'))); }
            }, child: const Text('Reset password'))]),
          if (docs.isEmpty) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Ask your admin to create or link your doctor directory listing.')),
        ])),
      ]);
    });
  });
  Future<void> _edit(Map<String, dynamic> data, List<DocumentSnapshot<Map<String, dynamic>>> docs) => showDialog<void>(context: context, barrierDismissible: false,
    builder: (_) => DoctorProfileForm(initial: data, hasDirectory: docs.isNotEmpty, onSave: (fields) async {
      final batch = widget.db.batch();
      batch.update(widget.db.collection('users').doc(widget.uid), {...fields, 'updatedAt': FieldValue.serverTimestamp()});
      for (final doc in docs) { batch.update(doc.reference, {...fields, 'updatedAt': FieldValue.serverTimestamp()}); }
      await batch.commit();
      await FirebaseAuth.instance.currentUser?.updateDisplayName(fields['name'] as String);
    }));
}

class DoctorProfileForm extends StatefulWidget {
  final Map<String, dynamic> initial;
  final bool hasDirectory;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const DoctorProfileForm({super.key, required this.initial, required this.hasDirectory, required this.onSave});
  @override
  State<DoctorProfileForm> createState() => _DoctorProfileFormState();
}
class _DoctorProfileFormState extends State<DoctorProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _fields = ['name', 'phone', if (widget.hasDirectory) ...['specialization', 'qualification', 'experience', 'hospital', 'availability']];
  late final _controllers = {for (final key in _fields) key: TextEditingController(text: widget.initial[key]?.toString() ?? '')};
  bool _saving = false;
  String? _error;
  @override
  void dispose() { for (final c in _controllers.values) { c.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_saving, child: AlertDialog(title: const Text('Edit doctor profile'),
    content: SizedBox(width: 480, child: SingleChildScrollView(child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [
      ..._fields.map((key) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(controller: _controllers[key], enabled: !_saving,
        maxLength: key == 'phone' ? 40 : 200, decoration: InputDecoration(labelText: key.toUpperCase(), border: const OutlineInputBorder(), counterText: ''),
        validator: (v) => key == 'name' && (v ?? '').trim().isEmpty ? 'Enter your name.' : null))),
      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
    ])))), actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: _saving ? null : () async {
      if (!_form.currentState!.validate()) return;
      setState(() { _saving = true; _error = null; });
      try { await widget.onSave({for (final e in _controllers.entries) e.key: e.value.text.trim()}); if (context.mounted) Navigator.pop(context); }
      catch (e) { if (mounted) setState(() { _saving = false; _error = 'Could not save profile. Check permissions and try again.'; }); }
    }, child: Text(_saving ? 'Saving…' : 'Save profile'))]));
}
