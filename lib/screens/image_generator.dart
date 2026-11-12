import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../services/image_generation_policy.dart';
import '../services/image_generation_service.dart';
import '../theme.dart';

class ImageGeneratorScreen extends StatefulWidget {
  const ImageGeneratorScreen({super.key});

  @override
  State<ImageGeneratorScreen> createState() => _ImageGeneratorScreenState();
}

class _ImageGeneratorScreenState extends State<ImageGeneratorScreen> {
  final _controller = TextEditingController();
  final _service = ImageGenerationService();
  Uint8List? _image;
  bool _generating = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    late final String prompt;
    try {
      prompt = validateImagePrompt(_controller.text);
    } on ArgumentError catch (error) {
      setState(() => _error = error.message.toString());
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
      _image = null;
    });
    try {
      final image = await _service.generate(prompt);
      if (mounted) setState(() => _image = image);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is StateError
            ? error.message.toString()
            : 'चित्र नहीं बन पाया। इंटरनेट जाँचकर फिर कोशिश करें।');
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI चित्र बनाएँ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'पढ़ाई के लिए सुरक्षित चित्र',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'जैसे: ओम के नियम का सरल सर्किट डायग्राम, मानव हृदय का शैक्षिक चित्र या सौर मंडल का मॉडल।',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'किस विषय का चित्र बनाना है?',
                hintText: 'चित्र का साफ़ विवरण लिखें…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_generating ? 'चित्र बन रहा है…' : 'चित्र बनाएँ'),
            ),
            const SizedBox(height: 10),
            const Text(
              'सुरक्षा जाँच लागू है। हर खाते से एक मिनट में एक अनुरोध। मुफ़्त AI दैनिक सीमा साझा है; सीमा पूरी होने पर अनुरोध रुक जाएगा और कोई paid सेवा नहीं चलेगी।',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'चित्र केवल इस स्क्रीन पर अस्थायी रूप से दिखेगा। यह Firestore या किसी सार्वजनिक स्टोरेज में सेव नहीं होगा।',
              style: TextStyle(fontSize: 13),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: kError)),
            ],
            if (_image != null) ...[
              const SizedBox(height: 20),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.memory(
                    _image!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('चित्र दिखाया नहीं जा सका।'),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
