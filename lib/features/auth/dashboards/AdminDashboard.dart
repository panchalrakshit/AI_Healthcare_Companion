import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'admin/admin_analytics.dart';
import 'admin/admin_account_dialog.dart';
import '../login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _selected = 0;
  String _search = '';
  int _days = 30;
  String _filter = 'all';
  final Set<String> _busy = {};
  late final _usersStream = _db.collection('users').snapshots();
  late final _doctorsStream = _db.collection('doctors').snapshots();
  late final _appointmentsStream = _db.collection('appointments').snapshots();
  static const _titles = ['Overview', 'Patients', 'Doctors', 'Appointments'];
  static const _icons = [Icons.dashboard_outlined, Icons.people_outline, Icons.medical_services_outlined, Icons.calendar_month_outlined];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F6FB),
    body: LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 850) {
        return Scaffold(
          appBar: AppBar(title: Text(_titles[_selected]), backgroundColor: Colors.white, foregroundColor: const Color(0xFF242044)),
          drawer: Drawer(child: _sidebar(close: true)),
          body: _content(),
        );
      }
      return Row(children: [SizedBox(width: 245, child: _sidebar()), Expanded(child: _content())]);
    }),
  );

  Widget _sidebar({bool close = false}) => Container(
    color: Colors.white,
    child: SafeArea(child: Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 22, 20, 30),
        child: Row(children: [
          CircleAvatar(backgroundColor: Color(0xFFEFE7FF), child: Icon(Icons.health_and_safety, color: Color(0xFF6335D6))),
          SizedBox(width: 12),
          Expanded(child: Text('HealthCompanion', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Align(alignment: Alignment.centerLeft, child: Text('ADMIN PANEL', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: Color(0xFF8A8595), fontWeight: FontWeight.w700))),
      ),
      const SizedBox(height: 12),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _titles.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: ListTile(
            selected: _selected == i,
            selectedTileColor: const Color(0xFF6335D6),
            selectedColor: Colors.white,
            textColor: const Color(0xFF575268),
            iconColor: const Color(0xFF575268),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: Icon(_icons[i]),
            title: Text(_titles[i], style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              setState(() { _selected = i; _search = ''; _filter = 'all'; });
              if (close) Navigator.pop(context);
            },
          ),
        ),
      )),
      Padding(
        padding: const EdgeInsets.all(12),
        child: ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), onTap: _logout),
      ),
    ])),
  );

  Widget _content() {
    if (_selected == 1) return _users('patient');
    if (_selected == 2) return _users('doctor');
    if (_selected == 3) return _appointments();
    return _overview();
  }

  Widget _shell(String title, String subtitle, Widget child, {bool search = false, Widget? action}) => SafeArea(
    child: Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(22),
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF242044))),
            const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: Color(0xFF777384))),
          ])), if (action != null) action]),
          if (search) ...[
            const SizedBox(height: 16),
            TextField(key: ValueKey('search-$_selected'), onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              decoration: InputDecoration(hintText: 'Search by name, email or specialty…', prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: const Color(0xFFF7F6FB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: (_selected == 3 ? ['all', 'pending', 'confirmed', 'completed', 'cancelled'] : ['all', 'active', 'suspended']).map((f) => ChoiceChip(
              label: Text(f.toUpperCase()), selected: _filter == f, onSelected: (_) => setState(() => _filter = f))).toList()),
          ],
        ]),
      ),
      Expanded(child: child),
    ]),
  );

  Widget _withData(Widget Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>, List<QueryDocumentSnapshot<Map<String, dynamic>>>, List<QueryDocumentSnapshot<Map<String, dynamic>>>) builder) =>
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _usersStream, builder: (context, users) {
      if (users.hasError) return _error('Unable to load user profiles. Check admin permissions.');
      if (!users.hasData) return const Center(child: CircularProgressIndicator());
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _doctorsStream, builder: (context, doctors) {
        if (doctors.hasError) return _error('Unable to load the doctor directory. Check admin permissions.');
        if (!doctors.hasData) return const Center(child: CircularProgressIndicator());
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _appointmentsStream, builder: (context, appointments) {
          if (appointments.hasError) return _error('Unable to load appointments. Check admin permissions.');
          if (!appointments.hasData) return const Center(child: CircularProgressIndicator());
          return builder(users.data!.docs, doctors.data!.docs, appointments.data!.docs);
        });
      });
    });

  List<_AdminAccount> _accounts(List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> doctors, String role) {
    final profiles = {for (final u in users) u.id: u};
    if (role == 'patient') return users.where((u) => u.data()['role'] == 'patient')
      .map((u) => _AdminAccount(uid: u.id, data: u.data())).toList();
    final result = <_AdminAccount>[];
    final linked = <String>{};
    for (final d in doctors) {
      final x = d.data();
      final link = x['uid']?.toString() ?? d.id;
      final user = profiles[link];
      final uid = user != null && user.data()['role'] == 'doctor' ? link : null;
      if (uid != null && linked.contains(uid)) continue;
      if (uid != null) linked.add(uid);
      result.add(_AdminAccount(uid: uid, doctorId: d.id, data: {...x, if (uid != null) ...user!.data()}));
    }
    for (final u in users.where((u) => u.data()['role'] == 'doctor' && !linked.contains(u.id))) {
      result.add(_AdminAccount(uid: u.id, data: u.data()));
    }
    return result;
  }

  Widget _overview() => _shell('Admin Dashboard', 'Live insights and account management.',
    _withData((users, doctors, appointments) {
      final patients = _accounts(users, doctors, 'patient');
      final physicians = _accounts(users, doctors, 'doctor');
      final pending = appointments.where((a) => (a.data()['status'] ?? 'pending') == 'pending').length;
      final recent = [...appointments]..sort((a, b) => (adminDate(b.data()['createdAt']) ?? adminDate(b.data()['appointmentDate']) ?? DateTime(1970))
        .compareTo(adminDate(a.data()['createdAt']) ?? adminDate(a.data()['appointmentDate']) ?? DateTime(1970)));
      return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4B258D), Color(0xFF8060DB)]), borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your platform at a glance', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8), Text('$pending pending appointments need attention.', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16), Wrap(spacing: 10, runSpacing: 10, children: [
              FilledButton.icon(onPressed: () => _editAccount('doctor'), icon: const Icon(Icons.person_add_alt_1), label: const Text('Add doctor')),
              FilledButton.icon(onPressed: () => _editAccount('patient'), icon: const Icon(Icons.person_add_alt_1), label: const Text('Add patient')),
            ]),
          ])),
        const SizedBox(height: 20),
        Wrap(spacing: 14, runSpacing: 14, children: [
          _metric('Patients', patients.length, Icons.people_outline),
          _metric('Doctors', physicians.length, Icons.medical_services_outlined),
          _metric('Appointments', appointments.length, Icons.calendar_month_outlined),
          _metric('Pending', pending, Icons.pending_actions_outlined),
          _metric('Suspended', [...patients, ...physicians].where((u) => u.data['status'] == 'suspended').length, Icons.person_off_outlined),
        ]),
        const SizedBox(height: 28),
        AdminAnalytics(appointments: appointments.map((a) => a.data()).toList(), users: users.map((u) => u.data()).toList(),
          days: _days, onDaysChanged: (d) => setState(() => _days = d)),
        const SizedBox(height: 28),
        const Text('Recent appointments', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        if (recent.isEmpty) _empty('No appointments yet.')
        else Container(decoration: _card(), child: Column(children: recent.take(8).map((d) => _appointmentTile(d, compact: true)).toList())),
      ]));
    }));

  Widget _metric(String label, int value, IconData icon) => Container(
    width: 205,
    padding: const EdgeInsets.all(20),
    decoration: _card(),
    child: Row(children: [
      CircleAvatar(radius: 24, backgroundColor: const Color(0xFFEFE7FF), child: Icon(icon, color: const Color(0xFF6335D6))),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF777384))),
      ]),
    ]),
  );

  Widget _users(String role) => _shell(role == 'doctor' ? 'Doctors' : 'Patients',
    'Add, edit, activate, suspend or remove accounts.',
    _withData((users, doctors, appointments) {
      final accounts = _accounts(users, doctors, role).where((a) {
        final x = a.data;
        return (_filter == 'all' || (x['status'] ?? 'active') == _filter) &&
          (_search.isEmpty || ['name', 'fullName', 'email', 'phone', 'specialization'].any((k) => (x[k] ?? '').toString().toLowerCase().contains(_search)));
      }).toList()..sort((a, b) => (a.data['name'] ?? '').toString().compareTo((b.data['name'] ?? '').toString()));
      if (accounts.isEmpty) return _empty('No matching $role accounts. Use Add to create one.');
      return ListView.separated(padding: const EdgeInsets.all(22), itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (_, i) => _userCard(accounts[i], role));
    }), search: true,
    action: FilledButton.icon(onPressed: () => _editAccount(role), icon: const Icon(Icons.add), label: const Text('Add')));

  Widget _userCard(_AdminAccount account, String role) {
    final x = account.data;
    final name = (x['name'] ?? x['fullName'] ?? 'Unnamed user').toString();
    final status = (x['status'] ?? 'active').toString();
    return Container(padding: const EdgeInsets.all(18), decoration: _card(), child: Row(children: [
      CircleAvatar(backgroundColor: const Color(0xFFEFE7FF), child: Icon(role == 'doctor' ? Icons.medical_services : Icons.person, color: const Color(0xFF6335D6))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 4), Text((x['email'] ?? 'No email').toString()),
        if (role == 'doctor') Text((x['specialization'] ?? 'No specialty').toString(), style: const TextStyle(color: Color(0xFF7352D6))),
        if (account.uid == null) const Text('Directory entry • no linked login', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ])),
      _status(status),
      if (_busy.contains(account.key)) const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
      else PopupMenuButton<String>(onSelected: (v) {
        if (v == 'edit') _editAccount(role, account: account);
        if (v == 'active' || v == 'suspended') _accountAction(account, 'adminSetAccountStatus', {'status': v});
        if (v == 'delete') _confirmDeleteAccount(account);
      }, itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit details')),
        PopupMenuItem(value: 'active', child: Text('Activate account')),
        PopupMenuItem(value: 'suspended', child: Text('Suspend account')),
        PopupMenuDivider(), PopupMenuItem(value: 'delete', child: Text('Remove account')),
      ]),
    ]));
  }

  Future<void> _call(String name, Map<String, dynamic> data) async {
    try { await FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(name).call(data); }
    on FirebaseFunctionsException catch (e) {
      if (['not-found', 'unavailable', 'unimplemented'].contains(e.code)) {
        throw Exception('Account service is unavailable. Ask the project owner to deploy the admin functions.');
      }
      throw Exception(e.message ?? 'Account operation failed (${e.code}).');
    }
  }

  Future<void> _editAccount(String role, {_AdminAccount? account}) async {
    final saved = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => AdminAccountDialog(
      role: role, initial: account?.data, onSave: (fields) => _call(account == null ? 'adminCreateAccount' : 'adminUpdateAccount',
        {...fields, if (account == null) 'role': role, if (account != null) ...account.target}),
    ));
    if (saved == true) _message(account == null ? 'Account created successfully.' : 'Account updated.');
  }

  Future<void> _accountAction(_AdminAccount account, String function, Map<String, dynamic> fields) async {
    if (_busy.contains(account.key)) return;
    setState(() => _busy.add(account.key));
    try { await _call(function, {...account.target, ...fields}); _message('Account updated.'); }
    catch (e) { _message(e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _busy.remove(account.key)); }
  }

  Future<void> _confirmDeleteAccount(_AdminAccount account) async {
    final name = (account.data['name'] ?? account.data['email'] ?? 'this account').toString();
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Remove account?'),
      content: Text(account.uid == null ? 'Remove $name from the doctor directory?'
        : 'Remove $name and their login account? Appointment and health history will be retained. This cannot be undone.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove'))],
    ));
    if (yes == true) await _accountAction(account, 'adminDeleteAccount', {});
  }

  Widget _appointments() => _shell(
    'Appointments',
    'Review and update appointment status.',
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _appointmentsStream,
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return _error('Unable to load appointments.');
        var docs = s.data?.docs ?? [];
        docs.sort((a, b) {
          final ad = a.data()['appointmentDate'];
          final bd = b.data()['appointmentDate'];
          if (ad is Timestamp && bd is Timestamp) return bd.compareTo(ad);
          return 0;
        });
        docs = docs.where((d) => _filter == 'all' || (d.data()['status'] ?? 'pending') == _filter).toList();
        if (_search.isNotEmpty) {
          docs = docs.where((d) {
            final x = d.data();
            return ['doctorName', 'patientName', 'patientEmail', 'reason', 'status', 'specialization'].map((k) => (x[k] ?? '').toString().toLowerCase()).any((v) => v.contains(_search));
          }).toList();
        }
        if (docs.isEmpty) return _empty('No appointments found.');
        return ListView.separated(
          padding: const EdgeInsets.all(28),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _appointmentTile(docs[i]),
        );
      },
    ),
    search: true,
  );

  Widget _appointmentTile(QueryDocumentSnapshot<Map<String, dynamic>> doc, {bool compact = false}) {
    final x = doc.data();
    final doctor = (x['doctorName'] ?? 'Doctor').toString();
    final patient = (x['patientName'] ?? x['patientEmail'] ?? 'Patient').toString();
    final status = (x['status'] ?? 'pending').toString().toLowerCase();
    final reason = (x['reason'] ?? '').toString();
    final date = x['appointmentDate'];
    String dateText = 'Date not set';
    if (date is Timestamp) {
      final d = date.toDate();
      dateText = d.day.toString().padLeft(2, '0') + '/' + d.month.toString().padLeft(2, '0') + '/' + d.year.toString();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: compact ? null : _card(),
      child: Row(children: [
        const CircleAvatar(backgroundColor: Color(0xFFEFE7FF), child: Icon(Icons.calendar_today, color: Color(0xFF6335D6), size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(patient + ' → ' + doctor, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(dateText + (reason.isEmpty ? '' : ' • ' + reason), style: const TextStyle(fontSize: 12, color: Color(0xFF777384))),
        ])),
        _status(status),
        if (!compact) ...[
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') { _deleteAppointment(doc); }
              else { _setAppointmentStatus(doc.id, v); }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pending', child: Text('Mark pending')),
              PopupMenuItem(value: 'confirmed', child: Text('Confirm')),
              PopupMenuItem(value: 'completed', child: Text('Mark completed')),
              PopupMenuItem(value: 'cancelled', child: Text('Cancel')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: Text('Delete appointment')),
            ],
          ),
        ],
      ]),
    );
  }

  Widget _status(String value) {
    Color color;
    if (['active', 'confirmed', 'completed'].contains(value)) {
      color = const Color(0xFF168A62);
    } else if (['suspended', 'cancelled'].contains(value)) {
      color = const Color(0xFFC74747);
    } else {
      color = const Color(0xFFB7791F);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(20)),
      child: Text(value.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Future<void> _setAppointmentStatus(String id, String status) async {
    try {
      await _db.collection('appointments').doc(id).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
      _message('Appointment marked ' + status + '.');
    } catch (e) { _message('Could not update appointment: ' + e.toString()); }
  }

  Future<void> _deleteAppointment(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete appointment?'), content: const Text('This permanently removes the appointment record.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
    if (yes == true) {
      try { await doc.reference.delete(); _message('Appointment deleted.'); }
      catch (e) { _message('Could not delete appointment: $e'); }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _empty(String text) => Center(child: Text(text, style: const TextStyle(color: Color(0xFF777384))));
  Widget _error(String text) => Center(child: Text(text, style: const TextStyle(color: Colors.redAccent)));
  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: const Color(0xFFE8E4EF)),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.025), blurRadius: 12, offset: const Offset(0, 5))],
  );
}


class _AdminAccount {
  final String? uid;
  final String? doctorId;
  final Map<String, dynamic> data;
  _AdminAccount({this.uid, this.doctorId, required this.data});
  String get key => doctorId ?? uid!;
  Map<String, dynamic> get target => {if (uid != null) 'uid': uid, if (doctorId != null) 'doctorId': doctorId};
}
