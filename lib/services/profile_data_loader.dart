/// Loads the profile and editable AI Study Memory independently.
///
/// A Memory Rules/read failure must not prevent the profile and Study Setup
/// editor from loading. A null map means that specific read failed.
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

  try {
    profile = await loadProfile();
  } catch (error) {
    profileError = error;
  }

  try {
    memory = await loadMemory();
  } catch (error) {
    memoryError = error;
  }

  return ProfileDataLoadResult(
    profile: profile,
    memory: memory,
    profileError: profileError,
    memoryError: memoryError,
  );
}
