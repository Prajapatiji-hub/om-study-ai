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
  final _memorySummary = TextEditingController();
  final _strengths = TextEditingController();
  final _weakTopics = TextEditingController();
  final _preferredStyle = TextEditingController();
  String _lang = 'hi';
  bool _loading = true, _saving = false, _savingMemory = false;
  String? _msg, _memoryMsg;
  bool _isError = false, _memoryError = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await widget.repo.profile().first;
      final memory = await widget.repo.loadStudyMemory();
      _name.text = (p['displayName'] ?? '').toString();
      final l = (p['language'] ?? 'hi').toString();
      _lang = const ['hi', 'en', 'hinglish'].contains(l) ? l : 'hi';
      _memorySummary.text = (memory['summary'] ?? '').toString();
      _strengths.text = _asLines(memory['strengths']);
      _weakTopics.text = _asLines(memory['weakTopics']);
      _preferredStyle.text = (memory['preferredStyle'] ?? '').toString();
    } catch (_) {
      _msg = 'प्रोफ़ाइल लोड नहीं हुई। इंटरनेट और अनुमति जाँचें।';
      _isError = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  String _asLines(dynamic value) =>
      value is List ? value.whereType<String>().join('\n') : '';

  List<String> _toLines(String value) => value
      .split(RegExp(r'[\n,;]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();

  @override
  void dispose() {
    _name.dispose();
    _memorySummary.dispose();
    _strengths.dispose();
    _weakTopics.dispose();
    _preferredStyle.dispose();
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
    setState(() { _saving = true; _msg = null; });
    try {
      await widget.repo.updateProfile({'displayName': name, 'language': _lang});
      await widget.repo.user.updateDisplayName(name);
      _msg = 'प्रोफ़ाइल सेव हो गई।';
      _isError = false;
    } catch (e) {
      final code = e is FirebaseException ? e.code : e.runtimeType.toString();
      _msg = 'प्रोफ़ाइल सेव नहीं हुई (कारण: $code)।';
      _isError = true;
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _saveMemory() async {
    setState(() { _savingMemory = true; _memoryMsg = null; });
    try {
      await widget.repo.saveStudyMemory(
        summary: _memorySummary.text,
        strengths: _toLines(_strengths.text),
        weakTopics: _toLines(_weakTopics.text),
        preferredStyle: _preferredStyle.text,
      );
      _memoryMsg = 'AI Study Memory सेव हो गई। AI Teacher इसे अगले सवाल से उपयोग करेगा।';
      _memoryError = false;
    } catch (e) {
      final code = e is FirebaseException ? e.code : e.runtimeType.toString();
      _memoryMsg = e is ArgumentError
          ? e.message.toString()
          : 'Memory सेव नहीं हुई (कारण: $code)। यदि permission-denied है, अंतिम Firestore Rules प्रकाशित होने बाकी हैं।';
      _memoryError = true;
    }
    if (mounted) setState(() => _savingMemory = false);
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

  Widget _memoryField(String label, TextEditingController controller,
      {int lines = 3, int maxLength = 2000, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        minLines: lines,
        maxLines: lines + 2,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
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
                  decoration: const InputDecoration(labelText: 'आपका नाम'),
                ),
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
                        style: TextStyle(fontSize: 14, color: _isError ? kError : kTeal)),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('प्रोफ़ाइल सेव करें'),
                ),
                const Divider(height: 36),
                const Text('मेरी AI Study Memory',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('यह जानकारी केवल आपके खाते में रहती है। AI Teacher इसे आपके स्तर और पसंद के अनुसार पढ़ाने के लिए उपयोग करेगा।'),
                _memoryField('मेरी पढ़ाई का सार', _memorySummary,
                    hint: 'जैसे: कक्षा 12, बोर्ड परीक्षा की तैयारी, रोज़ 2 घंटे'),
                _memoryField('मेरे मजबूत विषय (हर लाइन में एक)', _strengths,
                    maxLength: 720, hint: 'जैसे: गणित\nभौतिकी'),
                _memoryField('जिन विषयों में मदद चाहिए (हर लाइन में एक)', _weakTopics,
                    maxLength: 720, hint: 'जैसे: रसायन विज्ञान\nओम का नियम'),
                _memoryField('मुझे किस तरह समझाना पसंद है?', _preferredStyle,
                    maxLength: 300, lines: 2,
                    hint: 'जैसे: आसान हिंदी, छोटे उदाहरण और चरण-दर-चरण'),
                if (_memoryMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_memoryMsg!,
                        style: TextStyle(color: _memoryError ? kError : kTeal)),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _savingMemory ? null : _saveMemory,
                  icon: _savingMemory
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.psychology_alt_outlined),
                  label: const Text('AI Study Memory सेव करें'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OnboardingScreen(repo: widget.repo, edit: true),
                    ),
                  ),
                  child: const Text('सेटअप के जवाब बदलें'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _logout, child: const Text('लॉगआउट')),
              ],
            ),
    );
  }
}
