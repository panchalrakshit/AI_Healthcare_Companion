import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../dashboards/patient/patient_data.dart';
import '../dashboards/patient/patient_widgets.dart';

class AppointmentsScreen extends StatefulWidget {
  final bool embedded;
  const AppointmentsScreen({super.key, this.embedded = false});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}
class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _doctors;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _appointments;
  String _query = '', _status = 'All';
  final Set<String> _busy = {};
  @override
  void initState() {
    super.initState();
    _doctors = FirebaseFirestore.instance.collection('doctors').snapshots();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) _appointments = FirebaseFirestore.instance.collection('appointments').where('patientId', isEqualTo: uid).snapshots();
  }
  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  Future<void> _book(Map<String, dynamic> doctor) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final result = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => PatientBookingForm(doctor: doctor, onSave: (fields) async {
      if (FirebaseAuth.instance.currentUser?.uid != uid) throw StateError('Session changed.');
      final db = FirebaseFirestore.instance;
      final doctorRef = db.collection('doctors').doc(doctor['id'] as String);
      final user = FirebaseAuth.instance.currentUser!;
      final profile = await db.collection('users').doc(uid).get();
      final appointment = db.collection('appointments').doc();
      await db.runTransaction((transaction) async {
        final current = (await transaction.get(doctorRef)).data();
        if (current == null || (current['status'] ?? 'active') != 'active') throw StateError('This doctor is no longer available.');
        transaction.set(appointment, {
          ...fields, 'patientId': uid, 'patientName': profile.data()?['name'] ?? user.displayName ?? 'Patient',
          'patientEmail': user.email ?? '', 'doctorId': doctorRef.id,
          'doctorName': current['name'] ?? 'Doctor', 'specialization': current['specialization'] ?? '',
          'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
        });
      });
    }));
    if (result == true) _message('Appointment requested. Your doctor will confirm the visit.');
  }
  Future<void> _cancel(Map<String, dynamic> appointment) async {
    final id = appointment['id'] as String;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _busy.contains(id)) return;
    final result = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Cancel this appointment?'),
      content: Text('Your visit with ${appointment['doctorName'] ?? 'this doctor'} will be cancelled.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep visit')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel visit'))]));
    if (result != true || !mounted) return;
    setState(() => _busy.add(id));
    try {
      final db = FirebaseFirestore.instance;
      final ref = db.collection('appointments').doc(id);
      await db.runTransaction((transaction) async {
        final data = (await transaction.get(ref)).data();
        if (data == null || data['patientId'] != uid || !['pending', 'confirmed'].contains(data['status'])) throw StateError('This appointment has changed and can no longer be cancelled.');
        transaction.update(ref, {'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()});
      });
      _message('Appointment cancelled.');
    } catch (e) { _message(e is FirebaseException ? (e.message ?? e.code) : '$e'); }
    finally { if (mounted) setState(() => _busy.remove(id)); }
  }
  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Your appointments', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), const Text('Request a visit, follow its status and find your care team.', style: TextStyle(color: patientMuted)), const SizedBox(height: 22),
      Wrap(spacing: 8, runSpacing: 8, children: ['All', 'pending', 'confirmed', 'completed', 'cancelled'].map((s) => ChoiceChip(label: Text(s == 'All' ? s : s.toUpperCase()), selected: _status == s, onSelected: (_) => setState(() => _status = s))).toList()),
      const SizedBox(height: 18),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _appointments, builder: (context, snapshot) {
        if (_appointments == null) return const PatientEmpty('Sign in to view your appointments.');
        if (snapshot.hasError) return const PatientEmpty('Unable to load appointments. Check your connection and account permissions.');
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final all = snapshot.data!.docs.map((d) => {...d.data(), 'id': d.id}).toList();
        all.sort((a, b) => (patientDate(b['appointmentDate']) ?? DateTime(1900)).compareTo(patientDate(a['appointmentDate']) ?? DateTime(1900)));
        final filtered = all.where((a) => _status == 'All' || a['status'] == _status).toList();
        return PatientPanel(title: 'Visit history', subtitle: '${filtered.length} visits shown • ${all.length} total', child: filtered.isEmpty ? const PatientEmpty('No appointments match this filter.', icon: Icons.calendar_month_outlined)
          : Column(children: filtered.map((a) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: patientBackground, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [Text('${a['doctorName'] ?? 'Doctor'}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), PatientStatus('${a['status'] ?? 'unknown'}')]),
              const SizedBox(height: 10), Text('${patientDateLabel(a['appointmentDate'])} • ${a['appointmentTime'] ?? 'Time unavailable'}'),
              if ((a['specialization'] ?? '').toString().isNotEmpty) Text('${a['specialization']}', style: const TextStyle(color: patientPurple)),
              if ((a['reason'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('${a['reason']}')),
              if (['pending', 'confirmed'].contains(a['status'])) Padding(padding: const EdgeInsets.only(top: 14), child: OutlinedButton.icon(onPressed: _busy.contains(a['id']) ? null : () => _cancel(a),
                icon: const Icon(Icons.event_busy, size: 18), label: Text(_busy.contains(a['id']) ? 'Cancelling…' : 'Cancel appointment'))),
            ]))).toList()));
      }),
      const SizedBox(height: 28),
      TextField(onChanged: (v) => setState(() => _query = v.trim().toLowerCase()), decoration: InputDecoration(hintText: 'Find a doctor or specialization', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 18),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _doctors, builder: (context, snapshot) {
        if (snapshot.hasError) return const PatientEmpty('Unable to load the doctor directory. Check your connection and account permissions.');
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final doctors = snapshot.data!.docs.map((d) => {...d.data(), 'id': d.id}).where((d) => (d['status'] ?? 'active') == 'active' && '${d['name'] ?? ''} ${d['specialization'] ?? ''}'.toLowerCase().contains(_query)).toList();
        doctors.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
        return PatientPanel(title: 'Find your doctor', subtitle: '${doctors.length} active doctors match your search', child: doctors.isEmpty ? const PatientEmpty('No doctors match. Try another search or contact your administrator.', icon: Icons.person_search_outlined)
          : LayoutBuilder(builder: (context, c) {
            final width = c.maxWidth >= 760 ? (c.maxWidth - 14) / 2 : c.maxWidth;
            return Wrap(spacing: 14, runSpacing: 14, children: doctors.map((d) => SizedBox(width: width, child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: patientBackground, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const CircleAvatar(backgroundColor: Color(0xFFE9E0FD), child: Icon(Icons.medical_services_outlined, color: patientPurple)), const SizedBox(height: 14),
                Text('${d['name'] ?? 'Doctor'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 6),
                Text('${d['specialization'] ?? 'Specialization not listed'}', style: const TextStyle(color: patientPurple)),
                if ((d['qualification'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${d['qualification']}')),
                if ((d['hospital'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${d['hospital']}')),
                if ((d['availability'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Hours: ${d['availability']}', style: const TextStyle(color: patientMuted, fontSize: 12))),
                const SizedBox(height: 16), FilledButton.icon(onPressed: () => _book(d), icon: const Icon(Icons.calendar_month, size: 18), label: const Text('Request appointment')),
              ])))).toList());
          }));
      }),
    ]));
    if (widget.embedded) return content;
    return Scaffold(backgroundColor: patientBackground, appBar: AppBar(title: const Text('Appointments'), backgroundColor: Colors.white), body: content);
  }
}

class PatientBookingForm extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const PatientBookingForm({super.key, required this.doctor, required this.onSave});
  @override
  State<PatientBookingForm> createState() => _PatientBookingFormState();
}
class _PatientBookingFormState extends State<PatientBookingForm> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  bool _saving = false;
  String? _error;
  @override
  void dispose() { _reason.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final scheduled = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    if (!scheduled.isAfter(DateTime.now())) { setState(() => _error = 'Choose a future appointment time.'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onSave({'reason': _reason.text.trim(), 'appointmentDate': Timestamp.fromDate(scheduled), 'appointmentTime': _time.format(context)});
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) setState(() { _saving = false; _error = e is FirebaseException ? (e.message ?? e.code) : '$e'; }); }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_saving, child: AlertDialog(title: const Text('Request an appointment'), content: SizedBox(width: 460, child: SingleChildScrollView(child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('${widget.doctor['name'] ?? 'Doctor'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 12),
    const Text('Choose your preferred date and time. This is a request; the doctor must confirm availability.', style: TextStyle(color: patientMuted, fontSize: 12)), const SizedBox(height: 20),
    Wrap(spacing: 10, runSpacing: 10, children: [
      OutlinedButton.icon(onPressed: _saving ? null : () async {
        final date = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
        if (date != null && mounted) setState(() => _date = date);
      }, icon: const Icon(Icons.calendar_today, size: 18), label: Text(patientDateLabel(_date))),
      OutlinedButton.icon(onPressed: _saving ? null : () async {
        final time = await showTimePicker(context: context, initialTime: _time);
        if (time != null && mounted) setState(() => _time = time);
      }, icon: const Icon(Icons.schedule, size: 18), label: Text(_time.format(context))),
    ]), const SizedBox(height: 20),
    TextFormField(controller: _reason, maxLength: 2000, maxLines: 3, decoration: const InputDecoration(labelText: 'Reason for visit', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your reason for the visit.' : null),
    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
  ])))), actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
    FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Requesting…' : 'Request visit'))]));
}
