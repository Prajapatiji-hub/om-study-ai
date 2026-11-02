import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/user_repo.dart';
import '../theme.dart';

class QuizHistoryScreen extends StatelessWidget {
  final UserRepo repo;
  const QuizHistoryScreen({super.key, required this.repo});

  String _date(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate().toLocal();
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = d.year.toString();
      final hour = d.hour.toString().padLeft(2, '0');
      final minute = d.minute.toString().padLeft(2, '0');
      return '$day/$month/$year • $hour:$minute';
    }
    return 'समय उपलब्ध नहीं';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('मेरी प्रगति')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: repo.quizAttempts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('टेस्ट परिणाम लोड नहीं हुए। इंटरनेट और Firebase Rules जाँचें।',
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights_outlined, size: 64, color: kTeal),
                    SizedBox(height: 12),
                    Text('अभी कोई टेस्ट परिणाम नहीं है।',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    SizedBox(height: 8),
                    Text('प्रैक्टिस टेस्ट पूरा करने के बाद आपकी प्रगति यहाँ दिखेगी।',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          var totalScore = 0;
          var totalQuestions = 0;
          var bestPercent = 0;
          for (final doc in docs) {
            final data = doc.data();
            final score = data['score'] is int ? data['score'] as int : 0;
            final total = data['total'] is int ? data['total'] as int : 0;
            if (total > 0 && score >= 0 && score <= total) {
              totalScore += score;
              totalQuestions += total;
              final percent = (score * 100 / total).round();
              if (percent > bestPercent) bestPercent = percent;
            }
          }
          final average = totalQuestions == 0
              ? 0
              : (totalScore * 100 / totalQuestions).round();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _stat('टेस्ट', docs.length.toString())),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('औसत अंक', '$average%')),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('सबसे अच्छा', '$bestPercent%')),
                ],
              ),
              const SizedBox(height: 18),
              const Text('हाल के परिणाम',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (var i = 0; i < docs.length; i++)
                _attemptCard(docs[i].data(), i),
              const SizedBox(height: 12),
              const Text(
                'औसत और सर्वश्रेष्ठ परिणाम उपलब्ध सेव किए गए अधिकतम 50 टेस्ट पर आधारित हैं।',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTeal)),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _attemptCard(Map<String, dynamic> data, int index) {
    final score = data['score'] is int ? data['score'] as int : 0;
    final total = data['total'] is int ? data['total'] as int : 0;
    final safeScore = total > 0 ? score.clamp(0, total) : 0;
    final percent = total > 0 ? (safeScore * 100 / total).round() : 0;
    final title = data['quizId'] == 'starter_basics_01'
        ? 'शुरुआती अभ्यास टेस्ट'
        : 'प्रैक्टिस टेस्ट';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kTeal.withOpacity(0.12),
          child: Text('$percent%', style: const TextStyle(color: kTeal, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${safeScore.toInt()} / $total सही • ${_date(data['createdAt'])}'),
        trailing: const Icon(Icons.check_circle_outline, color: kTeal),
      ),
    );
  }
}
