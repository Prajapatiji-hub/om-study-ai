import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../services/user_repo.dart';
import '../theme.dart';

class NotesScreen extends StatefulWidget {
  final UserRepo repo;
  const NotesScreen({super.key, required this.repo});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _saving = false;

  Future<void> _openEditor({String? noteId, String title = '', String body = ''}) async {
    final titleController = TextEditingController(text: title);
    final bodyController = TextEditingController(text: body);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(noteId == null ? 'नया नोट' : 'नोट बदलें'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'नोट का शीर्षक',
                      hintText: 'जैसे: विद्युत के नियम',
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'शीर्षक लिखें।';
                      if (value.length > 100) return 'शीर्षक 100 अक्षरों से छोटा रखें।';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bodyController,
                    minLines: 8,
                    maxLines: 14,
                    maxLength: 20000,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'आपके नोट्स',
                      alignLabelWithHint: true,
                      hintText: 'यहाँ अपना नोट लिखें...',
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'नोट की सामग्री लिखें।';
                      if (value.length > 20000) return 'नोट बहुत लंबा है।';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('रद्द करें'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('सेव करें'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      setState(() => _saving = true);
      try {
        if (noteId == null) {
          await widget.repo.addNote(
            title: titleController.text,
            body: bodyController.text,
          );
        } else {
          await widget.repo.updateNote(
            noteId: noteId,
            title: titleController.text,
            body: bodyController.text,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(noteId == null ? 'नोट सेव हो गया।' : 'नोट अपडेट हो गया।')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('नोट सेव नहीं हुआ: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
    titleController.dispose();
    bodyController.dispose();
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('नोट हटाएँ?'),
        content: const Text('यह नोट आपके खाते से हट जाएगा। यह काम वापस नहीं होगा।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('रहने दें'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('हटा दें'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repo.deleteNote(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('नोट हटा दिया गया।')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('नोट नहीं हट सका: ${e.toString()}')),
        );
      }
    }
  }

  String _dateLabel(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate().toLocal();
      final d = date.day.toString().padLeft(2, '0');
      final m = date.month.toString().padLeft(2, '0');
      return '$d/$m/${date.year}';
    }
    return 'अभी-अभी';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('मेरे नोट्स')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _openEditor(),
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('नया नोट'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.repo.notes(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'नोट्स लोड नहीं हुए। इंटरनेट और Firebase Rules जाँचें, फिर दोबारा कोशिश करें।',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.note_alt_outlined, size: 64, color: kTeal),
                    SizedBox(height: 12),
                    Text('अभी कोई नोट नहीं है',
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      'नीचे “नया नोट” दबाकर अपने विषय के नोट्स लिखें। नोट आपके खाते में सुरक्षित रहेंगे।',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = (data['title'] ?? 'बिना शीर्षक').toString();
              final body = (data['body'] ?? '').toString();
              return Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.sticky_note_2_outlined, color: kTeal),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('बदला गया: ${_dateLabel(data['updatedAt'])}'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(body),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _openEditor(noteId: doc.id, title: title, body: body),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('बदलें'),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _delete(doc.id),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('हटाएँ'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
