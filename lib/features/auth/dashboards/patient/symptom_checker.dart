import 'package:flutter/material.dart';
import 'patient_widgets.dart';
import 'symptom_model.dart';

class SymptomChecker extends StatefulWidget {
  final Future<SymptomModel>? model;
  final VoidCallback onAppointments;
  const SymptomChecker({super.key, this.model, required this.onAppointments});
  @override
  State<SymptomChecker> createState() => _SymptomCheckerState();
}
class _SymptomCheckerState extends State<SymptomChecker> {
  late Future<SymptomModel> _model;
  final Map<String, bool?> _answers = {};
  SymptomResult? _result;
  String? _error;
  @override
  void initState() { super.initState(); _model = widget.model ?? SymptomModel.load(); }
  void _run(SymptomModel model) {
    if (model.features.any((f) => _answers[f] == null)) { setState(() => _error = 'Answer Yes or No for every symptom.'); return; }
    try {
      final result = model.evaluate({for (final f in model.features) f: _answers[f]!});
      setState(() { _result = result; _error = null; });
    } catch (_) { setState(() { _result = null; _error = 'Unable to evaluate these inputs.'; }); }
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<SymptomModel>(future: _model, builder: (context, snapshot) {
    if (snapshot.hasError) return PatientPanel(title: 'Model unavailable', child: Column(children: [
      const Text('The bundled model could not be loaded. Rebuild with the model asset included.'),
      TextButton.icon(onPressed: () => setState(() => _model = widget.model ?? SymptomModel.load()), icon: const Icon(Icons.refresh), label: const Text('Retry')),
    ]));
    if (!snapshot.hasData) return const LinearProgressIndicator();
    final model = snapshot.data!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PatientPanel(title: 'Symptom checker • college demo', subtitle: 'Runs locally on your device. Inputs are not sent to a prediction server or saved.', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('This experimental model covers only Common Cold, Influenza, Malaria, Dengue and Typhoid. It cannot diagnose or rule out these or other conditions.', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12), Text('Grouped held-out test: ${(model.testAccuracy * 100).toStringAsFixed(1)}% accuracy across ${model.testRows} rows; macro F1 ${model.macroF1.toStringAsFixed(2)}. This score evaluates the bare tree, before the app withholds unsupported inputs. Small, unverified-source dataset; not clinically validated.', style: const TextStyle(color: patientMuted, fontSize: 12)),
        const SizedBox(height: 16), const Text('Answer Yes or No for each symptom. Leave an answer blank if unsure; the checker needs complete inputs.'),
        const SizedBox(height: 18),
        ...model.features.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
          Expanded(child: Text(symptomLabels[f]!)), const SizedBox(width: 8),
          SegmentedButton<bool>(key: ValueKey('symptom-$f'), emptySelectionAllowed: true, showSelectedIcon: false,
            segments: const [ButtonSegment(value: false, label: Text('No')), ButtonSegment(value: true, label: Text('Yes'))],
            selected: _answers[f] == null ? {} : {_answers[f]!}, onSelectionChanged: (values) => setState(() { _answers[f] = values.isEmpty ? null : values.single; _result = null; _error = null; })),
        ]))),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        Wrap(spacing: 12, runSpacing: 8, children: [
          FilledButton.icon(onPressed: () => _run(model), icon: const Icon(Icons.analytics_outlined), label: const Text('Run demo model')),
          TextButton(onPressed: () => setState(() { _answers.clear(); _result = null; _error = null; }), child: const Text('Clear answers')),
        ]),
      ])),
      if (_result != null) ...[const SizedBox(height: 18), PatientPanel(title: _result!.supported ? 'Experimental model suggestion' : 'No reliable suggestion', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!_result!.hasSymptoms) const Text('No symptoms were reported. This model has no healthy class, so it cannot assess this input.')
        else if (_result!.matchingLabels.isEmpty) const Text('This combination was not present in the model training set. The app withholds the tree prediction instead of presenting an unsupported disease suggestion.')
        else if (_result!.matchingLabels.length > 1) Text('The same symptom combination has conflicting labels in the training data: ${_result!.matchingLabels.join(', ')}. These inputs cannot distinguish those conditions.')
        else if (!_result!.supported) const Text('The tree output disagrees with the recorded label for this training pattern. The app withholds a disease suggestion.')
        else ...[
          Text(_result!.treeSuggestion, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: patientPurple)),
          const SizedBox(height: 10), const Text('This is a model output, not a diagnosis or a calibrated medical probability. Other conditions may cause the same symptoms.'),
        ],
        const SizedBox(height: 14), const Text('Discuss persistent or concerning symptoms with a clinician. Do not choose treatment based on this demo.'),
        const SizedBox(height: 16), OutlinedButton.icon(onPressed: widget.onAppointments, icon: const Icon(Icons.calendar_month), label: const Text('Find a doctor')),
      ]))],
    ]);
  });
}
