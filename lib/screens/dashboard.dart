import 'package:flutter/material.dart';

import '../services/user_repo.dart';
import '../theme.dart';
import 'coming_soon.dart';
import 'onboarding.dart';
import 'profile.dart';
import 'syllabus.dart';
import 'study_plan.dart';

class Module {
  final String title;
  final IconData icon;
  final String? goal; // shown only if the student chose this goal
  final bool ready;
  const Module(this.title, this.icon, {this.goal, this.ready = false});
}

const kModules = [
  Module('स्कूल की पढ़ाई', Icons.school, goal: 'school'),
  Module('सरकारी परीक्षा', Icons.account_balance, goal: 'govt'),
  Module('ITI और हुनर', Icons.electrical_services, goal: 'iti'),
  Module('AI टीचर', Icons.smart_toy),
  Module('मेरा स्टडी प्लान', Icons.event_note, ready: true),
  Module('मेरा सिलेबस', Icons.menu_book, ready: true),
  Module('मेरे नोट्स', Icons.edit_note),
  Module('मेरे वीडियो', Icons.ondemand_video),
  Module('प्रैक्टिस टेस्ट', Icons.quiz),
  Module('मेरी प्रगति', Icons.show_chart),
  Module('मेरी AI मेमोरी', Icons.psychology),
  Module('पढ़ाई के रिमाइंडर', Icons.alarm),
  Module('मेरी प्रोफ़ाइल', Icons.person, ready: true),
  Module('सेटिंग्स', Icons.settings, ready: true),
];

class DashboardScreen extends StatefulWidget {
  final UserRepo repo;
  const DashboardScreen({super.key, required this.repo});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<void> _init = widget.repo.ensureProfile();

  void _open(Module m) {
    final page = m.title == 'मेरा सिलेबस'
        ? SyllabusScreen(repo: widget.repo)
        : (m.title == 'मेरा स्टडी प्लान'
            ? StudyPlanScreen(repo: widget.repo)
            : (m.ready
                ? ProfileScreen(repo: widget.repo)
                : ComingSoonScreen(title: m.title)));
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, initSnap) {
        if (initSnap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (initSnap.hasError) {
          return const Scaffold(
              body: Center(
                  child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('प्रोफ़ाइल लोड नहीं हुई। इंटरनेट जाँचकर ऐप दोबारा खोलें।',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          )));
        }
        return StreamBuilder<Map<String, dynamic>>(
          stream: widget.repo.profile(),
          builder: (context, pSnap) {
            final profile = pSnap.data ?? {};
            final goals = (profile['selectedGoals'] is List)
                ? List<String>.from(profile['selectedGoals'])
                : <String>[];
            final name = (profile['displayName'] ?? 'विद्यार्थी').toString();
            final shown = kModules
                .where((m) => m.goal == null || goals.isEmpty || goals.contains(m.goal))
                .toList();
            return Scaffold(
              appBar: AppBar(title: const Text('OM STUDY AI')),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('नमस्ते, $name',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    StreamBuilder<Map<String, dynamic>>(
                      stream: widget.repo.answers(),
                      builder: (context, aSnap) {
                        if (!aSnap.hasData) return const SizedBox.shrink();
                        final p = onboardingProgress(aSnap.data!);
                        if (p.done >= p.total) return const SizedBox.shrink();
                        return Card(
                          color: const Color(0xFFFFF3DC),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            title: const Text('अपना सेटअप पूरा करें',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Text('${p.done} / ${p.total} सवाल हो चुके'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => OnboardingScreen(repo: widget.repo))),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        for (final m in shown)
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _open(m),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFD5E0DE)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(m.icon, size: 34, color: kTeal),
                                  const SizedBox(height: 8),
                                  Text(m.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  if (!m.ready)
                                    const Text('जल्द आएगा', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
