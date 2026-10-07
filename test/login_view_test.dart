import 'package:ai_healthcompanion_using_flutter/features/auth/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile login validates fields, preserves password spaces and supports visibility and submit', (tester) async {
    tester.view.physicalSize = const Size(320, 1100); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final email = TextEditingController(), password = TextEditingController();
    addTearDown(email.dispose); addTearDown(password.dispose);
    var signedIn = 0, reset = false, signup = false;
    await tester.pumpWidget(MaterialApp(home: LoginView(email: email, password: password, role: 'Patient', busy: false, onRole: (_) {},
      onLogin: () => signedIn++, onReset: () => reset = true, onSignup: () => signup = true)));
    await tester.tap(find.text('Sign in as Patient')); await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget); expect(find.text('Enter your password.'), findsOneWidget); expect(signedIn, 0);
    await tester.enterText(find.byKey(const ValueKey('login-email')), 'patient@example.com');
    await tester.enterText(find.byKey(const ValueKey('login-password')), ' password with spaces ');
    await tester.tap(find.byTooltip('Show password')); await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.descendant(of: find.byKey(const ValueKey('login-password')), matching: find.byType(TextField))).obscureText, isFalse);
    await tester.tap(find.byKey(const ValueKey('login-password')));
    await tester.testTextInput.receiveAction(TextInputAction.done); await tester.pumpAndSettle();
    expect(signedIn, 1); expect(password.text, ' password with spaces ');
    await tester.tap(find.text('Forgot password?')); expect(reset, isTrue);
    await tester.ensureVisible(find.text('Create patient account')); await tester.tap(find.text('Create patient account')); expect(signup, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('desktop role cards change the requested role and describe managed accounts', (tester) async {
    tester.view.physicalSize = const Size(1280, 1200); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final email = TextEditingController(), password = TextEditingController();
    addTearDown(email.dispose); addTearDown(password.dispose);
    var role = 'Patient';
    await tester.pumpWidget(MaterialApp(home: StatefulBuilder(builder: (_, setState) => LoginView(email: email, password: password, role: role, busy: false,
      onRole: (value) => setState(() => role = value), onLogin: () {}, onReset: () {}, onSignup: () {}))));
    expect(find.text('Your health,\nconnected.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('login-role-Doctor'))); await tester.pumpAndSettle();
    expect(find.text('Sign in as Doctor'), findsOneWidget); expect(find.text('Create patient account'), findsNothing);
    expect(find.text('Doctor and admin accounts are provided by your administrator.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('login-role-Admin'))); await tester.pumpAndSettle();
    expect(find.text('Sign in as Admin'), findsOneWidget); expect(tester.takeException(), isNull);
  });
  testWidgets('busy state disables submissions, role selection and reset', (tester) async {
    final email = TextEditingController(text: 'patient@example.com'), password = TextEditingController(text: 'secret');
    addTearDown(email.dispose); addTearDown(password.dispose);
    var actions = 0;
    await tester.pumpWidget(MaterialApp(home: LoginView(email: email, password: password, role: 'Patient', busy: true,
      onRole: (_) => actions++, onLogin: () => actions++, onReset: () => actions++, onSignup: () => actions++)));
    await tester.tap(find.byKey(const ValueKey('login-role-Doctor')));
    await tester.tap(find.text('Forgot password?'));
    expect(actions, 0); expect(find.text('Please wait…'), findsOneWidget);
    expect(tester.widget<TextFormField>(find.byKey(const ValueKey('login-email'))).enabled, isFalse);
  });
}
