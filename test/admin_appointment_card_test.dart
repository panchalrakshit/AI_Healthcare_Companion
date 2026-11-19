import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/admin/admin_appointment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin appointment card wraps long content on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: AdminAppointmentCard(
                patientName: 'A very long patient name that needs wrapping on a phone screen',
                doctorName: 'A very long doctor name and specialization',
                status: 'confirmed',
                dateLabel: '19/11/2026 • 10:30 AM',
                reason: 'A detailed reason for consultation that should wrap and remain readable.',
                onAction: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('CONFIRMED'), findsOneWidget);
    expect(find.byTooltip('Appointment actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin appointment card exposes status actions', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminAppointmentCard(
            patientName: 'Patient',
            doctorName: 'Doctor',
            status: 'pending',
            dateLabel: '20/11/2026 • 10:00 AM',
            reason: 'Consultation',
            onAction: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Appointment actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm').last);
    await tester.pumpAndSettle();

    expect(selected, 'confirmed');
    expect(tester.takeException(), isNull);
  });
}

void _noop(String value) {}
