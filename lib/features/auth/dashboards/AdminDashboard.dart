import 'package:cloud_firestore/cloud_firestore.dart';
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
              setState(() { _selected = i; _search = ''; });
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

  Widget _shell(String title, String subtitle, Widget child, {bool search = false}) => SafeArea(
    child: Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 18),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF242044))),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF777384))),
          ])),
          if (search) SizedBox(
            width: 280,
            child: TextField(
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
              decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search), isDense: true, filled: true, fillColor: const Color(0xFFF7F6FB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
          ),
        ]),
      ),
      Expanded(child: child),
    ]),
  );

  Widget _overview() => _shell(
    'Admin Dashboard',
    'Monitor users, appointments and platform activity.',
    SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('users').snapshots(),
          builder: (context, us) {
            final users = us.data?.docs ?? [];
            final patients = users.where((d) => (d.data()['role'] ?? '').toString().toLowerCase() == 'patient').length;
            final doctors = users.where((d) => (d.data()['role'] ?? '').toString().toLowerCase() == 'doctor').length;
            final inactive = users.where((d) => (d.data()['status'] ?? '').toString().toLowerCase() != 'active').length;
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('appointments').snapshots(),
              builder: (context, ap) {
                final appointments = ap.data?.docs ?? [];
                final pending = appointments.where((d) => (d.data()['status'] ?? 'pending').toString().toLowerCase() == 'pending').length;
                return Wrap(spacing: 16, runSpacing: 16, children: [
                  _metric('Patients', patients, Icons.people_outline),
                  _metric('Doctors', doctors, Icons.medical_services_outlined),
                  _metric('Appointments', appointments.length, Icons.calendar_month_outlined),
                  _metric('Pending', pending, Icons.pending_actions_outlined),
                  _metric('Inactive users', inactive, Icons.person_off_outlined),
                ]);
              },
            );
          },
        ),
        const SizedBox(height: 30),
        const Text('Recent appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        _recent(),
      ]),
    ),
  );

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

  Widget _recent() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _db.collection('appointments').limit(8).snapshots(),
    builder: (context, s) {
      if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (s.hasError) return _error('Unable to load appointments.');
      final docs = s.data?.docs ?? [];
      if (docs.isEmpty) return _empty('No appointments found.');
      return Container(decoration: _card(), child: Column(children: docs.map((d) => _appointmentTile(d, compact: true)).toList()));
    },
  );

  Widget _users(String role) {
    final plural = role == 'doctor' ? 'Doctors' : 'Patients';
    return _shell(
      plural,
      'View and manage registered ' + role + ' accounts.',
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('users').where('role', isEqualTo: role).snapshots(),
        builder: (context, s) {
          if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (s.hasError) return _error('Unable to load ' + plural + '.');
          var docs = s.data?.docs ?? [];
          if (_search.isNotEmpty) {
            docs = docs.where((d) {
              final x = d.data();
              return ['name', 'fullName', 'email', 'phone', 'specialization'].map((k) => (x[k] ?? '').toString().toLowerCase()).any((v) => v.contains(_search));
            }).toList();
          }
          if (docs.isEmpty) return _empty('No ' + plural + ' found.');
          return ListView.separated(
            padding: const EdgeInsets.all(28),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _userCard(docs[i], role),
          );
        },
      ),
      search: true,
    );
  }

  Widget _userCard(QueryDocumentSnapshot<Map<String, dynamic>> doc, String role) {
    final x = doc.data();
    final name = (x['name'] ?? x['fullName'] ?? 'Unnamed user').toString();
    final email = (x['email'] ?? 'No email').toString();
    final status = (x['status'] ?? 'active').toString().toLowerCase();
    final specialty = (x['specialization'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: Row(children: [
        CircleAvatar(radius: 25, backgroundColor: const Color(0xFFEFE7FF), child: Icon(role == 'doctor' ? Icons.medical_services : Icons.person, color: const Color(0xFF6335D6))),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: Color(0xFF777384), fontSize: 13)),
          if (specialty.isNotEmpty) Text(specialty, style: const TextStyle(color: Color(0xFF6335D6), fontSize: 12)),
        ])),
        _status(status),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'active' || v == 'suspended') _setUserStatus(doc.id, v);
            if (v == 'delete') _confirmDelete(doc);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'active', child: Text('Activate account')),
            PopupMenuItem(value: 'suspended', child: Text('Suspend account')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'delete', child: Text('Delete Firestore profile')),
          ],
        ),
      ]),
    );
  }

  Widget _appointments() => _shell(
    'Appointments',
    'Review and update appointment status.',
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('appointments').snapshots(),
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
            onSelected: (v) => _setAppointmentStatus(doc.id, v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pending', child: Text('Mark pending')),
              PopupMenuItem(value: 'confirmed', child: Text('Confirm')),
              PopupMenuItem(value: 'completed', child: Text('Mark completed')),
              PopupMenuItem(value: 'cancelled', child: Text('Cancel')),
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

  Future<void> _setUserStatus(String uid, String status) async {
    try {
      await _db.collection('users').doc(uid).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
      _message('Account marked ' + status + '.');
    } catch (e) { _message('Could not update account: ' + e.toString()); }
  }

  Future<void> _setAppointmentStatus(String id, String status) async {
    try {
      await _db.collection('appointments').doc(id).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
      _message('Appointment marked ' + status + '.');
    } catch (e) { _message('Could not update appointment: ' + e.toString()); }
  }

  Future<void> _confirmDelete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final x = doc.data();
    final name = (x['name'] ?? x['fullName'] ?? x['email'] ?? 'this user').toString();
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text('Delete the Firestore profile for ' + name + '? This does not delete the Firebase Authentication account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      try { await doc.reference.delete(); _message('Profile deleted.'); }
      catch (e) { _message('Could not delete profile: ' + e.toString()); }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
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
