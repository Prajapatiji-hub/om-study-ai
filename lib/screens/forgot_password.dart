import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../services/user_repo.dart';
import '../theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _sent = false;

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('पासवर्ड रीसेट')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('अपना ईमेल लिखें। हम पासवर्ड बदलने का लिंक भेजेंगे।',
                style: TextStyle(fontSize: 17)),
            const SizedBox(height: 16),
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'ईमेल')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: kError, fontSize: 16)),
            ],
            if (_sent) ...[
              const SizedBox(height: 12),
              const Text('अगर यह ईमेल हमारे पास है, तो लिंक भेज दिया गया है। Spam फ़ोल्डर भी देखें।',
                  style: TextStyle(fontSize: 16, color: kTeal)),
            ],
            const SizedBox(height: 20),
            FilledButton(
                onPressed: _busy ? null : _send, child: const Text('लिंक भेजें')),
          ],
        ),
      ),
    );
  }
}
