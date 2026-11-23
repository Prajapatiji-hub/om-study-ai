/// Pure helpers used to enforce first-time Study Setup.
bool isRequiredStudySetupPending(Map<String, dynamic> answers) =>
    answers['_setupRequired'] == true;

/// A missing profile alone does not prove that an account is new. Existing
/// setup answers must be preserved and must not be replaced by a new-user gate.
bool shouldCreateRequiredStudySetupMarker({
  required bool profileExists,
  required bool setupAnswersExist,
}) =>
    !profileExists && !setupAnswersExist;

/// Dashboard access is fail-closed until the Study Setup document has loaded.
/// Errors are distinct from loading so the UI can offer a retry instead of
/// briefly showing private app modules while access is unknown.
enum StudySetupAccessState { loading, error, setupRequired, allowed }

StudySetupAccessState resolveStudySetupAccess({
  required bool hasData,
  required bool hasError,
  Map<String, dynamic>? answers,
}) {
  if (hasError) return StudySetupAccessState.error;
  if (!hasData) return StudySetupAccessState.loading;
  return isRequiredStudySetupPending(answers ?? const {})
      ? StudySetupAccessState.setupRequired
      : StudySetupAccessState.allowed;
}
