import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/doctor/doctor_panel_widgets.dart';

void main() {
  testWidgets('doctor patient, assessment and follow-up cards fit narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DoctorPatientCard(
                  name: 'A very long patient name that should wrap instead of overflowing',
                  email: 'patient.with.a.very.long.email.address@example-health-companion.test',
                  appointmentCount: 12,
                  accessHint: 'Confirm an appointment before opening clinical records.',
                ),
                DoctorAssessmentCard(
                  patientName: 'A very long patient name for the assessment card',
                  notes: 'A detailed clinical note that is intentionally long to verify '
                      'that the text wraps within the available width and does not push '
                      'the priority label outside the card.',
                  updatedLabel: 'Updated 19/11/2026',
                  priority: 'high',
                  onTap: () {},
                ),
                DoctorFollowUpCard(
                  patientName: 'A patient with a long name that should wrap correctly',
                  dueLabel: '19/11/2026',
                  onOpenAssessments: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('A very long patient name that should wrap instead of overflowing'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('doctor patient and follow-up actions remain tappable', (tester) async {
    var patientOpened = false;
    var assessmentsOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              DoctorPatientCard(
                name: 'Patient',
                email: 'patient@example.com',
                appointmentCount: 1,
                accessHint: '',
                onOpen: () => patientOpened = true,
              ),
              DoctorFollowUpCard(
                patientName: 'Patient',
                dueLabel: 'Today',
                onOpenAssessments: () => assessmentsOpened = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open patient workspace'));
    await tester.pump();
    await tester.tap(find.text('View assessment'));
    await tester.pump();

    expect(patientOpened, isTrue);
    expect(assessmentsOpened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
