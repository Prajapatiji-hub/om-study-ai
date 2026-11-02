import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ai_teacher_service.dart';
import '../theme.dart';

class AiTeacherScreen extends StatefulWidget {
  final String mode;
  final String question;
  final String selectedAnswer;
  final String correctAnswer;
  final String explanation;

  const AiTeacherScreen({
    super.key,
    this.mode = 'tutor',
    this.question = '',
    this.selectedAnswer = '',
    this.correctAnswer = '',
    this.explanation = '',
  });

  @override
  State<AiTeacherScreen> createState() => _AiTeacherScreenState();
}

class _AiTeacherScreenState extends State<AiTeacherScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _service = AiTeacherService();
  final List<Map<String, String>> _messages = [];
  bool _sending = false;
  bool _loadingHistory = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'explain_question') {
      _controller.text = 'कृपया इस प्रश्न को आसान भाषा में चरण-दर-चरण समझाइए।';
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingHistory = false);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_teacher_messages')
          .orderBy('createdAt', descending: true)
          .limit(40)
          .get();
      final restored = snapshot.docs.reversed
          .map((doc) {
            final data = doc.data();
            return <String, String>{
              'role': data['role'] is String ? data['role'] as String : '',
              'text': data['text'] is String ? data['text'] as String : '',
            };
          })
          .where((item) =>
              (item['role'] == 'user' || item['role'] == 'model') &&
              (item['text'] ?? '').isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(restored);
        _loadingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingHistory = false;
        _error = 'पुरानी बातचीत लोड नहीं हो पाई। इंटरनेट जाँचकर फिर खोलें।';
      });
    }
  }

  Future<void> _saveTurn(String userText, String answer) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('लॉगिन की पुष्टि नहीं हुई।');
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_teacher_messages');
    final batch = FirebaseFirestore.instance.batch();
    final userDoc = collection.doc();
    final modelDoc = collection.doc();
    batch.set(userDoc, {
      'role': 'user',
      'text': userText,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(modelDoc, {
      'role': 'model',
      'text': answer,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _loadingHistory) return;
    setState(() {
      _sending = true;
      _error = null;
      _messages.add({'role': 'user', 'text': text});
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final history = _messages.length > 1
          ? _messages.sublist(0, _messages.length - 1).take(8).toList()
          : <Map<String, String>>[];
      final answer = await _service.ask(
        message: text,
        mode: widget.mode,
        question: widget.question,
        selectedAnswer: widget.selectedAnswer,
        correctAnswer: widget.correctAnswer,
        explanation: widget.explanation,
        history: history,
      );
      if (!mounted) return;
      setState(() => _messages.add({'role': 'model', 'text': answer}));
      _scrollToBottom();
      try {
        await _saveTurn(text, answer);
      } catch (_) {
        if (mounted) {
          setState(() => _error =
              'जवाब मिल गया, लेकिन बातचीत सेव नहीं हुई। इंटरनेट जाँचें और फिर कोशिश करें।');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        if (_messages.isNotEmpty && _messages.last['role'] == 'user') {
          _messages.removeLast();
        }
        _controller.text = text;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString();
    final value = raw.toLowerCase();
    if (value.contains('unauthenticated') || value.contains('पहले लॉगिन')) {
      return 'पहले अपने खाते में लॉगिन करें।';
    }
    if (value.contains('resource-exhausted') || value.contains('मुफ्त उपयोग सीमा')) {
      return 'Gemini की मुफ्त उपयोग सीमा अभी पूरी हुई है। बाद में कोशिश करें।';
    }
    if (value.contains('socketexception') || value.contains('network') ||
        value.contains('failed host lookup')) {
      return 'इंटरनेट कनेक्शन जाँचकर फिर कोशिश करें।';
    }
    if (value.contains('timeoutexception') || value.contains('timed out')) {
      return 'AI का जवाब आने में अधिक समय लगा। इंटरनेट जाँचकर फिर कोशिश करें।';
    }
    if (error is StateError) {
      final message = error.message.toString().trim();
      if (message.isNotEmpty) return message;
    }
    return 'AI जवाब नहीं दे पाया। थोड़ी देर बाद दोबारा कोशिश करें।';
  }

  @override
  Widget build(BuildContext context) {
    final explainMode = widget.mode == 'explain_question';
    return Scaffold(
      appBar: AppBar(
        title: Text(explainMode ? 'AI से प्रश्न समझें' : 'AI टीचर'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (explainMode)
              Container(
                width: double.infinity,
                color: const Color(0xFFEAF4F2),
                padding: const EdgeInsets.all(12),
                child: Text(
                  'प्रश्न: ${widget.question}\nआपका उत्तर: ${widget.selectedAnswer}\nसही उत्तर: ${widget.correctAnswer}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            Expanded(
              child: _loadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.smart_toy_outlined, size: 58, color: kTeal),
                                const SizedBox(height: 12),
                                Text(
                                  explainMode
                                      ? 'AI इस प्रश्न को चरण-दर-चरण समझाएगा।'
                                      : 'नमस्ते! मैं आपका AI पढ़ाई साथी हूँ। सवाल पूछिए।',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'महत्वपूर्ण परीक्षा या आधिकारिक जानकारी को विश्वसनीय स्रोत से जाँचें।',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length + (_sending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              return const Padding(
                                padding: EdgeInsets.all(12),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final item = _messages[index];
                            final isUser = item['role'] == 'user';
                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 340),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: isUser ? const Color(0xFFD9EFEB) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFD5E0DE)),
                                ),
                                child: SelectableText(item['text'] ?? ''),
                              ),
                            );
                          },
                        ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 4000,
                      decoration: const InputDecoration(
                        hintText: 'अपना सवाल लिखें…',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: (_sending || _loadingHistory) ? null : _send,
                    icon: const Icon(Icons.send),
                    color: Colors.white,
                    style: IconButton.styleFrom(backgroundColor: kTeal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
