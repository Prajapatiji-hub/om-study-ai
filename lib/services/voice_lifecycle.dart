import 'package:flutter/widgets.dart';

import 'adaptive_study_context.dart';

/// Resolve voice output from the student's editable profile language first,
/// then fall back to the original Study Setup answer for older accounts.
String resolveVoiceLocale({
  required Map<String, dynamic> profile,
  required Map<String, dynamic> setupAnswers,
}) {
  final language = resolveStudyLanguage(
    profile: profile,
    setupAnswers: setupAnswers,
  );
  // Hinglish uses Hindi speech recognition/TTS as the closest supported locale.
  return language == 'en' ? 'en-US' : 'hi-IN';
}

/// Voice capture and speech output must stop when the app leaves the foreground.
bool shouldStopVoiceForLifecycleState(AppLifecycleState state) =>
    state == AppLifecycleState.inactive ||
    state == AppLifecycleState.hidden ||
    state == AppLifecycleState.paused ||
    state == AppLifecycleState.detached;

/// Voice may only start while the app is fully resumed in the foreground.
bool canStartVoiceForLifecycleState(AppLifecycleState state) =>
    state == AppLifecycleState.resumed;
