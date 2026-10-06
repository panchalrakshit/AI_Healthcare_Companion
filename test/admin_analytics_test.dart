import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/admin/admin_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('analytics show real totals, exclude undated records and switch ranges', (tester) async {
    final now = DateTime.now();
    var selected = 30;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AdminAnalytics(
      appointments: [
        {'appointmentDate': Timestamp.fromDate(now), 'status': 'completed', 'specialization': 'Cardiology'},
        {'appointmentDate': Timestamp.fromDate(now), 'status': 'pending', 'specialization': 'Cardiology'},
        {'status': 'pending'},
        {'appointmentDate': Timestamp.fromDate(now.subtract(const Duration(days: 100))), 'status': 'pending'},
      ],
      users: [{'createdAt': Timestamp.fromDate(now)}], days: 30, onDaysChanged: (d) => selected = d,
    )))));
    expect(find.text('2 appointments in selected period'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Cardiology'), findsOneWidget);
    await tester.tap(find.text('Last 7 days'));
    expect(selected, 7);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty charts fit a narrow mobile screen', (tester) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: Padding(
      padding: const EdgeInsets.all(22), child: AdminAnalytics(appointments: const [], users: const [], days: 7, onDaysChanged: (_) {}),
    )))));
    expect(find.text('No appointments in this period.'), findsOneWidget);
    expect(find.text('No outcomes to display.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
