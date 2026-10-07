import 'package:flutter/material.dart';

const _purple = Color(0xFF6335D6);
const _ink = Color(0xFF28253F);
const _muted = Color(0xFF77748C);

class LoginView extends StatefulWidget {
  final TextEditingController email, password;
  final String role;
  final bool busy;
  final ValueChanged<String> onRole;
  final VoidCallback onLogin, onReset, onSignup;
  const LoginView({super.key, required this.email, required this.password, required this.role, required this.busy,
    required this.onRole, required this.onLogin, required this.onReset, required this.onSignup});
  @override
  State<LoginView> createState() => _LoginViewState();
}
class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  bool _obscure = true;
  void _submit() {
    if (!widget.busy && _form.currentState!.validate()) widget.onLogin();
  }
  @override
  Widget build(BuildContext context) => Theme(data: Theme.of(context).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: _purple),
    textTheme: Theme.of(context).textTheme.apply(bodyColor: _ink, displayColor: _ink),
  ), child: Scaffold(backgroundColor: const Color(0xFFF5F3FB), body: SafeArea(child: LayoutBuilder(builder: (context, c) {
    final wide = c.maxWidth >= 1000;
    return SingleChildScrollView(padding: EdgeInsets.all(wide ? 32 : 18), child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? 1200 : 560),
      child: Column(children: [
        Row(children: [const Expanded(child: _Brand()), if (wide) const Text('Your care. Your workspace.', style: TextStyle(color: _muted, fontSize: 12))]),
        const SizedBox(height: 26),
        Material(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: Color(0xFFE5DFF1))), clipBehavior: Clip.antiAlias,
          child: wide ? IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Expanded(flex: 5, child: _LoginHero()),
            Expanded(flex: 5, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40), child: _loginForm())),
          ])) : Padding(padding: const EdgeInsets.all(22), child: _loginForm())),
        const SizedBox(height: 20), const Text('HealthCompanion • Your everyday care companion', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 11)),
      ]),
    )));
  }))));
  Widget _loginForm() => AutofillGroup(child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF0EBFD), borderRadius: BorderRadius.circular(20)),
      child: const Text('WELCOME BACK', style: TextStyle(color: _purple, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800))),
    const SizedBox(height: 16), const Text('Sign in to your\ncare workspace', style: TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w800)),
    const SizedBox(height: 12), const Text('Choose your account type to continue.', style: TextStyle(color: _muted, fontSize: 13)),
    const SizedBox(height: 22),
    Row(children: ['Patient', 'Doctor', 'Admin'].map((role) {
      final selected = widget.role == role;
      final icon = role == 'Patient' ? Icons.person_outline : role == 'Doctor' ? Icons.medical_services_outlined : Icons.admin_panel_settings_outlined;
      return Expanded(child: Padding(padding: EdgeInsets.only(right: role == 'Admin' ? 0 : 8), child: Semantics(selected: selected, button: true, label: '$role account', child: Material(
        color: selected ? _purple : const Color(0xFFF7F5FC), borderRadius: BorderRadius.circular(12),
        child: InkWell(key: ValueKey('login-role-$role'), borderRadius: BorderRadius.circular(12), onTap: widget.busy ? null : () => widget.onRole(role), child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(children: [Icon(icon, size: 22, color: selected ? Colors.white : _muted), const SizedBox(height: 8), Text(role, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : _ink))]))),
      ))));
    }).toList()),
    const SizedBox(height: 22),
    TextFormField(key: const ValueKey('login-email'), controller: widget.email, enabled: !widget.busy,
      keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.username, AutofillHints.email], autocorrect: false,
      decoration: _input('Email address', Icons.alternate_email_rounded, hint: 'you@example.com'),
      validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '') ? null : 'Enter a valid email address.'),
    const SizedBox(height: 18),
    TextFormField(key: const ValueKey('login-password'), controller: widget.password, enabled: !widget.busy, obscureText: _obscure,
      enableSuggestions: false, autocorrect: false, autofillHints: const [AutofillHints.password], textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _submit(),
      decoration: _input('Password', Icons.lock_outline_rounded, suffix: IconButton(onPressed: widget.busy ? null : () => setState(() => _obscure = !_obscure),
        tooltip: _obscure ? 'Show password' : 'Hide password', icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 21))),
      validator: (value) => value == null || value.isEmpty ? 'Enter your password.' : null),
    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: widget.busy ? null : widget.onReset, child: const Text('Forgot password?'))),
    const SizedBox(height: 10), SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: widget.busy ? null : _submit,
      style: FilledButton.styleFrom(backgroundColor: _purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: widget.busy ? const Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('Please wait…')])
        : Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: Text('Sign in as ${widget.role}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))), const SizedBox(width: 10), const Icon(Icons.arrow_forward_rounded, size: 18)]))),
    const SizedBox(height: 20),
    Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF7F5FC), borderRadius: BorderRadius.circular(12)),
      child: Text(widget.role == 'Patient' ? 'Your readings, reports and appointments are waiting in your personal workspace.' : widget.role == 'Doctor' ? 'Access assigned appointments, patient records and your clinical workspace.' : 'Manage accounts, appointments and application insights.', style: const TextStyle(fontSize: 12, height: 1.5, color: _muted))),
    const SizedBox(height: 18),
    if (widget.role == 'Patient') Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [const Text('New to HealthCompanion?', style: TextStyle(fontSize: 12, color: _muted)), TextButton(onPressed: widget.busy ? null : widget.onSignup, child: const Text('Create patient account'))])
    else const Text('Doctor and admin accounts are provided by your administrator.', style: TextStyle(fontSize: 12, color: _muted, height: 1.5)),
  ])));
  InputDecoration _input(String label, IconData icon, {String? hint, Widget? suffix}) => InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 21), suffixIcon: suffix,
    filled: true, fillColor: const Color(0xFFFBFAFD), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5DFF1))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5DFF1))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _purple, width: 1.5)));
}
class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24)),
    const SizedBox(width: 10), const Flexible(child: Text('HealthCompanion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
  ]);
}
class _LoginHero extends StatelessWidget {
  const _LoginHero();
  @override
  Widget build(BuildContext context) => Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF452198), Color(0xFF7951D2)])),
    padding: const EdgeInsets.all(40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('CONNECTED CARE', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 28), const Text('Your health,\nconnected.', style: TextStyle(fontSize: 46, height: 1.1, color: Colors.white, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18), const Text('Keep your records close.\nStay connected to your care team.', style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6)),
      const SizedBox(height: 40),
      Center(child: SizedBox(height: 180, width: 250, child: Stack(alignment: Alignment.center, children: [
        Container(width: 170, height: 170, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white12, width: 22))),
        Container(width: 116, height: 116, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(34)), child: const Icon(Icons.health_and_safety_outlined, size: 68, color: Colors.white)),
        Positioned(left: 0, top: 15, child: _badge(Icons.monitor_heart_outlined)), Positioned(right: 0, bottom: 15, child: _badge(Icons.calendar_month_outlined)),
      ]))),
      const SizedBox(height: 34),
      _feature(Icons.monitor_heart_outlined, 'See your progress', 'Measured readings and clear health patterns.'),
      const SizedBox(height: 20), _feature(Icons.folder_outlined, 'Keep care organised', 'Reports and appointments in one place.'),
      const SizedBox(height: 20), _feature(Icons.people_outline, 'Stay connected', 'Dedicated patient, doctor and admin workspaces.'),
    ]));
  Widget _badge(IconData icon) => Container(width: 54, height: 54, decoration: BoxDecoration(color: const Color(0xFFF2EBFF), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: _purple, size: 28));
  Widget _feature(IconData icon, String title, String text) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: Colors.white70, size: 24), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)), const SizedBox(height: 5), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
    ])),
  ]);
}
