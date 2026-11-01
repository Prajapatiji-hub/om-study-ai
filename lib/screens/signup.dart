import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_repo.dart';
import '../theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || name.length > 80) {
      return setState(() => _error = 'अपना नाम लिखें (80 अक्षर तक)।');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return setState(() => _error = 'सही ईमेल लिखें।');
    }
    if (_pass.text.length < 8) {
      return setState(() => _error = 'पासवर्ड कम से कम 8 अक्षर का रखें।');
    }
    if (_pass.text != _pass2.text) {
      return setState(() => _error = 'दोनों पासवर्ड एक जैसे नहीं हैं।');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: _pass.text);
      await cred.user!.updateDisplayName(name);
      await cred.user!.reload();
      final u = FirebaseAuth.instance.currentUser!;
      await UserRepo(u).ensureProfile();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('खाता बनाएँ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'आपका नाम')),
            const SizedBox(height: 14),
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'ईमेल')),
            const SizedBox(height: 14),
            TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'पासवर्ड (कम से कम 8 अक्षर)')),
            const SizedBox(height: 14),
            TextField(
                controller: _pass2,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'पासवर्ड दोबारा')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: kError, fontSize: 16)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 3))
                  : const Text('खाता बनाएँ'),
            ),
          ],
        ),
      ),
    );
  }
}
