import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/Patient_dashboard.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/patient/patient_data.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/patient/patient_forms.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/patient/patient_widgets.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/appointments/appointmentscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history uses dated measured readings without fabricating profile history', () {
    final now = DateTime(2026, 10, 6, 12);
    final stats = PatientStats(PatientSnapshot(profile: {'heartRate': 70}, records: [
      {'vitals': {'heartRate': 82}, 'measuredAt': Timestamp.fromDate(now.subtract(const Duration(days: 2)))},
      {'vitals': {'heartRate': 72}, 'measuredAt': Timestamp.fromDate(now)},
      {'vitals': {'heartRate': double.nan}, 'measuredAt': Timestamp.fromDate(now)},
      {'vitals': {'heartRate': 100}, 'measuredAt': Timestamp.fromDate(now.subtract(const Duration(days: 40)))},
      {'vitals': {'heartRate': 90}, 'measuredAt': Timestamp.fromDate(now.add(const Duration(days: 1)))},
      {'vitals': {'heartRate': 60}},
    ]), now: now, days: 7);
    expect(stats.points('heartRate').map((p) => p.value), [82, 72]);
    expect(stats.points('weight'), isEmpty);
    expect(PatientStats(PatientSnapshot(profile: {'heartRate': 70}), now: now).points('heartRate'), isEmpty);
  });
  test('appointment patterns exclude future and missing dates; upcoming excludes cancelled visits', () {
    final now = DateTime(2026, 10, 6, 12);
    final stats = PatientStats(PatientSnapshot(appointments: [
      {'status': 'completed', 'appointmentDate': Timestamp.fromDate(now)},
      {'status': 'confirmed', 'appointmentDate': Timestamp.fromDate(now.add(const Duration(days: 1)))},
      {'status': 'pending', 'appointmentDate': Timestamp.fromDate(now.subtract(const Duration(days: 1)))},
      {'status': 'cancelled', 'appointmentDate': Timestamp.fromDate(now.add(const Duration(days: 2)))},
      {'status': 'pending'},
    ]), now: now);
    expect(stats.period.length, 2); expect(stats.weekdays[1], 1);
    expect(stats.upcoming.length, 1); expect(stats.upcoming.single['status'], 'confirmed');
    expect(stats.outcomes['completed'], 1);
  });
  test('CSV escapes cells and neutralises spreadsheet formulas', () {
    final csv = patientRecordsCsv([{'title': '=HYPERLINK("bad")', 'description': 'a,b\nsecond line'}]);
    expect(csv, contains('"\'=HYPERLINK(""bad"")"'));
    expect(csv, contains('"a,b\nsecond line"'));
  });
  testWidgets('patient charts fit 320px and switch metric and time range', (tester) async {
    tester.view.physicalSize = const Size(320, 1500); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    var days = 30;
    final now = DateTime.now();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: PatientInsights(
      stats: PatientStats(PatientSnapshot(records: [{'vitals': {'heartRate': 76}, 'recordDate': Timestamp.fromDate(now)}]), now: now), onRange: (d) => days = d))))));
    expect(find.text('76.0 bpm'), findsOneWidget);
    await tester.tap(find.text('7 days')); expect(days, 7);
    await tester.tap(find.text('Weight')); await tester.pumpAndSettle();
    expect(find.textContaining('No readings for this metric'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reading form rejects empty and invalid values then saves only entered metrics', (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () => showDialog<void>(context: context,
      builder: (_) => PatientEditor(kind: 'Reading', onSave: (fields) async { saved = fields; })), child: const Text('Open'))))));
    await tester.tap(find.text('Open')); await tester.pumpAndSettle();
    await tester.tap(find.text('Save reading')); await tester.pumpAndSettle();
    expect(find.text('Enter at least one measured reading.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Heart rate (bpm)'), '-2');
    await tester.tap(find.text('Save reading')); await tester.pumpAndSettle();
    expect(find.text('Enter a positive number up to 10000.'), findsOneWidget);
    expect(saved, isNull);
    await tester.enterText(find.widgetWithText(TextFormField, 'Heart rate (bpm)'), '76');
    await tester.tap(find.text('Save reading')); await tester.pumpAndSettle();
    expect(saved, {'heartRate': 76.0}); expect(tester.takeException(), isNull);
  });
  testWidgets('profile edit changes only permitted personal fields', (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () => showDialog<void>(context: context,
      builder: (_) => PatientEditor(kind: 'Profile', initial: const {'name': 'Original', 'phone': '123', 'role': 'patient', 'email': 'test@example.com'},
        onSave: (fields) async { saved = fields; })), child: const Text('Open'))))));
    await tester.tap(find.text('Open')); await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Updated');
    await tester.tap(find.text('Save changes')); await tester.pumpAndSettle();
    expect(saved, {'name': 'Updated', 'phone': '123'});
  });
  testWidgets('booking requires a reason and submits a future pending request payload', (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () => showDialog<void>(context: context,
      builder: (_) => PatientBookingForm(doctor: const {'name': 'Dr. Test'}, onSave: (fields) async { saved = fields; })), child: const Text('Open'))))));
    await tester.tap(find.text('Open')); await tester.pumpAndSettle();
    await tester.tap(find.text('Request visit')); await tester.pumpAndSettle();
    expect(find.text('Enter your reason for the visit.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Reason for visit'), 'Follow up');
    await tester.tap(find.text('Request visit')); await tester.pumpAndSettle();
    expect(saved?['reason'], 'Follow up');
    expect(patientDate(saved?['appointmentDate'])!.isAfter(DateTime.now()), isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('populated overview fits a narrow phone and uses saved readings', (tester) async {
    tester.view.physicalSize = const Size(320, 1800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final now = Timestamp.now();
    await tester.pumpWidget(MaterialApp(home: PatientWorkspace(data: PatientSnapshot(
      user: {'name': 'Patient with a longer full name'}, profile: {'heartRate': 76, 'bloodPressure': '120/80', 'updatedAt': now},
      records: [{'title': 'Measured health readings', 'recordType': 'Vital Signs', 'recordDate': now, 'vitals': {'heartRate': 76}}],
      appointments: [{'doctorName': 'Dr. Test', 'status': 'confirmed', 'appointmentDate': now, 'appointmentTime': '10:00 AM'}]),
      onReading: () {}, onProfile: () {}, onAddRecord: () {}, onEditRecord: (_) {}, onDeleteRecord: (_) {}, onLogout: () {}, onResetPassword: () {}, onRetry: () {})));
    await tester.pumpAndSettle();
    expect(find.text('A clearer view of your health'), findsOneWidget);
    expect(find.text('76.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -1400)); await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Open navigation menu')); await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Health records')); await tester.pumpAndSettle();
    expect(find.text('Your health records'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(1280, 1800); await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('My profile')); await tester.pumpAndSettle();
    expect(find.text('Personal information'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Symptom checker')); await tester.pumpAndSettle();
    expect(find.text('Symptom checker • college demo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('patient workspace renders empty and live error states on mobile', (tester) async {
    tester.view.physicalSize = const Size(320, 1800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    var retried = false;
    await tester.pumpWidget(MaterialApp(home: PatientWorkspace(data: PatientSnapshot(user: {'name': 'Patient'}, errors: {'Records': 'Permission denied'}),
      onReading: () {}, onProfile: () {}, onAddRecord: () {}, onEditRecord: (_) {}, onDeleteRecord: (_) {}, onLogout: () {}, onResetPassword: () {}, onRetry: () => retried = true)));
    expect(find.text('Records: Permission denied'), findsOneWidget);
    await tester.tap(find.text('Retry')); expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });
}
