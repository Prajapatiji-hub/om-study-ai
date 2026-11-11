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

/// Convert speech plugin errors into actionable, non-technical guidance.
/// A permanent permission error requires the student to change Android settings;
/// transient errors should allow another in-app attempt.
String voiceRecognitionErrorMessage({
  required String error,
  required bool permanent,
}) {
  final normalized = error.trim().toLowerCase().replaceAll('-', '_');
  final permissionError = normalized.contains('permission') ||
      normalized.contains('not_allowed') ||
      normalized.contains('notallowed');

  if (permissionError && permanent) {
    return 'माइक्रोफ़ोन अनुमति स्थायी रूप से बंद है। Android Settings > Apps > OM STUDY AI > Permissions > Microphone में अनुमति दें, फिर ऐप में वापस आकर दोबारा कोशिश करें।';
  }
  if (permissionError) {
    return 'बोलकर सवाल पूछने के लिए माइक्रोफ़ोन की अनुमति दें। अनुमति पूछे जाने पर Allow चुनें।';
  }

  final unavailable = normalized.contains('not_available') ||
      normalized.contains('not available') ||
      normalized.contains('recognition_service') ||
      normalized.contains('service_not_available');
  if (unavailable) {
    return 'इस फोन में Speech Recognition सेवा उपलब्ध नहीं है। फोन की speech/Google voice service सक्षम करके फिर कोशिश करें।';
  }
  if (permanent) {
    return 'Speech Recognition सेवा रुक गई है। फोन की Microphone अनुमति और Speech/Google voice service जाँचें; फिर ऐप दोबारा खोलें।';
  }
  return 'आवाज़ पहचानने में समस्या हुई। इंटरनेट और माइक्रोफ़ोन जाँचकर फिर कोशिश करें।';
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
