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
