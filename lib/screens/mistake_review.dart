import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../services/user_repo.dart';
import '../theme.dart';

class MistakeReviewScreen extends StatelessWidget {
  final UserRepo repo;
  const MistakeReviewScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('मेरी गलतियों की कॉपी')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: repo.quizAttempts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('गलत उत्तर लोड नहीं हो पाए। इंटरनेट और Firebase Rules जाँचें।',
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final mistakes = <Map<String, dynamic>>[];
          for (final attempt in snapshot.data!.docs) {
            final data = attempt.data();
            final raw = data['responses'];
            if (raw is! List) continue; // Older attempts only stored option indexes.
            for (final item in raw) {
              if (item is! Map) continue;
              final response = Map<String, dynamic>.from(item);
              final selected = response['selectedIndex'];
              final correct = response['correctIndex'];
              final options = response['options'];
              if (selected is int && correct is int && selected != correct &&
                  options is List && selected >= 0 && correct >= 0 &&
                  selected < options.length && correct < options.length &&
                  response['question'] is String) {
                mistakes.add({
                  ...response,
                  'attemptAt': data['createdAt'],
                });
              }
            }
          }

          if (mistakes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.task_alt, size: 64, color: kTeal),
                    SizedBox(height: 12),
                    Text('अभी समीक्षा के लिए कोई गलत उत्तर नहीं है।',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('नया प्रैक्टिस टेस्ट देने के बाद गलत उत्तर यहाँ दिखेंगे।',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'कुल ${mistakes.length} गलत उत्तर • सही जवाब और हल पढ़कर दोबारा अभ्यास करें।',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              for (var i = 0; i < mistakes.length; i++)
                _mistakeCard(mistakes[i], i),
              const SizedBox(height: 12),
              const Text(
                'यह सूची आपके खाते के हाल के अधिकतम 50 टेस्ट प्रयासों से बनती है। पुराने प्रयास जिनमें प्रश्न का पूरा विवरण सेव नहीं था, यहाँ शामिल नहीं होंगे।',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mistakeCard(Map<String, dynamic> item, int index) {
    final options = (item['options'] as List).cast<String>();
    final selected = item['selectedIndex'] as int;
    final correct = item['correctIndex'] as int;
    final date = item['attemptAt'];
    String dateText = 'तारीख उपलब्ध नहीं';
    if (date is Timestamp) {
      final d = date.toDate().toLocal();
      dateText = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('प्रश्न ${index + 1}', style: const TextStyle(color: kTeal, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(item['question'] as String,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text('आपका उत्तर: ${options[selected]}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('सही उत्तर: ${options[correct]}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(item['explanation'] as String? ?? 'इस प्रश्न का हल उपलब्ध नहीं है।'),
            const SizedBox(height: 6),
            Text(dateText, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
