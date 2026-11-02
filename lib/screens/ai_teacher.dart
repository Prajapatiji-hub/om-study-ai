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
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'explain_question') {
      _controller.text = 'कृपया इस प्रश्न को आसान भाषा में चरण-दर-चरण समझाइए।';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
      _messages.add({'role': 'user', 'text': text});
    });
    _controller.clear();

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _messages.removeLast();
        _controller.text = text;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _friendlyError(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('unauthenticated')) return 'पहले अपने खाते में लॉगिन करें।';
    if (value.contains('resource-exhausted')) return 'अभी सवालों की सीमा पूरी हुई है। थोड़ी देर बाद कोशिश करें।';
    if (value.contains('not-found') || value.contains('unavailable')) {
      return 'AI सेवा अभी तैयार नहीं है या उपलब्ध नहीं है। Backend सेटअप पूरा होने पर फिर कोशिश करें।';
    }
    if (value.contains('network')) return 'इंटरनेट कनेक्शन जाँचकर फिर कोशिश करें।';
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
              child: _messages.isEmpty
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
                    onPressed: _sending ? null : _send,
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
