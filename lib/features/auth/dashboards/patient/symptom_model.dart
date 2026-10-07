import 'dart:convert';
import 'package:flutter/services.dart';

const symptomDiseases = ['Common Cold', 'Dengue', 'Influenza', 'Malaria', 'Typhoid'];
const symptomLabels = {
  'fever': 'Fever', 'cough': 'Cough', 'headache': 'Headache', 'fatigue': 'Fatigue',
  'vomiting': 'Vomiting', 'joint_pain': 'Joint pain', 'sore_throat': 'Sore throat',
  'runny_nose': 'Runny nose', 'chills': 'Chills', 'body_pain': 'Body pain',
};

class SymptomResult {
  final String treeSuggestion;
  final List<String> matchingLabels;
  final bool hasSymptoms;
  SymptomResult(this.treeSuggestion, this.matchingLabels, this.hasSymptoms);
  bool get supported => hasSymptoms && matchingLabels.length == 1 && matchingLabels.single == treeSuggestion;
}

class SymptomModel {
  final List<String> features, classes;
  final List<Map<String, dynamic>> nodes;
  final Map<String, List<String>> patterns;
  final String version;
  final double testAccuracy, macroF1;
  final int testRows;
  SymptomModel._(this.features, this.classes, this.nodes, this.patterns, this.version, this.testAccuracy, this.macroF1, this.testRows);

  static Future<SymptomModel> load() async => SymptomModel.fromJson(await rootBundle.loadString('assets/models/symptom_tree.json'));
  factory SymptomModel.fromJson(String text) {
    final value = jsonDecode(text) as Map<String, dynamic>;
    if (value['schemaVersion'] != 1 || value['educationalOnly'] != true) throw const FormatException('Unsupported model format.');
    final features = List<String>.from(value['features'] as List);
    final classes = List<String>.from(value['classes'] as List);
    final nodes = (value['nodes'] as List).map((n) => Map<String, dynamic>.from(n as Map)).toList();
    if (features.length != symptomLabels.length || features.toSet().length != features.length || features.any((f) => !symptomLabels.containsKey(f)) || classes.length != symptomDiseases.length || classes.toSet().length != classes.length || classes.any((c) => !symptomDiseases.contains(c)) || nodes.isEmpty) throw const FormatException('Invalid model inputs.');
    for (final node in nodes) {
      final feature = node['feature'] as int;
      final distribution = List<num>.from(node['distribution'] as List);
      if (distribution.length != classes.length || distribution.any((n) => !n.isFinite || n < 0) || distribution.fold<double>(0, (a, b) => a + b) <= 0) throw const FormatException('Invalid leaf values.');
      if (feature >= 0 && (feature >= features.length || !(node['threshold'] as num).isFinite || (node['left'] as int) < 0 || (node['right'] as int) < 0 || (node['left'] as int) >= nodes.length || (node['right'] as int) >= nodes.length)) throw const FormatException('Invalid tree nodes.');
    }
    final patterns = (value['trainingPatterns'] as Map).map((key, labels) => MapEntry(key as String, List<String>.from(labels as List)));
    if (patterns.entries.any((p) => p.key.length != features.length || !RegExp(r'^[01]+$').hasMatch(p.key) || p.value.isEmpty || p.value.any((l) => !classes.contains(l)))) throw const FormatException('Invalid pattern metadata.');
    final evaluation = value['evaluation'] as Map;
    final accuracy = (evaluation['testAccuracy'] as num).toDouble();
    final f1 = (evaluation['testMacroF1'] as num).toDouble();
    final rows = evaluation['testRows'] as int;
    if (!accuracy.isFinite || accuracy < 0 || accuracy > 1 || !f1.isFinite || f1 < 0 || f1 > 1 || rows < 1) throw const FormatException('Invalid evaluation metadata.');
    return SymptomModel._(features, classes, nodes, patterns, value['modelVersion'] as String, accuracy, f1, rows);
  }

  // Also exposed for exhaustive parity tests, including unsupported inputs.
  int predictClassIndex(Map<String, bool> answers) {
    if (answers.length != features.length || features.any((f) => !answers.containsKey(f))) throw ArgumentError('Answer every model symptom exactly once.');
    var index = 0;
    for (var steps = 0; steps <= nodes.length; steps++) {
      final node = nodes[index];
      final feature = node['feature'] as int;
      if (feature < 0) {
        final weights = List<num>.from(node['distribution'] as List);
        var best = 0;
        for (var i = 1; i < weights.length; i++) { if (weights[i] > weights[best]) best = i; }
        return best;
      }
      index = ((answers[features[feature]]! ? 1 : 0) <= (node['threshold'] as num)) ? node['left'] as int : node['right'] as int;
    }
    throw const FormatException('Tree contains a cycle.');
  }
  SymptomResult evaluate(Map<String, bool> answers) {
    final label = classes[predictClassIndex(answers)];
    final key = features.map((f) => answers[f]! ? '1' : '0').join();
    return SymptomResult(label, patterns[key] ?? [], answers.values.any((v) => v));
  }
}
