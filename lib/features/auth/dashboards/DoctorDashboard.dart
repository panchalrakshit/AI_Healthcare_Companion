import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../login/login_screen.dart';
import 'doctor/doctor_data.dart';
import 'doctor/doctor_insights.dart';
import 'doctor/doctor_patient.dart';
import 'doctor/doctor_profile.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});
  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final _db = FirebaseFirestore.instance;
  late final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late final DoctorRepository? _repository = _uid == null ? null : DoctorRepository(_db, _uid);
  late final _appointments = _repository?.watchAppointments();
  late final _profile = _uid == null ? null : _db.collection('users').doc(_uid).snapshots();
  late final _assessments = _uid == null ? null : _db.collection('doctorAssessments').where('doctorUid', isEqualTo: _uid).snapshots();
  final _busy = <String>{};
  int _page = 0, _days = 30;
  String _search = '', _status = 'all';
  static const _labels = ['Overview', 'My patients', 'Appointments', 'Assessments', 'Alerts', 'Reports', 'Profile'];
  static const _icons = [Icons.space_dashboard_outlined, Icons.people_outline, Icons.calendar_month_outlined,
    Icons.assignment_outlined, Icons.notifications_none_outlined, Icons.description_outlined, Icons.person_outline];

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087B75))),
    child: Scaffold(backgroundColor: const Color(0xFFF3F8F7), body: _uid == null ? _messagePanel('Sign in to view your doctor workspace.') :
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: _profile, builder: (context, profile) {
        if (profile.hasError) return _messagePanel('Unable to verify your doctor profile. Check the connection and Firestore rules.');
        if (!profile.hasData) return const Center(child: CircularProgressIndicator());
        final data = profile.data!.data();
        if (data == null || data['role'] != 'doctor' || data['status'] != 'active') return _messagePanel('Doctor access is unavailable. Your account may have been suspended or removed.');
        return LayoutBuilder(builder: (context, c) => c.maxWidth < 900
          ? Scaffold(backgroundColor: const Color(0xFFF3F8F7), appBar: AppBar(title: Text(_labels[_page]), backgroundColor: Colors.white),
              drawer: Drawer(child: _sidebar(close: true)), body: _body(data))
          : Row(children: [SizedBox(width: 235, child: _sidebar()), Expanded(child: _body(data))]));
      })),
  );

  Widget _sidebar({bool close = false}) => Material(color: const Color(0xFF075E5A), child: SafeArea(child: Column(children: [
    const Padding(padding: EdgeInsets.fromLTRB(20, 28, 16, 24), child: Row(children: [Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 32), SizedBox(width: 12),
      Expanded(child: Text('HealthCompanion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)))])),
    const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.centerLeft, child: Text('DOCTOR WORKSPACE', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.2)))),
    Expanded(child: ListView(children: List.generate(_labels.length, (i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(selected: _page == i, selectedTileColor: Colors.white, selectedColor: const Color(0xFF075E5A), textColor: Colors.white70, iconColor: Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), leading: Icon(_icons[i]), title: Text(_labels[i], style: TextStyle(fontWeight: _page == i ? FontWeight.w700 : FontWeight.w500)), onTap: () {
          setState(() { _page = i; _search = ''; _status = 'all'; }); if (close) Navigator.pop(context);
        }))))),
    Padding(padding: const EdgeInsets.all(12), child: ListTile(leading: const Icon(Icons.logout, color: Colors.white70), title: const Text('Sign out', style: TextStyle(color: Colors.white70)), onTap: _logout)),
  ])));

  Widget _body(Map<String, dynamic> profile) {
    if (_page == 6) return DoctorProfile(db: _db, uid: _uid!, profile: profile);
    return StreamBuilder<List<DoctorDoc>>(stream: _appointments, builder: (context, appointments) {
      if (appointments.hasError) return _messagePanel('Unable to load assigned appointments. Publish the updated rules and check doctor directory links.');
      if (!appointments.hasData) return const Center(child: CircularProgressIndicator());
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _assessments, builder: (context, assessments) {
        if (assessments.hasError) return _messagePanel('Unable to load assessments. Publish the doctor security rules and try again.');
        if (!assessments.hasData) return const Center(child: CircularProgressIndicator());
        final visits = appointments.data!, notes = assessments.data!.docs;
        final stats = DoctorStats(visits.map((a) => a.data()).toList(), notes.map((a) => a.data()).toList(), now: DateTime.now(), days: _days);
        return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_labels[_page], style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: Color(0xFF153C39))),
            const SizedBox(height: 5), Text('Welcome, ${profile['name'] ?? 'Doctor'}', style: const TextStyle(color: Colors.grey))])), const Icon(Icons.verified_user_outlined, color: Color(0xFF087B75))]),
          const SizedBox(height: 22),
          if ([1, 2, 3, 5].contains(_page)) ...[TextField(key: ValueKey('doctor-search-$_page'), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search patient, reason or notes', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase())), const SizedBox(height: 16)],
          if (_page == 0) ..._overview(visits, stats),
          if (_page == 1) ..._patients(visits),
          if (_page == 2) ..._appointmentList(visits),
          if (_page == 3) ..._assessmentList(notes, visits),
          if (_page == 4) ..._alerts(visits, notes),
          if (_page == 5) ..._reports(notes, stats),
        ]));
      });
    });
  }

  List<Widget> _overview(List<DoctorDoc> visits, DoctorStats stats) {
    final pending = visits.where((a) => a.data()['status'] == 'pending').length;
    final upcoming = visits.where((a) { final date = doctorDate(a.data()['appointmentDate']);
      return date != null && !date.isBefore(DateTime(stats.now.year, stats.now.month, stats.now.day)) && ['pending', 'confirmed'].contains(a.data()['status']); }).toList();
    return [Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF075E5A), Color(0xFF18A495)]), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Care, appointments & insights', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8), Text('$pending appointment requests await your response.', style: const TextStyle(color: Colors.white70)), const SizedBox(height: 16),
        FilledButton.icon(onPressed: () => setState(() => _page = 2), icon: const Icon(Icons.calendar_today), label: const Text('Manage appointments'))])),
      const SizedBox(height: 18), Wrap(spacing: 14, runSpacing: 14, children: [_metric('My patients', stats.patientCount, Icons.people_outline), _metric('Today’s visits', stats.todayCount, Icons.calendar_today_outlined),
        _metric('Pending requests', pending, Icons.pending_actions), _metric('High priority', stats.highPriority, Icons.flag_outlined)]),
      const SizedBox(height: 28), DoctorInsights(stats: stats, onRange: (d) => setState(() => _days = d)), const SizedBox(height: 28),
      const Text('Upcoming appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 14),
      if (upcoming.isEmpty) _empty('No upcoming appointments.') else ...upcoming.take(6).map(_appointmentCard)];
  }
  Widget _metric(String title, int value, IconData icon) => Container(width: 205, padding: const EdgeInsets.all(20), decoration: _card(), child: Row(children: [
    CircleAvatar(backgroundColor: const Color(0xFFE2F4F0), child: Icon(icon, color: const Color(0xFF087B75))), const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$value', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)), Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey))]))]));
  bool _matches(Map<String, dynamic> data) => _search.isEmpty || ['patientName', 'patientEmail', 'reason', 'notes', 'symptoms', 'plan', 'priority'].any((key) => (data[key] ?? '').toString().toLowerCase().contains(_search));
  List<Widget> _appointmentList(List<DoctorDoc> visits) {
    final filtered = visits.where((a) => (_status == 'all' || a.data()['status'] == _status) && _matches(a.data())).toList();
    return [Wrap(spacing: 8, runSpacing: 6, children: ['all', 'pending', 'confirmed', 'completed', 'cancelled'].map((s) => ChoiceChip(label: Text(s.toUpperCase()), selected: _status == s, onSelected: (_) => setState(() => _status = s))).toList()),
      const SizedBox(height: 18), if (filtered.isEmpty) _empty('No matching appointments.') else ...filtered.map(_appointmentCard)];
  }
  Widget _appointmentCard(DoctorDoc doc) {
    final data = doc.data(), status = (doc.data()['status'] ?? 'pending').toString();
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18), decoration: _card(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const CircleAvatar(backgroundColor: Color(0xFFE2F4F0), child: Icon(Icons.person_outline, color: Color(0xFF087B75))), const SizedBox(width: 12),
        Expanded(child: Text((data['patientName'] ?? 'Patient').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), _badge(status)]),
      const SizedBox(height: 10), Text('${_date(doctorDate(data['appointmentDate']))} • ${data['appointmentTime'] ?? ''}', style: const TextStyle(color: Colors.grey)),
      if ((data['reason'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 7), child: Text('Reason: ${data['reason']}')),
      const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: [
        if (['confirmed', 'completed'].contains(status)) OutlinedButton.icon(onPressed: _busy.contains(doc.id) ? null : () => _openPatient(doc), icon: const Icon(Icons.folder_shared_outlined, size: 18), label: const Text('Patient records')),
        ...doctorNextStatuses(status).map((next) => FilledButton.tonal(onPressed: _busy.contains(doc.id) ? null : () => _statusAction(doc, next), child: Text(next == 'confirmed' ? 'Confirm visit' : next == 'completed' ? 'Complete visit' : 'Cancel visit'))),
        if (_busy.contains(doc.id)) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))])
    ]));
  }
  List<Widget> _patients(List<DoctorDoc> visits) {
    final groups = <String, List<DoctorDoc>>{};
    for (final visit in visits) { final id = visit.data()['patientId']; if (id is String && visit.data()['status'] != 'cancelled') groups.putIfAbsent(id, () => []).add(visit); }
    final matched = groups.values.where((g) => g.any((v) => _matches(v.data()))).toList();
    if (matched.isEmpty) return [_empty('No assigned patients yet. Patients appear after booking with you.')];
    return matched.map((group) { final latest = group.last.data(); final eligible = group.where((a) => ['confirmed', 'completed'].contains(a.data()['status'])).toList();
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18), decoration: _card(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((latest['patientName'] ?? 'Patient').toString(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text('${latest['patientEmail'] ?? ''} • ${group.length} appointments'), const SizedBox(height: 10),
        if (eligible.isNotEmpty) OutlinedButton.icon(onPressed: () => _openPatient(eligible.last), icon: const Icon(Icons.folder_shared_outlined), label: const Text('Open patient workspace'))
        else const Text('Confirm an appointment before opening clinical records.', style: TextStyle(color: Colors.grey, fontSize: 12))])); }).toList();
  }
  List<Widget> _assessmentList(List<DoctorDoc> notes, List<DoctorDoc> visits) {
    final eligible = visits.where((a) => ['confirmed', 'completed'].contains(a.data()['status'])).toList();
    final filtered = notes.where((n) => _matches(n.data())).toList()..sort((a, b) => (doctorDate(b.data()['updatedAt']) ?? DateTime(1970)).compareTo(doctorDate(a.data()['updatedAt']) ?? DateTime(1970)));
    return [const Text('Record symptoms, notes, a care plan and clinician-selected priority for each visit.', style: TextStyle(color: Colors.grey)), const SizedBox(height: 14),
      FilledButton.icon(onPressed: eligible.isEmpty ? null : () => _chooseAssessment(eligible), icon: const Icon(Icons.add), label: const Text('New assessment')), const SizedBox(height: 18),
      if (filtered.isEmpty) _empty('No saved assessments yet.') else ...filtered.map(_assessmentCard)];
  }
  Widget _assessmentCard(DoctorDoc note) {
    final x = note.data();
    return Container(margin: const EdgeInsets.only(bottom: 12), decoration: _card(), child: ListTile(contentPadding: const EdgeInsets.all(18),
      title: Text((x['patientName'] ?? 'Patient').toString(), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${x['notes'] ?? ''}\n${_date(doctorDate(x['updatedAt']))}'),
      isThreeLine: true, trailing: _badge((x['priority'] ?? 'low').toString()), onTap: () => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text((x['patientName'] ?? 'Assessment').toString()),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final key in ['symptoms', 'notes', 'plan', 'priority']) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('${key.toUpperCase()}\n${x[key] ?? 'Not recorded'}')),
          Text('Follow-up: ${_date(doctorDate(x['followUpAt']))}')
        ])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]))));
  }
  List<Widget> _alerts(List<DoctorDoc> visits, List<DoctorDoc> notes) {
    final requests = visits.where((a) => a.data()['status'] == 'pending').toList();
    final latest = DoctorStats(visits.map((a) => a.data()).toList(), notes.map((a) => a.data()).toList(), now: DateTime.now()).latestAssessments;
    final due = latest.values.where((n) { final date = doctorDate(n['followUpAt']); return date != null && !date.isAfter(DateTime.now()); }).toList();
    return [const Text('Pending requests and due follow-ups from your saved records.', style: TextStyle(color: Colors.grey)), const SizedBox(height: 18),
      if (requests.isEmpty && due.isEmpty) _empty('No pending requests or due follow-ups.'), ...requests.map(_appointmentCard),
      ...due.map((n) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: _card(), child: ListTile(leading: const Icon(Icons.event_repeat, color: Colors.orange), title: Text('Follow-up: ${n['patientName'] ?? 'Patient'}'),
        subtitle: Text('Due ${_date(doctorDate(n['followUpAt']))}'), trailing: TextButton(onPressed: () => setState(() => _page = 3), child: const Text('Assessments')))))];
  }
  List<Widget> _reports(List<DoctorDoc> notes, DoctorStats stats) => [DoctorInsights(stats: stats, onRange: (d) => setState(() => _days = d)), const SizedBox(height: 22),
    OutlinedButton.icon(onPressed: notes.isEmpty ? null : () async {
      String cell(dynamic value) => '"${(value ?? '').toString().replaceAll('"', '""')}"';
      final lines = ['Patient,Priority,Symptoms,Notes,Care plan,Follow-up', ...notes.where((n) => _matches(n.data())).map((n) { final x = n.data();
        return [x['patientName'], x['priority'], x['symptoms'], x['notes'], x['plan'], _date(doctorDate(x['followUpAt']))].map(cell).join(','); })];
      await Clipboard.setData(ClipboardData(text: lines.join('\n'))); _toast('Assessment report copied as CSV.');
    }, icon: const Icon(Icons.copy), label: const Text('Copy assessment report as CSV')), const SizedBox(height: 18), ...notes.where((n) => _matches(n.data())).map(_assessmentCard)];
  Future<void> _chooseAssessment(List<DoctorDoc> visits) async {
    final visit = await showDialog<DoctorDoc>(context: context, builder: (context) => SimpleDialog(title: const Text('Choose an appointment'), children: visits.map((a) => SimpleDialogOption(
      onPressed: () => Navigator.pop(context, a), child: Text('${a.data()['patientName'] ?? 'Patient'} • ${_date(doctorDate(a.data()['appointmentDate']))}'))).toList()));
    if (visit != null) await _openPatient(visit);
  }
  Future<void> _openPatient(DoctorDoc visit) async {
    setState(() => _busy.add(visit.id));
    try { await _repository!.openCare(visit); if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorPatient(db: _db, doctorUid: _uid!, appointment: visit)));
    } catch (e) { _toast('Cannot open patient records. Confirm the visit, check assignment and publish the updated rules.'); }
    finally { if (mounted) setState(() => _busy.remove(visit.id)); }
  }
  Future<void> _statusAction(DoctorDoc visit, String status) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text('Mark appointment $status?'), content: const Text('The patient and admin will see the updated status.'), actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update'))]));
    if (confirmed != true || !mounted) return;
    setState(() => _busy.add(visit.id));
    try { await _repository!.changeStatus(visit.id, status); _toast('Appointment updated.'); }
    catch (e) { _toast('Could not update appointment. It may have changed or access may be unavailable.'); }
    finally { if (mounted) setState(() => _busy.remove(visit.id)); }
  }
  Future<void> _logout() async { await FirebaseAuth.instance.signOut(); if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false); }
  void _toast(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  Widget _messagePanel(String message) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message, textAlign: TextAlign.center),
    const SizedBox(height: 14), TextButton(onPressed: _logout, child: const Text('Return to sign in'))])));
  Widget _empty(String text) => Padding(padding: const EdgeInsets.all(24), child: Text(text, style: const TextStyle(color: Colors.grey)));
  Widget _badge(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: ['high', 'cancelled'].contains(text) ? const Color(0xFFFFECEF) : const Color(0xFFEAF4F2), borderRadius: BorderRadius.circular(20)), child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)));
  BoxDecoration _card() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1ECE9)));
  String _date(DateTime? date) => date == null ? 'Not recorded' : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
