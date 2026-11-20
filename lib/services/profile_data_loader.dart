/// Loads the profile and editable AI Study Memory independently.
///
/// A Memory Rules/read failure must not prevent the profile and Study Setup
/// editor from loading. A null map means that specific read failed. Both
/// owner-scoped reads start together so a slow optional Memory read does not
/// unnecessarily delay the profile editor (or vice versa).
class ProfileDataLoadResult {
  const ProfileDataLoadResult({
    this.profile,
    this.memory,
    this.profileError,
    this.memoryError,
  });

  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? memory;
  final Object? profileError;
  final Object? memoryError;
}

Future<ProfileDataLoadResult> loadProfileAndMemory({
  required Future<Map<String, dynamic>> Function() loadProfile,
  required Future<Map<String, dynamic>> Function() loadMemory,
}) async {
  Map<String, dynamic>? profile;
  Map<String, dynamic>? memory;
  Object? profileError;
  Object? memoryError;

  Future<void> captureProfile() async {
    try {
      profile = await loadProfile();
    } catch (error) {
      profileError = error;
    }
  }

  Future<void> captureMemory() async {
    try {
      memory = await loadMemory();
    } catch (error) {
      memoryError = error;
    }
  }

  // Invoke both loaders before awaiting either result.
  await Future.wait([captureProfile(), captureMemory()]);

  return ProfileDataLoadResult(
    profile: profile,
    memory: memory,
    profileError: profileError,
    memoryError: memoryError,
  );
}
