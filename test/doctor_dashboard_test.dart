import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/doctor/doctor_data.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/doctor/doctor_insights.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/doctor/doctor_patient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('doctor statistics use dated records, unique patients and latest assessment priorities', () {
    final now = DateTime(2026, 10, 6, 12);
    final stats = DoctorStats([
      {'patientId': 'one', 'status': 'completed', 'appointmentDate': Timestamp.fromDate(now)},
      {'patientId': 'one', 'status': 'pending', 'appointmentDate': Timestamp.fromDate(now)},
      {'patientId': 'two', 'status': 'cancelled', 'appointmentDate': Timestamp.fromDate(now)},
      {'patientId': 'three', 'status': 'pending'},
      {'patientId': 'four', 'status': 'confirmed', 'appointmentDate': Timestamp.fromDate(now.add(const Duration(days: 1)))},
    ], [
      {'patientId': 'one', 'priority': 'high', 'updatedAt': Timestamp.fromDate(now.subtract(const Duration(days: 1)))},
      {'patientId': 'one', 'priority': 'low', 'updatedAt': Timestamp.fromDate(now)},
      {'patientId': 'two', 'priority': 'high', 'updatedAt': Timestamp.fromDate(now)},
    ], now: now, days: 7);
    expect(stats.period.length, 3);
    expect(stats.patientCount, 3);
    expect(stats.todayCount, 2);
    expect(stats.highPriority, 1);
    expect(stats.outcomes['completed'], 1);
    expect(stats.trend.reduce((a, b) => a + b), 3);
    expect(stats.weekdays[1], 3);
  });
  test('appointment transitions cannot reopen cancelled/completed visits', () {
    expect(doctorNextStatuses('pending'), ['confirmed', 'cancelled']);
    expect(doctorNextStatuses('confirmed'), ['completed', 'cancelled']);
    expect(doctorNextStatuses('cancelled'), isEmpty);
    expect(doctorNextStatuses('completed'), isEmpty);
  });
  testWidgets('insights fit a narrow screen with real data and range controls', (tester) async {
    tester.view.physicalSize = const Size(320, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = 30;
    final now = DateTime.now();
    final stats = DoctorStats([{'patientId': 'one', 'appointmentDate': Timestamp.fromDate(now), 'status': 'completed'}], [], now: now);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(22),
      child: DoctorInsights(stats: stats, onRange: (d) => selected = d))))));
    await tester.pumpAndSettle();
    expect(find.text('100% completed'), findsOneWidget);
    expect(find.text('Scheduled dates • 1 appointments'), findsOneWidget);
    await tester.tap(find.text('7 days'));
    expect(selected, 7);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty insights show no fabricated data', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: DoctorInsights(
      stats: DoctorStats([], [], now: DateTime.now()), onRange: (_) {})))));
    expect(find.text('No appointments in this period.'), findsOneWidget);
    expect(find.text('No outcomes to display.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('assessment requires notes and submits clinician priority without a predicted score', (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () => showDialog<void>(context: context, builder: (_) => DoctorAssessmentForm(onSave: (fields) async { saved = fields; })), child: const Text('Open'))))));
    await tester.tap(find.text('Open')); await tester.pumpAndSettle();
    await tester.tap(find.text('Save assessment')); await tester.pumpAndSettle();
    expect(find.text('Enter clinical notes.'), findsOneWidget); expect(saved, isNull);
    await tester.enterText(find.widgetWithText(TextFormField, 'Clinical notes'), 'Patient reports improvement.');
    await tester.tap(find.text('Save assessment')); await tester.pumpAndSettle();
    expect(saved?['notes'], 'Patient reports improvement.'); expect(saved?['priority'], 'low');
    expect(saved?.containsKey('predictedScore'), isFalse); expect(tester.takeException(), isNull);
  });
}
