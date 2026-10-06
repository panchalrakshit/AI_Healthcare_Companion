import 'package:flutter/material.dart';

class AdminAccountDialog extends StatefulWidget {
  final String role;
  final Map<String, dynamic>? initial;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const AdminAccountDialog({super.key, required this.role, this.initial, required this.onSave});
  @override
  State<AdminAccountDialog> createState() => _AdminAccountDialogState();
}

class _AdminAccountDialogState extends State<AdminAccountDialog> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  bool _saving = false;
  bool _hidePassword = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    for (final key in ['name', 'email', 'phone', 'password', 'specialization', 'qualification', 'experience', 'hospital', 'availability']) {
      final initial = widget.initial ?? <String, dynamic>{};
      final value = initial[key] ?? (key == 'name' ? initial['fullName'] : key == 'hospital' ? initial['hospitalName'] : null);
      _controllers[key] = TextEditingController(text: value?.toString() ?? (key == 'availability' ? 'Available' : ''));
    }
  }
  @override
  void dispose() {
    for (final controller in _controllers.values) { controller.dispose(); }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text('${widget.initial == null ? 'Add' : 'Edit'} ${widget.role}'),
      content: SizedBox(width: 480, child: SingleChildScrollView(child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field('name', 'Full name', required: true),
        _field('email', 'Email', required: true, type: TextInputType.emailAddress),
        _field('phone', 'Phone', type: TextInputType.phone),
        if (widget.initial == null) ...[
          _field('password', 'Temporary password', required: true, password: true),
          const Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Share the temporary password privately. The user can change it using Forgot Password.', style: TextStyle(fontSize: 12, color: Colors.grey))),
        ],
        if (widget.role == 'doctor') ...[
          _field('specialization', 'Specialization', required: true),
          _field('qualification', 'Qualification'),
          _field('experience', 'Experience (e.g. 5 years)'),
          _field('hospital', 'Hospital / clinic'),
          _field('availability', 'Availability'),
        ],
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
      ])))),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
          label: Text(_saving ? 'Saving…' : widget.initial == null ? 'Create account' : 'Save changes')),
      ],
    ),
  );

  Widget _field(String key, String label, {bool required = false, bool password = false, TextInputType? type}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(controller: _controllers[key], enabled: !_saving && !(key == 'email' && widget.initial?['uid'] != null), obscureText: password && _hidePassword,
      keyboardType: type, maxLength: password ? 128 : (key == 'email' ? 254 : key == 'phone' ? 40 : 200),
      decoration: InputDecoration(labelText: label, counterText: '', border: const OutlineInputBorder(),
        suffixIcon: password ? IconButton(onPressed: () => setState(() => _hidePassword = !_hidePassword), icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off)) : null),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (required && v.isEmpty) return 'Enter $label.';
        if (key == 'email' && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) return 'Enter a valid email.';
        if (password && v.length < 8) return 'Use at least 8 characters.';
        return null;
      },
    ),
  );
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onSave({ for (final e in _controllers.entries) e.key: e.value.text.trim() });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _saving = false; });
    }
  }
}
