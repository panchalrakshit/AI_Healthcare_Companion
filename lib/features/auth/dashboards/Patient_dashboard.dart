import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../appointments/appointmentscreen.dart';
import '../login/login_screen.dart';
import 'patient/patient_data.dart';
import 'patient/patient_forms.dart';
import 'patient/patient_records.dart';
import 'patient/patient_widgets.dart';
import 'patient/symptom_checker.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});
  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}
class _PatientDashboardState extends State<PatientDashboard> {
  PatientRepository? _repository;
  StreamSubscription<User?>? _auth;
  @override
  void initState() {
    super.initState();
    _bind(FirebaseAuth.instance.currentUser);
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_repository?.uid != user?.uid && mounted) setState(() => _bind(user));
    });
  }
  void _bind(User? user) {
    _repository?.dispose();
    _repository = user == null ? null : PatientRepository(FirebaseFirestore.instance, user.uid);
  }
  @override
  void dispose() { _auth?.cancel(); _repository?.dispose(); super.dispose(); }
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } catch (_) { if (mounted) _message('Unable to sign out. Try again.'); }
  }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _edit(String kind, PatientSnapshot data, {Map<String, dynamic>? record}) async {
    final repository = _repository;
    if (repository == null) return;
    final db = repository.db;
    final uid = repository.uid;
    final result = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => PatientEditor(
      kind: kind, initial: record ?? (kind == 'Profile' ? data.user : {}), onSave: (fields) async {
        if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('Session changed.');
        if (kind == 'Profile') {
          await db.collection('users').doc(uid).update({...fields, 'updatedAt': FieldValue.serverTimestamp()});
        } else if (kind == 'Reading') {
          final measuredAt = Timestamp.now();
          final newRecord = db.collection('healthRecords').doc();
          final profile = db.collection('healthProfiles').doc(uid);
          await db.runTransaction((transaction) async {
            final old = (await transaction.get(profile)).data() ?? {};
            final weight = patientNumber(fields['weight'] ?? old['weight']);
            final height = patientNumber(fields['height'] ?? old['height']);
            transaction.set(profile, {
              ...fields, 'uid': uid, 'updatedAt': FieldValue.serverTimestamp(), 'lastCheckup': measuredAt,
              if (weight != null && height != null && height > 0) 'bmi': weight / ((height / 100) * (height / 100)),
            }, SetOptions(merge: true));
            transaction.set(newRecord, {
              'patientId': uid, 'title': 'Measured health readings', 'recordType': 'Vital Signs',
              'vitals': fields, 'measuredAt': measuredAt, 'recordDate': measuredAt,
              'createdAt': FieldValue.serverTimestamp(),
            });
          });
        } else if (record != null) {
          await db.collection('healthRecords').doc(record['id'] as String).update({...fields, 'updatedAt': FieldValue.serverTimestamp()});
        } else {
          await db.collection('healthRecords').add({...fields, 'patientId': uid, 'createdAt': FieldValue.serverTimestamp()});
        }
      }));
    if (result == true && mounted) _message('Saved successfully.');
  }
  Future<void> _delete(Map<String, dynamic> record) async {
    final repository = _repository;
    if (repository == null) return;
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete this record?'),
      content: Text(record['vitals'] is Map ? 'This removes the history entry. Your latest health profile values remain saved.' : 'This permanently removes the record from your account.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep record')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
    ));
    if (confirmed != true) return;
    try {
      if (FirebaseAuth.instance.currentUser?.uid != repository.uid) return;
      await repository.db.collection('healthRecords').doc(record['id'] as String).delete();
      if (mounted) _message('Record deleted.');
    } on FirebaseException catch (e) { if (mounted) _message(e.message ?? 'Could not delete record.'); }
  }
  Future<void> _resetPassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _message('Password reset email requested. Check your inbox.');
    } on FirebaseAuthException catch (e) { if (mounted) _message(e.message ?? 'Could not send reset email.'); }
  }
  @override
  Widget build(BuildContext context) {
    final repository = _repository;
    if (repository == null) return Scaffold(body: Center(child: FilledButton(onPressed: _logout, child: const Text('Return to login'))));
    return StreamBuilder<PatientSnapshot>(stream: repository.stream, initialData: repository.current, builder: (context, snapshot) {
      final data = snapshot.data ?? repository.current;
      if (!data.loading.contains('Profile') && !data.errors.containsKey('Profile') && (data.user.isEmpty || data.user['role'] != 'patient' || (data.user['status'] ?? 'active') != 'active')) {
        return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Your patient account is unavailable. Contact your administrator.'),
          const SizedBox(height: 20), FilledButton(onPressed: _logout, child: const Text('Sign out')),
        ])));
      }
      return PatientWorkspace(key: ValueKey(repository.uid), data: data,
        onReading: () => _edit('Reading', data), onProfile: () => _edit('Profile', data), onAddRecord: () => _edit('Record', data),
        onEditRecord: (r) => _edit('Record', data, record: r), onDeleteRecord: _delete,
        onLogout: _logout, onResetPassword: _resetPassword, onRetry: () => setState(() => _bind(FirebaseAuth.instance.currentUser)));
    });
  }
}

class PatientWorkspace extends StatefulWidget {
  final PatientSnapshot data;
  final VoidCallback onReading, onProfile, onAddRecord, onLogout, onResetPassword, onRetry;
  final ValueChanged<Map<String, dynamic>> onEditRecord, onDeleteRecord;
  const PatientWorkspace({super.key, required this.data, required this.onReading, required this.onProfile, required this.onAddRecord,
    required this.onEditRecord, required this.onDeleteRecord, required this.onLogout, required this.onResetPassword, required this.onRetry});
  @override
  State<PatientWorkspace> createState() => _PatientWorkspaceState();
}
class _PatientWorkspaceState extends State<PatientWorkspace> {
  int _page = 0, _days = 30;
  bool _exporting = false;
  static const _pages = ['Overview', 'Health insights', 'Health records', 'Appointments', 'Reminders', 'My profile', 'Symptom checker'];
  static const _icons = [Icons.space_dashboard_outlined, Icons.insights_outlined, Icons.folder_outlined, Icons.calendar_month_outlined, Icons.notifications_none_outlined, Icons.person_outline, Icons.psychology_outlined];
  PatientStats get _stats => PatientStats(widget.data, days: _days);
  void _select(int i) { setState(() => _page = i); }
  Widget _nav({bool drawer = false}) => SizedBox(width: 248, child: Material(color: Colors.white, child: SafeArea(child: Column(children: [
    const Padding(padding: EdgeInsets.fromLTRB(22, 28, 22, 25), child: Row(children: [Icon(Icons.favorite_rounded, color: patientPurple, size: 30), SizedBox(width: 10), Expanded(child: Text('Health\nCompanion', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: patientInk)))])),
    const Padding(padding: EdgeInsets.only(bottom: 20), child: Text('PATIENT WORKSPACE', style: TextStyle(fontSize: 10, letterSpacing: 2, color: patientMuted))),
    Expanded(child: ListView(children: List.generate(_pages.length, (i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), selected: _page == i, selectedTileColor: patientPurple, selectedColor: Colors.white,
      leading: Icon(_icons[i]), title: Text(_pages[i], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      onTap: () { if (drawer) Navigator.pop(context); _select(i); },
    ))))),
    Padding(padding: const EdgeInsets.all(14), child: ListTile(leading: const Icon(Icons.logout), title: const Text('Sign out'), onTap: widget.onLogout)),
  ]))));
  @override
  Widget build(BuildContext context) => Theme(data: Theme.of(context).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: patientPurple), scaffoldBackgroundColor: patientBackground,
    textTheme: Theme.of(context).textTheme.apply(bodyColor: patientInk, displayColor: patientInk),
  ), child: LayoutBuilder(builder: (context, constraints) {
    final wide = constraints.maxWidth >= 1050;
    return Scaffold(
      backgroundColor: patientBackground,
      drawer: wide ? null : Drawer(child: _nav(drawer: true)),
      appBar: wide ? null : AppBar(title: Text(_pages[_page]), backgroundColor: Colors.white, actions: [IconButton(onPressed: widget.onReading, tooltip: 'Add reading', icon: const Icon(Icons.add_chart))]),
      body: Row(children: [if (wide) _nav(), Expanded(child: _page == 3 ? const AppointmentsScreen(embedded: true) : SingleChildScrollView(
        key: PageStorageKey('patient-page-$_page'), padding: EdgeInsets.all(wide ? 30 : 16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _header(), const SizedBox(height: 24),
          if (widget.data.loading.isNotEmpty) ...[const LinearProgressIndicator(), const SizedBox(height: 14), Text('Loading ${widget.data.loading.join(', ')}…'), const SizedBox(height: 16)],
          if (widget.data.errors.isNotEmpty) ...[Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Some live data could not be loaded.', style: TextStyle(fontWeight: FontWeight.bold)),
              ...widget.data.errors.entries.map((e) => Text('${e.key}: ${e.value}')),
              TextButton.icon(onPressed: widget.onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ])), const SizedBox(height: 18)],
          if (widget.data.loading.isEmpty && widget.data.errors.isEmpty || widget.data.user.isNotEmpty) _content(),
        ]),
      ))]),
    );
  }));
  Widget _header() => LayoutBuilder(builder: (context, constraints) {
    final compact = constraints.maxWidth < 600;
    final heading = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_page == 0 ? 'Welcome, ${widget.data.user['name'] ?? 'Patient'}' : _pages[_page],
        style: TextStyle(fontSize: compact ? 24 : 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      Text(_page == 0 ? 'Your care, records and progress in one place.' : 'Connected to your saved Firebase data',
        style: const TextStyle(color: patientMuted)),
    ]);
    final action = FilledButton.icon(onPressed: widget.onReading, icon: const Icon(Icons.add, size: 18), label: const Text('Add reading'));
    if (compact) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading, const SizedBox(height: 16), action,
    ]);
    return Row(children: [Expanded(child: heading), const SizedBox(width: 20), action]);
  });
  Widget _content() {
    if (_page == 6) return SymptomChecker(onAppointments: () => _select(3));
    if (widget.data.errors.isNotEmpty) return const PatientPanel(title: 'Live data unavailable', child: Text('Retry the failed sources above to view your current information.'));
    if (widget.data.loading.isNotEmpty) return const PatientPanel(title: 'Connecting to your account', child: Text('Your saved information will appear when loading finishes.'));
    return switch (_page) {
    1 => PatientInsights(stats: _stats, onRange: (d) => setState(() => _days = d)),
    2 => Column(children: [Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: _exporting ? null : _exportRecords, icon: const Icon(Icons.copy_outlined), label: const Text('Copy records CSV'))), const SizedBox(height: 12),
      PatientRecords(records: _stats.recentRecords, onAdd: widget.onAddRecord, onEdit: widget.onEditRecord, onDelete: widget.onDeleteRecord)]),
    4 => _reminders(),
    5 => _profile(),
    _ => _overview(),
    };
  }
  Widget _overview() {
    final data = widget.data;
    final stats = _stats;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(26), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6335D6), Color(0xFF8E62E9)]), borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('A clearer view of your health', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10), const Text('Track measured readings, organise reports and stay connected to your doctor.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 18), Wrap(spacing: 12, runSpacing: 10, children: [
            FilledButton.tonalIcon(onPressed: () => _select(3), icon: const Icon(Icons.calendar_month), label: const Text('Book appointment')),
            OutlinedButton(onPressed: widget.onAddRecord, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)), child: const Text('Add health record')),
          ]),
        ])),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (context, c) {
        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final minCardWidth = 145 * textScale.clamp(1.0, 1.5);
        final columns = c.maxWidth >= 900 && c.maxWidth >= minCardWidth * 4 + 42
            ? 4 : c.maxWidth >= minCardWidth * 2 + 14 ? 2 : 1;
        final width = (c.maxWidth - (columns - 1) * 14) / columns;
        return Wrap(spacing: 14, runSpacing: 14, children: [
          _statCard('Upcoming visits', '${stats.upcoming.length}', Icons.calendar_month, 'Appointments', () => _select(3)),
          _statCard('Saved records', '${data.records.length}', Icons.folder_outlined, 'Records', () => _select(2)),
          _statCard('Completed visits', '${data.appointments.where((a) => a['status'] == 'completed').length}', Icons.task_alt, 'Appointments', () => _select(1)),
          _statCard('Reading entries', '${data.records.where((r) => r['vitals'] is Map).length}', Icons.monitor_heart_outlined, 'Records', () => _select(1)),
        ].map((w) => SizedBox(width: width, child: w)).toList());
      }),
      const SizedBox(height: 20),
      PatientPanel(title: 'Latest health profile', subtitle: data.profile.isEmpty ? 'Add your first measured reading' : 'Last saved: ${patientDateLabel(data.profile['updatedAt'] ?? data.profile['lastCheckup'])}',
        child: _vitalGrid([
          ...patientMetrics.map((m) => _vitalTile(m.label, data.profile[m.key], m.unit)),
          _vitalTile('Blood pressure', data.profile['bloodPressure'], 'mmHg'), _vitalTile('BMI', data.profile['bmi'], 'kg/m²'),
        ])),
      const SizedBox(height: 20),
      PatientColumns(children: [
        PatientPanel(title: 'Next appointments', action: TextButton(onPressed: () => _select(3), child: const Text('View all')), child: stats.upcoming.isEmpty ? const PatientEmpty('No upcoming visits. Book an appointment to get started.', icon: Icons.calendar_month_outlined)
          : Column(children: stats.upcoming.take(3).map(_appointmentTile).toList())),
        PatientPanel(title: 'Recent records', action: TextButton(onPressed: () => _select(2), child: const Text('View all')), child: stats.recentRecords.isEmpty ? const PatientEmpty('Your saved reports and readings will appear here.', icon: Icons.folder_outlined)
          : Column(children: stats.recentRecords.take(3).map((r) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.description_outlined, color: patientPurple), title: Text('${r['title'] ?? 'Health record'}'), subtitle: Text('${r['recordType'] ?? 'Other'} • ${patientDateLabel(r['recordDate'])}'), onTap: () => _select(2))).toList())),
      ]),
      const SizedBox(height: 24), PatientInsights(stats: stats, onRange: (d) => setState(() => _days = d)),
    ]);
  }
  Widget _statCard(String title, String value, IconData icon, String source, VoidCallback onTap) {
    final unavailable = widget.data.errors.containsKey(source);
    final loading = widget.data.loading.contains(source);
    return Material(color: Colors.white, borderRadius: BorderRadius.circular(16), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: patientPurple), const SizedBox(height: 14), Text(unavailable || loading ? '—' : value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5), ConstrainedBox(constraints: BoxConstraints(minHeight: MediaQuery.textScalerOf(context).scale(12) * 2.5), child: Text(title, style: const TextStyle(fontSize: 12, color: patientMuted))),
    ]))));
  }
  Widget _vitalGrid(List<Widget> tiles) => LayoutBuilder(builder: (context, constraints) {
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final minWidth = 140 * textScale.clamp(1.0, 1.5);
    final columns = ((constraints.maxWidth + 12) / (minWidth + 12)).floor().clamp(1, 6);
    final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
    return Wrap(spacing: 12, runSpacing: 12, children: tiles.map((tile) => SizedBox(width: width, child: tile)).toList());
  });
  Widget _vitalTile(String label, dynamic value, String unit) {
    final n = patientNumber(value);
    final display = value == null || '$value'.isEmpty ? 'Not recorded' : n != null ? n.toStringAsFixed(1) : '$value';
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: patientBackground, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: patientMuted, fontSize: 12)), const SizedBox(height: 10), Text(display, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
      if (display != 'Not recorded') Text(unit, style: const TextStyle(color: patientMuted, fontSize: 11)),
    ]));
  }
  Widget _appointmentTile(Map<String, dynamic> a) => Container(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [Text('${a['doctorName'] ?? 'Doctor'}', style: const TextStyle(fontWeight: FontWeight.bold)), PatientStatus('${a['status'] ?? 'pending'}')]),
    const SizedBox(height: 6), Text('${patientDateLabel(a['appointmentDate'])} • ${a['appointmentTime'] ?? 'Time unavailable'}', style: const TextStyle(color: patientMuted, fontSize: 12)),
    if ((a['reason'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text('${a['reason']}')),
  ]));
  Widget _reminders() => PatientPanel(title: 'Appointment reminders', subtitle: 'Derived from your live appointments; updates when your doctor changes a visit.',
    action: TextButton(onPressed: () => _select(3), child: const Text('Manage visits')),
    child: _stats.upcoming.isEmpty ? const PatientEmpty('You have no upcoming appointment reminders.', icon: Icons.notifications_none_outlined)
      : Column(children: _stats.upcoming.map((a) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a['status'] == 'pending' ? 'Awaiting doctor confirmation' : 'Your visit is confirmed', style: const TextStyle(color: patientPurple, fontWeight: FontWeight.w700)),
        _appointmentTile(a), const Divider(),
      ])).toList()));
  Widget _profile() => PatientColumns(children: [
    PatientPanel(title: 'Personal information', action: TextButton(onPressed: widget.onProfile, child: const Text('Edit profile')), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const CircleAvatar(radius: 32, backgroundColor: Color(0xFFF0EBFD), child: Icon(Icons.person_outline, size: 34, color: patientPurple)), const SizedBox(height: 20),
      ...['name', 'email', 'phone', 'role', 'status'].map((key) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(key.toUpperCase(), style: const TextStyle(color: patientMuted, fontSize: 10)), const SizedBox(height: 5), Text('${widget.data.user[key] ?? 'Not recorded'}'),
      ]))),
      OutlinedButton.icon(onPressed: widget.onResetPassword, icon: const Icon(Icons.lock_reset), label: const Text('Send password reset email')),
    ])),
    PatientPanel(title: 'Health information', subtitle: 'Your latest saved measurements', action: TextButton(onPressed: widget.onReading, child: const Text('Add reading')), child: _vitalGrid([
      ...patientMetrics.map((m) => _vitalTile(m.label, widget.data.profile[m.key], m.unit)),
      _vitalTile('Blood pressure', widget.data.profile['bloodPressure'], 'mmHg'), _vitalTile('Height', widget.data.profile['height'], 'cm'), _vitalTile('BMI', widget.data.profile['bmi'], 'kg/m²'),
    ])),
  ]);
  Future<void> _exportRecords() async {
    setState(() => _exporting = true);
    try {
      await Clipboard.setData(ClipboardData(text: patientRecordsCsv(_stats.recentRecords)));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Records CSV copied. Paste it into a file or spreadsheet.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not copy records. Try again.')));
    } finally { if (mounted) setState(() => _exporting = false); }
  }
}

String patientRecordsCsv(List<Map<String, dynamic>> records) {
  String cell(dynamic value) {
    var text = '${value ?? ''}';
    if (RegExp(r'^\s*[=+@-]').hasMatch(text)) text = "'$text";
    return '"${text.replaceAll('"', '""')}"';
  }
  return ['title,type,date,doctor,clinic,description,vitals', ...records.map((r) => [r['title'], r['recordType'], patientDateLabel(r['recordDate']), r['doctorName'], r['hospitalName'], r['description'], r['vitals'] is Map ? (r['vitals'] as Map).entries.map((e) => '${e.key}: ${e.value}').join('; ') : ''].map(cell).join(','))].join('\n');
}

