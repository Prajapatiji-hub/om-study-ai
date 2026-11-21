/// Reads optional, owner-scoped study context without letting one stalled
/// Firestore request block an AI Teacher or adaptive-quiz request indefinitely.
///
/// Missing, denied, offline, and timed-out sources use the supplied fallback.
/// This helper is only for optional personalization context; it must not be
/// used for required writes or authorization decisions.
Future<T> loadOptionalStudyContext<T>({
  required Future<T> Function() load,
  required T fallback,
  Duration timeout = const Duration(seconds: 8),
}) async {
  try {
    return await load().timeout(timeout);
  } catch (_) {
    return fallback;
  }
}
