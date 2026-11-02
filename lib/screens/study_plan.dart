import 'package:flutter/material.dart';

import '../services/user_repo.dart';
import '../theme.dart';

class StudyPlanScreen extends StatefulWidget {
  final UserRepo repo;
  const StudyPlanScreen({super.key, required this.repo});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  final _taskController = TextEditingController();
  bool _adding = false;
  String? _error;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _taskController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'पहले पढ़ाई का काम लिखें।');
      return;
    }
    setState(() { _adding = true; _error = null; });
    try {
      await widget.repo.addStudyTask(title);
      _taskController.clear();
    } catch (e) {
      setState(() => _error = 'काम सेव नहीं हुआ (\${e.runtimeType})। दोबारा कोशिश करें।');
    }
    if (mounted) setState(() => _adding = false);
  }

  Future<void> _setTarget(int minutes) async {
    try {
      await widget.repo.setStudyTarget(minutes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('लक्ष्य सेव नहीं हुआ (\${e.runtimeType})')),
        );
      }
    }
  }

  Future<void> _toggleTask(String id, bool done) async {
    try {
      await widget.repo.toggleStudyTask(id, done);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('स्थिति सेव नहीं हुई (\${e.runtimeType})')),
        );
      }
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      await widget.repo.deleteStudyTask(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('काम हटाया नहीं जा सका (\${e.runtimeType})')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('मेरा स्टडी प्लान')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: widget.repo.studyPlan(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('स्टडी प्लान लोड नहीं हुआ। दोबारा कोशिश करें।'));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final plan = snap.data!;
          final rawTasks = plan['tasks'];
          final tasks = rawTasks is List
              ? rawTasks.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
              : <Map<String, dynamic>>[];
          final target = plan['dailyMinutes'] is int ? plan['dailyMinutes'] as int : 120;
          final done = tasks.where((t) => t['done'] == true).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('आपका रोज़ का पढ़ाई लक्ष्य',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: [30, 60, 90, 120, 180, 240].contains(target) ? target : 120,
                        decoration: const InputDecoration(labelText: 'रोज़ कितने मिनट पढ़ेंगे?'),
                        items: const [
                          DropdownMenuItem(value: 30, child: Text('30 मिनट')),
                          DropdownMenuItem(value: 60, child: Text('1 घंटा')),
                          DropdownMenuItem(value: 90, child: Text('1 घंटा 30 मिनट')),
                          DropdownMenuItem(value: 120, child: Text('2 घंटे')),
                          DropdownMenuItem(value: 180, child: Text('3 घंटे')),
                          DropdownMenuItem(value: 240, child: Text('4 घंटे')),
                        ],
                        onChanged: (v) { if (v != null) _setTarget(v); },
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: target == 0 ? 0 : ((done * 30) / target).clamp(0.0, 1.0),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 6),
                      Text('\${done} काम पूरे · रोज़ का लक्ष्य \${target} मिनट'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('आज क्या पढ़ना है?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _taskController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _adding ? null : _addTask(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'जैसे: गणित का एक अध्याय पढ़ना',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _adding ? null : _addTask,
                icon: const Icon(Icons.add),
                label: Text(_adding ? 'सेव हो रहा है...' : 'पढ़ाई का काम जोड़ें'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              if (tasks.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'अभी कोई काम नहीं जोड़ा गया है। ऊपर अपना पहला पढ़ाई का काम लिखें। आपका प्लान आपके खाते में सेव होगा।',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                for (final task in tasks)
                  Card(
                    child: CheckboxListTile(
                      value: task['done'] == true,
                      activeColor: kTeal,
                      title: Text(
                        (task['title'] ?? 'पढ़ाई का काम').toString(),
                        style: TextStyle(
                          decoration: task['done'] == true
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(task['done'] == true ? 'पूरा हो गया' : 'अभी बाकी है'),
                      onChanged: (v) => _toggleTask((task['id'] ?? '').toString(), v == true),
                      secondary: IconButton(
                        tooltip: 'काम हटाएँ',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteTask((task['id'] ?? '').toString()),
                      ),
                    ),
                  ),
              const SizedBox(height: 12),
              const Text(
                'यह शुरुआती स्टडी प्लान है। आगे इसमें सिलेबस, परीक्षा की तारीख, कमजोर विषय और रिविज़न के आधार पर अपने-आप दैनिक योजना बनाने की सुविधा जोड़ी जाएगी।',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          );
        },
      ),
    );
  }
}
