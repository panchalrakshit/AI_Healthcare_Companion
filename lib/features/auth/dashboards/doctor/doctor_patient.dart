import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'doctor_data.dart';

class DoctorPatient extends StatefulWidget {
  final FirebaseFirestore db;
  final String doctorUid;
  final DoctorDoc appointment;
  const DoctorPatient({super.key, required this.db, required this.doctorUid, required this.appointment});
  @override
  State<DoctorPatient> createState() => _DoctorPatientState();
}

class _DoctorPatientState extends State<DoctorPatient> {
  late final String _patientId = widget.appointment.data()['patientId'] as String;
  late final _visit = widget.appointment.reference.snapshots();
  late final _patient = widget.db.collection('users').doc(_patientId).snapshots();
  late final _health = widget.db.collection('healthProfiles').doc(_patientId).snapshots();
  late final _records = widget.db.collection('healthRecords').where('patientId', isEqualTo: _patientId).snapshots();
  late final _assessment = widget.db.collection('doctorAssessments').doc('${widget.doctorUid}_${widget.appointment.id}');

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFF3F8F7), appBar: AppBar(
    title: Text((widget.appointment.data()['patientName'] ?? 'Patient workspace').toString()), backgroundColor: Colors.white),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: _visit, builder: (context, visit) {
      if (visit.hasError) return _state('Patient access is unavailable.');
      if (!visit.hasData) return const Center(child: CircularProgressIndicator());
      if (!visit.data!.exists || !['confirmed', 'completed'].contains(visit.data!.data()?['status'])) {
        return _state('Clinical access ended because the appointment was cancelled or removed.');
      }
      return SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: _patient, builder: (context, s) {
          if (s.hasError) return _state('Patient profile is unavailable or access has ended.');
          if (!s.hasData) return const LinearProgressIndicator();
          final data = s.data!.data();
          if (data == null) return _state('Patient account was removed.');
          return _panel('Patient details', [Text((data['name'] ?? 'Patient').toString(), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            Text('Email: ${data['email'] ?? 'Not recorded'}'), Text('Phone: ${data['phone'] ?? 'Not recorded'}')]);
        }), const SizedBox(height: 18),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: _health, builder: (context, s) {
          if (s.hasError) return _state('Health profile is unavailable or access has ended.');
          if (!s.hasData) return const LinearProgressIndicator();
          final data = s.data!.data() ?? <String, dynamic>{};
          const fields = {'bloodPressure': 'Blood pressure', 'bloodSugar': 'Blood sugar', 'heartRate': 'Heart rate', 'spo2': 'SpO₂',
            'temperature': 'Temperature', 'weight': 'Weight', 'height': 'Height', 'bmi': 'BMI', 'bloodGroup': 'Blood group', 'gender': 'Gender',
            'dateOfBirth': 'Date of birth', 'allergies': 'Allergies', 'existingConditions': 'Existing conditions', 'currentMedications': 'Current medications'};
          return _panel('Patient-reported health profile', [Wrap(spacing: 14, runSpacing: 14, children: fields.entries.map((e) => SizedBox(width: 190, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.value, style: const TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 4), Text(_display(data[e.key]), style: const TextStyle(fontWeight: FontWeight.w600)),
          ]))).toList())]);
        }), const SizedBox(height: 18),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _records, builder: (context, s) {
          if (s.hasError) return _state('Medical records are unavailable or access has ended.');
          if (!s.hasData) return const LinearProgressIndicator();
          final records = [...s.data!.docs]..sort((a, b) => (doctorDate(b.data()['recordDate']) ?? DateTime(1970)).compareTo(doctorDate(a.data()['recordDate']) ?? DateTime(1970)));
          return _panel('Medical record history', [if (records.isEmpty) const Text('No medical records shared yet.'),
            ...records.map((d) { final x = d.data(); return ExpansionTile(tilePadding: EdgeInsets.zero, title: Text((x['title'] ?? 'Medical record').toString()),
              subtitle: Text('${x['recordType'] ?? 'Record'} • ${_display(x['recordDate'])}'), children: [
                Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 16), child: Text('${x['description'] ?? ''}\nDoctor: ${x['doctorName'] ?? 'Not recorded'}\nHospital: ${x['hospitalName'] ?? 'Not recorded'}')))
              ]); }),
          ]);
        }), const SizedBox(height: 18),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: _assessment.snapshots(), builder: (context, s) {
          if (s.hasError) return _state('Assessment access is unavailable.');
          if (!s.hasData) return const LinearProgressIndicator();
          final data = s.data!.data();
          return _panel('Visit assessment', [
            if (data == null) const Text('No assessment saved for this visit.') else ...[
              Text('Priority: ${data['priority'] ?? 'Not recorded'}'), const SizedBox(height: 8),
              Text('Symptoms: ${data['symptoms'] ?? ''}'), Text('Notes: ${data['notes'] ?? ''}'), Text('Care plan: ${data['plan'] ?? ''}'),
              Text('Follow-up: ${_display(data['followUpAt'])}'),
            ], const SizedBox(height: 14), FilledButton.icon(onPressed: () => _edit(data), icon: const Icon(Icons.edit_note), label: Text(data == null ? 'Record assessment' : 'Edit assessment')),
          ]);
        }),
      ]));
    }),
  );
  Future<void> _edit(Map<String, dynamic>? initial) => showDialog<void>(context: context, barrierDismissible: false, builder: (_) => DoctorAssessmentForm(
    initial: initial, onSave: (fields) async {
      await _assessment.set({
        ...fields, 'doctorUid': widget.doctorUid, 'patientId': _patientId, 'appointmentId': widget.appointment.id,
        'patientName': widget.appointment.data()['patientName'] ?? 'Patient',
        'createdAt': initial?['createdAt'] ?? FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      });
    },
  ));
  Widget _panel(String title, List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1ECE9))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 16), ...children]));
  Widget _state(String text) => Padding(padding: const EdgeInsets.all(22), child: Text(text, style: const TextStyle(color: Colors.grey)));
  String _display(dynamic value) { if (value == null || value.toString().trim().isEmpty) return 'Not recorded'; final date = doctorDate(value); return date == null ? value.toString() : '${date.day}/${date.month}/${date.year}'; }
}

class DoctorAssessmentForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const DoctorAssessmentForm({super.key, this.initial, required this.onSave});
  @override
  State<DoctorAssessmentForm> createState() => _DoctorAssessmentFormState();
}
class _DoctorAssessmentFormState extends State<DoctorAssessmentForm> {
  final _form = GlobalKey<FormState>();
  late final _symptoms = TextEditingController(text: widget.initial?['symptoms']?.toString() ?? '');
  late final _notes = TextEditingController(text: widget.initial?['notes']?.toString() ?? '');
  late final _plan = TextEditingController(text: widget.initial?['plan']?.toString() ?? '');
  late String _priority = widget.initial?['priority']?.toString() ?? 'low';
  late DateTime? _followUp = doctorDate(widget.initial?['followUpAt']);
  bool _saving = false;
  String? _error;
  @override
  void dispose() { _symptoms.dispose(); _notes.dispose(); _plan.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_saving, child: AlertDialog(title: const Text('Visit assessment'),
    content: SizedBox(width: 500, child: SingleChildScrollView(child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [
      _field(_symptoms, 'Symptoms'), _field(_notes, 'Clinical notes', required: true), _field(_plan, 'Care plan'),
      DropdownButtonFormField<String>(initialValue: _priority, decoration: const InputDecoration(labelText: 'Clinician-selected priority', border: OutlineInputBorder()),
        items: ['low', 'medium', 'high'].map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(), onChanged: _saving ? null : (v) => setState(() => _priority = v!)),
      const SizedBox(height: 14), Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: _saving ? null : () async {
        final now = DateTime.now();
        final date = await showDatePicker(context: context, initialDate: _followUp != null && !_followUp!.isBefore(DateTime(now.year, now.month, now.day)) ? _followUp! : now,
          firstDate: DateTime(now.year, now.month, now.day), lastDate: DateTime(now.year + 5));
        if (date != null && mounted) setState(() => _followUp = date);
      }, icon: const Icon(Icons.event_repeat), label: Text(_followUp == null ? 'Set follow-up' : '${_followUp!.day}/${_followUp!.month}/${_followUp!.year}')),
        if (_followUp != null) TextButton(onPressed: _saving ? null : () => setState(() => _followUp = null), child: const Text('Clear'))]),
      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
    ])))), actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save assessment'))]));
  Widget _field(TextEditingController controller, String label, {bool required = false}) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(
    controller: controller, enabled: !_saving, minLines: 2, maxLines: 5, maxLength: 4000, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), counterText: ''),
    validator: (v) => required && (v ?? '').trim().isEmpty ? 'Enter clinical notes.' : null));
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try { await widget.onSave({'symptoms': _symptoms.text.trim(), 'notes': _notes.text.trim(), 'plan': _plan.text.trim(), 'priority': _priority,
      'followUpAt': _followUp == null ? null : Timestamp.fromDate(_followUp!)}); if (mounted) Navigator.pop(context); }
    catch (e) { if (mounted) setState(() { _saving = false; _error = 'Could not save. Check appointment access and your connection, then retry.'; }); }
  }
}
