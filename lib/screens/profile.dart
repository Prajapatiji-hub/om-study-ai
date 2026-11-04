import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_repo.dart';
import '../theme.dart';
import 'onboarding.dart';

class ProfileScreen extends StatefulWidget {
  final UserRepo repo;
  const ProfileScreen({super.key, required this.repo});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  String _lang = 'hi';
  bool _loading = true, _saving = false;
  String? _msg;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    widget.repo.profile().first.then((p) {
      _name.text = (p['displayName'] ?? '').toString();
      final l = (p['language'] ?? 'hi').toString();
      _lang = const ['hi', 'en', 'hinglish'].contains(l) ? l : 'hi';
      if (mounted) setState(() => _loading = false);
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 80) {
      return setState(() {
        _msg = 'नाम खाली न रखें (80 अक्षर तक)।';
        _isError = true;
      });
    }
    setState(() {
      _saving = true;
      _msg = null;
    });
    try {
      await widget.repo.updateProfile({'displayName': name, 'language': _lang});
      await widget.repo.user.updateDisplayName(name);
      _msg = 'सेव हो गया।';
      _isError = false;
    } catch (e) {
      final code = e is FirebaseException ? e.code : e.runtimeType.toString();
      _msg = 'सेव नहीं हुआ (कारण: $code)। स्क्रीनशॉट भेजें।';
      _isError = true;
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('लॉगआउट करें?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('नहीं')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('हाँ, लॉगआउट')),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('मेरी प्रोफ़ाइल')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('ईमेल: ${widget.repo.user.email ?? '-'}',
                    style: const TextStyle(fontSize: 17)),
                const SizedBox(height: 16),
                TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'आपका नाम')),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _lang,
                  decoration: const InputDecoration(labelText: 'पसंदीदा भाषा'),
                  items: const [
                    DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hinglish', child: Text('Hinglish')),
                  ],
                  onChanged: (v) => setState(() => _lang = v ?? 'hi'),
                ),
                if (_msg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_msg!,
                        style: TextStyle(fontSize: 16, color: _isError ? kError : kTeal)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: _saving ? null : _save, child: const Text('सेव करें')),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => OnboardingScreen(repo: widget.repo, edit: true))),
                  child: const Text('सेटअप के जवाब बदलें'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _logout, child: const Text('लॉगआउट')),
              ],
            ),
    );
  }
}
