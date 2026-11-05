/// Validates a short prompt before it is sent to the authenticated image endpoint.
String validateImagePrompt(String value) {
  final prompt = value.trim();
  if (prompt.isEmpty || prompt.length > 500) {
    throw ArgumentError('चित्र का विवरण 1 से 500 अक्षरों के बीच रखें।');
  }
  return prompt;
}
