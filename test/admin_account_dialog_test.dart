import 'package:ai_healthcompanion_using_flutter/features/auth/dashboards/admin/admin_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('creation validates required fields and passes account details to the service', (tester) async {
    Map<String, dynamic>? saved;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () => showDialog<void>(context: context, builder: (_) => AdminAccountDialog(
        role: 'patient', onSave: (fields) async { saved = fields; },
      )), child: const Text('Open'),
    )))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter Full name.'), findsOneWidget);
    expect(saved, isNull);
    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'New Patient');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'patient@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Temporary password'), 'TemporaryPass123!');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(saved?['name'], 'New Patient');
    expect(saved?['email'], 'patient@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing pre-fills legacy names and hospital fields without requesting a password', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AdminAccountDialog(
      role: 'doctor', initial: const {'fullName': 'Legacy Doctor', 'hospitalName': 'City Clinic'}, onSave: (_) async {},
    ))));
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.any((field) => field.controller?.text == 'Legacy Doctor'), isTrue);
    expect(fields.any((field) => field.controller?.text == 'City Clinic'), isTrue);
    expect(find.text('Temporary password'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
