import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'patient_data.dart';
import 'patient_widgets.dart';

typedef PatientSave = Future<void> Function(Map<String, dynamic> fields);

class PatientEditor extends StatefulWidget {
  final String kind;
  final Map<String, dynamic> initial;
  final PatientSave onSave;
  const PatientEditor({super.key, required this.kind, this.initial = const {}, required this.onSave});
  @override
  State<PatientEditor> createState() => _PatientEditorState();
}
class _PatientEditorState extends State<PatientEditor> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  bool _saving = false;
  String? _error;
  late DateTime _date;
  String _type = 'Medical Report';
  bool get _vital => widget.kind == 'Reading';
  bool get _profile => widget.kind == 'Profile';
  @override
  void initState() {
    super.initState();
    final keys = _vital ? ['heartRate', 'bloodSugar', 'spo2', 'temperature', 'weight', 'height', 'bloodPressure']
      : _profile ? ['name', 'phone'] : ['title', 'doctorName', 'hospitalName', 'description'];
    for (final key in keys) { _fields[key] = TextEditingController(text: _vital ? '' : widget.initial[key]?.toString() ?? ''); }
    _date = patientDate(widget.initial['recordDate']) ?? DateTime.now();
    if (!_profile && !_vital) _type = widget.initial['recordType']?.toString() ?? 'Medical Report';
  }
  @override
  void dispose() { for (final c in _fields.values) { c.dispose(); } super.dispose(); }
  Widget _field(String key, String label, {bool required = false, bool numeric = false, int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 16), child: TextFormField(controller: _fields[key], maxLines: lines,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      maxLength: lines > 1 ? 4000 : 200,
      validator: (text) {
        final value = text?.trim() ?? '';
        if (required && value.isEmpty) return 'Enter $label.';
        if (numeric && value.isNotEmpty) {
          final n = patientNumber(value);
          if (n == null || n <= 0 || n > 10000) return 'Enter a positive number up to 10000.';
          if (key == 'spo2' && n > 100) return 'Oxygen saturation cannot exceed 100%.';
        }
        if (key == 'bloodPressure' && value.isNotEmpty) {
          final parts = value.split('/');
          if (parts.length != 2 || parts.any((v) => patientNumber(v) == null || patientNumber(v)! <= 0 || patientNumber(v)! > 500)) return 'Use systolic/diastolic, for example 120/80.';
        }
        return null;
      },
    ));
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final fields = <String, dynamic>{};
    for (final e in _fields.entries) {
      final value = e.value.text.trim();
      if (_vital) {
        if (value.isNotEmpty) fields[e.key] = e.key == 'bloodPressure' ? value : patientNumber(value);
      } else { fields[e.key] = value; }
    }
    if (_vital && fields.isEmpty) { setState(() => _error = 'Enter at least one measured reading.'); return; }
    if (!_vital && !_profile) {
      fields['recordType'] = _type;
      fields['recordDate'] = Timestamp.fromDate(_date);
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onSave(fields);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _error = e is FirebaseException ? (e.message ?? e.code) : 'Could not save. Try again.'; _saving = false; });
    }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_saving, child: AlertDialog(
    title: Text(_vital ? 'Add a measured reading' : _profile ? 'Edit your profile' : widget.initial.isEmpty ? 'Add health record' : 'Edit health record'),
    content: SizedBox(width: 480, child: SingleChildScrollView(child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (_vital) ...[
        const Text('Enter measurements from your device or report. Saving adds a dated history entry and updates your latest health profile.', style: TextStyle(color: patientMuted, fontSize: 12)),
        const SizedBox(height: 18),
        ...patientMetrics.map((m) => _field(m.key, '${m.label} (${m.unit})', numeric: true)),
        _field('height', 'Height (cm)', numeric: true),
        _field('bloodPressure', 'Blood pressure (mmHg)'),
      ] else if (_profile) ...[
        _field('name', 'Name', required: true), _field('phone', 'Phone'),
        const Text('Your login email and account permissions are managed separately.', style: TextStyle(color: patientMuted, fontSize: 12)),
      ] else ...[
        _field('title', 'Title', required: true),
        DropdownButtonFormField<String>(initialValue: _type, isExpanded: true, decoration: const InputDecoration(labelText: 'Record type'),
          items: {...['Medical Report', 'Prescription', 'Lab Result', 'Consultation', 'Other'], _type}.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: _saving ? null : (v) => setState(() => _type = v!)),
        const SizedBox(height: 18), _field('doctorName', 'Doctor name'), _field('hospitalName', 'Hospital / clinic'), _field('description', 'Description', lines: 4),
        OutlinedButton.icon(onPressed: _saving ? null : () async {
          final date = await showDatePicker(context: context, initialDate: _date.isAfter(DateTime.now()) ? DateTime.now() : _date,
            firstDate: DateTime(1900), lastDate: DateTime.now());
          if (date != null && mounted) setState(() => _date = date);
        }, icon: const Icon(Icons.calendar_today_outlined), label: Text(patientDateLabel(_date))),
      ],
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: const TextStyle(color: Colors.red))),
    ])))),
    actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : _vital ? 'Save reading' : 'Save changes'))],
  ));
}
