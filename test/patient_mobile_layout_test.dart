import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/appointments/appointmentscreen.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/Patient_dashboard.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/patient/patient_data.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/patient/patient_widgets.dart';

void main() {
  for (final width in <double>[320, 360, 390, 430, 768, 1280]) {
    for (final scale in <double>[1, 1.6]) {
      testWidgets('Overview fits $width px at text scale $scale', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: PatientWorkspace(
            data: PatientSnapshot(user: {'name': 'Patient with a long display name'}, profile: {'heartRate': 70}),
            onReading: () {}, onProfile: () {}, onAddRecord: () {},
            onLogout: () {}, onResetPassword: () {}, onRetry: () {},
            onEditRecord: (_) {}, onDeleteRecord: (_) {},
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final panel = tester.getRect(find.ancestor(
          of: find.text('Latest health profile'), matching: find.byType(PatientPanel),
        ).first);
        expect(panel.left, closeTo(width >= 1050 ? 278 : 16, .1));
        expect(panel.right, closeTo(width - (width >= 1050 ? 30 : 16), .1));
        if (width == 390 && scale == 1) {
          final upcoming = tester.getRect(find.ancestor(
            of: find.text('Upcoming visits'), matching: find.byType(InkWell),
          ).first);
          final records = tester.getRect(find.ancestor(
            of: find.text('Saved records'), matching: find.byType(InkWell),
          ).first);
          expect(upcoming.top, closeTo(records.top, .1));
          expect(upcoming.width, closeTo(records.width, .1));
          expect(upcoming.right, lessThan(records.left));
        }
      });

      testWidgets('Visit cards share both edges at $width px / $scale', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PatientPanel(title: 'Visit history', child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PatientAppointmentCard(appointment: {
                    'doctorName': 'Dr. A', 'status': 'pending',
                    'appointmentDate': DateTime(2026, 10, 10), 'appointmentTime': '10:00 AM',
                  }, onCancel: () {}),
                  PatientAppointmentCard(appointment: {
                    'doctorName': 'Dr. A much longer doctor name', 'status': 'completed',
                    'reason': 'A longer reason that wraps onto multiple lines.',
                    'appointmentDate': DateTime(2026, 10, 11), 'appointmentTime': '11:00 AM',
                  }, onCancel: () {}),
                ],
              )),
            ]),
          )),
        ))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final cards = find.byType(PatientAppointmentCard);
        final first = tester.getRect(cards.at(0));
        final second = tester.getRect(cards.at(1));
        expect(first.left, closeTo(second.left, .1));
        expect(first.right, closeTo(second.right, .1));
        expect(first.width, closeTo(width - 32 - (width < 600 ? 32 : 44), .1));
        expect(find.text('Cancel appointment'), findsOneWidget);
      });
    }
  }
}
