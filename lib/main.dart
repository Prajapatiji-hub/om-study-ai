import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_gate.dart';
import 'theme.dart';

// These values are passed at build time (see README_HINDI.md). They are NOT AI keys.
const _apiKey = String.fromEnvironment('FB_API_KEY');
const _appId = String.fromEnvironment('FB_APP_ID');
const _projectId = String.fromEnvironment('FB_PROJECT_ID');
const _senderId = String.fromEnvironment('FB_SENDER_ID');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configured = _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _projectId.isNotEmpty &&
      _senderId.isNotEmpty;
  if (configured) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        projectId: _projectId,
        messagingSenderId: _senderId,
      ),
    );
  }
  runApp(OmStudyApp(configured: configured));
}

class OmStudyApp extends StatelessWidget {
  final bool configured;
  const OmStudyApp({super.key, required this.configured});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OM STUDY AI',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: configured ? const AuthGate() : const _MissingConfig(),
    );
  }
}

class _MissingConfig extends StatelessWidget {
  const _MissingConfig();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings_suggest, size: 64, color: kTeal),
              SizedBox(height: 16),
              Text('Firebase सेटअप बाकी है',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text(
                'यह APK बिना Firebase की जानकारी के बना है। GitHub में '
                'FB_API_KEY, FB_APP_ID, FB_PROJECT_ID और FB_SENDER_ID '
                'secrets जोड़ें और APK दोबारा बनाएँ। (README_HINDI.md देखें)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
