/// Loads the two independent sources used to select voice recognition/TTS
/// language. Each read fails independently so legacy accounts can still use
/// whichever source is available.
class VoicePreferenceData {
  const VoicePreferenceData({
    required this.profile,
    required this.setupAnswers,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> setupAnswers;
}

Future<VoicePreferenceData> loadVoicePreferenceData({
  required Future<Map<String, dynamic>> Function() loadProfile,
  required Future<Map<String, dynamic>> Function() loadSetupAnswers,
}) async {
  Future<Map<String, dynamic>> safeLoad(
    Future<Map<String, dynamic>> Function() loader,
  ) async {
    try {
      return await loader();
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  // Calling both safe loaders before awaiting either one starts both reads
  // concurrently while preserving per-source fallback behavior.
  final results = await Future.wait<Map<String, dynamic>>([
    safeLoad(loadProfile),
    safeLoad(loadSetupAnswers),
  ]);

  return VoicePreferenceData(
    profile: results[0],
    setupAnswers: results[1],
  );
}
