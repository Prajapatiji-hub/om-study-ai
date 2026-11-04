/// Pure predicate used by the dashboard to enforce first-time Study Setup.
bool isRequiredStudySetupPending(Map<String, dynamic> answers) =>
    answers['_setupRequired'] == true;
