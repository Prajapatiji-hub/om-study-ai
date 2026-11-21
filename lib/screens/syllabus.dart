import 'package:material_ui/material_ui.dart';

import '../data/syllabus_data.dart';
import '../services/user_repo.dart';
import '../theme.dart';

int _doneCount(Track t, Map<String, dynamic> data) {
  final valid = t.allKeys;
  return data.entries.where((e) => e.value == true && valid.contains(e.key)).length;
}

class SyllabusScreen extends StatelessWidget {
  final UserRepo repo;
  const SyllabusScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('मेरा सिलेबस')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: repo.profile(),
        builder: (context, snap) {
          final goals = (snap.data?['selectedGoals'] is List)
              ? List<String>.from(snap.data!['selectedGoals'])
              : <String>[];
          final tracks =
              kTracks.where((t) => goals.isEmpty || goals.contains(t.goal)).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'ये सूचियाँ शुरुआती सुझाव हैं और अभी आधिकारिक नहीं हैं। हर सूची के अंदर बताया है कि सही सिलेबस कहाँ से मिलाएँ।',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              for (final t in tracks) _TrackCard(repo: repo, track: t),
            ],
          );
        },
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final UserRepo repo;
  final Track track;
  const _TrackCard({required this.repo, required this.track});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: repo.progress(track.id),
      builder: (context, snap) {
        final done = _doneCount(track, snap.data ?? {});
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            title: Text(track.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                      value: track.total == 0 ? 0 : done / track.total, minHeight: 6),
                  const SizedBox(height: 6),
                  Text('$done / ${track.total} टॉपिक पूरे'),
                  Text(track.verified ? 'आधिकारिक स्रोत से जाँचा हुआ' : 'सुझाया हुआ: आधिकारिक से मिलाएँ',
                      style: TextStyle(
                          color: track.verified ? kTeal : const Color(0xFF8A5A00),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => TrackScreen(repo: repo, track: track))),
          ),
        );
      },
    );
  }
}

class TrackScreen extends StatelessWidget {
  final UserRepo repo;
  final Track track;
  const TrackScreen({super.key, required this.repo, required this.track});

  Future<void> _toggle(BuildContext context, String key, bool done) async {
    try {
      await repo.setTopicDone(track.id, key, done);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('सेव नहीं हुआ। इंटरनेट जाँचकर दोबारा कोशिश करें।')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(track.title, style: const TextStyle(fontSize: 18))),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: repo.progress(track.id),
        builder: (context, snap) {
          final data = snap.data ?? {};
          final done = _doneCount(track, data);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF3DC), borderRadius: BorderRadius.circular(12)),
                child: Text(track.note, style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                  value: track.total == 0 ? 0 : done / track.total, minHeight: 8),
              const SizedBox(height: 6),
              Text('$done / ${track.total} टॉपिक पूरे', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              for (final s in track.subjects)
                ExpansionTile(
                  title: Text(s.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${s.topics.where((t) => data[track.keyOf(s, t)] == true).length} / ${s.topics.length}'),
                  children: [
                    for (final t in s.topics)
                      CheckboxListTile(
                        value: data[track.keyOf(s, t)] == true,
                        title: Text(t.title, style: const TextStyle(fontSize: 17)),
                        onChanged: (v) => _toggle(context, track.keyOf(s, t), v == true),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
