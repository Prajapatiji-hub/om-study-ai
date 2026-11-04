/// Pure helpers used to enforce first-time Study Setup.
bool isRequiredStudySetupPending(Map<String, dynamic> answers) =>
    answers['_setupRequired'] == true;

/// Returns the first visible question without a saved answer, or -1 when done.
/// Optional questions count as answered when the student explicitly skips them.
int firstUnansweredStudySetupQuestionIndex(
  List<String> visibleQuestionIds,
  Map<String, dynamic> answers,
) =>
    visibleQuestionIds.indexWhere((id) => !answers.containsKey(id));

/// A required setup is complete only when there is a non-empty visible
/// question list and every visible question has an explicit saved answer.
bool hasCompletedRequiredStudySetup(
  List<String> visibleQuestionIds,
  Map<String, dynamic> answers,
) =>
    visibleQuestionIds.isNotEmpty &&
    firstUnansweredStudySetupQuestionIndex(visibleQuestionIds, answers) == -1;
