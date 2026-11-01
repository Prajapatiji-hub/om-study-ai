import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/dashboard.dart';
import 'screens/welcome.dart';
import 'services/user_repo.dart';

/// Welcome when logged out, Dashboard when logged in.
/// The uid ALWAYS comes from FirebaseAuth, never from user input.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const WelcomeScreen();
        // ValueKey(uid) forces a fresh widget tree per account (no stale data).
        return DashboardScreen(key: ValueKey(user.uid), repo: UserRepo(user));
      },
    );
  }
}
