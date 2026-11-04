/// Shared, pure validation for the editable per-student AI Study Memory.
Map<String, Object> sanitizeStudyMemory({
  required String summary,
  required List<String> strengths,
  required List<String> weakTopics,
  required String preferredStyle,
}) {
  String cleanText(String value, int maxLength, String field) {
    final clean = value.trim();
    if (clean.length > maxLength) {
      throw ArgumentError('$field अधिकतम $maxLength अक्षर का हो सकता है।');
    }
    return clean;
  }

  List<String> cleanItems(List<String> values, String field) {
    final items = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (items.length > 12 || items.any((value) => value.length > 60)) {
      throw ArgumentError('$field में अधिकतम 12 विषय (हर एक 60 अक्षर तक) रखें।');
    }
    return items;
  }

  return {
    'summary': cleanText(summary, 2000, 'पढ़ाई का सार'),
    'strengths': cleanItems(strengths, 'मजबूत विषय'),
    'weakTopics': cleanItems(weakTopics, 'कमजोर विषय'),
    'preferredStyle': cleanText(preferredStyle, 300, 'समझाने का तरीका'),
  };
}
