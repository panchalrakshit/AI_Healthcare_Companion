import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/patient/symptom_model.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/patient/symptom_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SymptomModel model;
  setUp(() { model = SymptomModel.fromJson(File('assets/models/symptom_tree.json').readAsStringSync()); });
  test('Dart matches sklearn on all 1024 symptom vectors', () {
    final fixture = jsonDecode(File('test/fixtures/symptom_predictions.json').readAsStringSync()) as Map;
    expect(model.features, fixture['features']); expect(model.classes, fixture['classes']);
    final expected = fixture['predictions'] as List;
    for (var i = 0; i < 1024; i++) {
      final bits = i.toRadixString(2).padLeft(10, '0');
      final answers = {for (var j = 0; j < model.features.length; j++) model.features[j]: bits[j] == '1'};
      expect(model.predictClassIndex(answers), expected[i], reason: 'vector $bits');
    }
  });
  test('missing inputs, no symptoms, unseen and conflicting patterns never give a supported result', () {
    expect(() => model.evaluate({'fever': true}), throwsArgumentError);
    expect(model.evaluate({for (final f in model.features) f: false}).supported, isFalse);
    final conflict = model.patterns.entries.firstWhere((p) => p.value.length > 1);
    final conflictResult = model.evaluate({for (var i = 0; i < model.features.length; i++) model.features[i]: conflict.key[i] == '1'});
    expect(conflictResult.supported, isFalse); expect(conflictResult.matchingLabels.length, greaterThan(1));
    final unseen = List.generate(1024, (i) => i.toRadixString(2).padLeft(10, '0')).firstWhere((p) => !model.patterns.containsKey(p) && p.contains('1'));
    expect(model.evaluate({for (var i = 0; i < model.features.length; i++) model.features[i]: unseen[i] == '1'}).supported, isFalse);
  });
  test('malformed trees are rejected', () {
    final raw = jsonDecode(File('assets/models/symptom_tree.json').readAsStringSync()) as Map;
    raw['nodes'][0]['left'] = 999999;
    expect(() => SymptomModel.fromJson(jsonEncode(raw)), throwsFormatException);
  });
  testWidgets('symptom form fits mobile, requires answers and clears results when edited', (tester) async {
    tester.view.physicalSize = const Size(320, 2200); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16),
      child: SymptomChecker(model: Future.value(model), onAppointments: () {}))))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Run demo model')); await tester.tap(find.text('Run demo model')); await tester.pumpAndSettle();
    expect(find.text('Answer Yes or No for every symptom.'), findsOneWidget);
    for (final f in model.features) {
      final no = find.descendant(of: find.byKey(ValueKey('symptom-$f')), matching: find.text('No'));
      await tester.ensureVisible(no); await tester.tap(no); await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Run demo model')); await tester.tap(find.text('Run demo model')); await tester.pumpAndSettle();
    expect(find.text('No reliable suggestion'), findsOneWidget);
    expect(find.textContaining('no healthy class'), findsOneWidget);
    final yes = find.descendant(of: find.byKey(const ValueKey('symptom-fever')), matching: find.text('Yes'));
    await tester.ensureVisible(yes); await tester.tap(yes); await tester.pumpAndSettle();
    expect(find.text('No reliable suggestion'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('supported training pattern displays an educational suggestion and doctor action', (tester) async {
    var opened = false;
    final pattern = model.patterns.keys.firstWhere((key) => model.evaluate({for (var i = 0; i < model.features.length; i++) model.features[i]: key[i] == '1'}).supported);
    final result = model.evaluate({for (var i = 0; i < model.features.length; i++) model.features[i]: pattern[i] == '1'});
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SymptomChecker(model: Future.value(model), onAppointments: () => opened = true)))));
    await tester.pumpAndSettle();
    for (var i = 0; i < model.features.length; i++) {
      final answer = find.descendant(of: find.byKey(ValueKey('symptom-${model.features[i]}')), matching: find.text(pattern[i] == '1' ? 'Yes' : 'No'));
      await tester.ensureVisible(answer); await tester.tap(answer); await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Run demo model')); await tester.tap(find.text('Run demo model')); await tester.pumpAndSettle();
    expect(find.text('Experimental model suggestion'), findsOneWidget);
    expect(find.text(result.treeSuggestion), findsOneWidget);
    await tester.ensureVisible(find.text('Find a doctor')); await tester.tap(find.text('Find a doctor')); expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('model loading errors have a retry action', (tester) async {
    final pending = Completer<SymptomModel>();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SymptomChecker(model: pending.future, onAppointments: () {}))));
    pending.completeError(const FormatException('invalid'));
    await tester.pumpAndSettle();
    expect(find.text('Model unavailable'), findsOneWidget); expect(find.text('Retry'), findsOneWidget);
  });
}
