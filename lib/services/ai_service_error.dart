/// Maps AI Worker failures to safe, actionable messages for the student.
String aiServiceErrorMessage({
  required int statusCode,
  String? errorCode,
  String? serverMessage,
  bool quiz = false,
}) {
  if (statusCode == 401) {
    return 'लॉगिन की पुष्टि नहीं हुई। दोबारा लॉगिन करें।';
  }
  if (statusCode == 429) {
    return errorCode == 'rate_limited'
        ? 'आपने थोड़े समय में बहुत अनुरोध किए हैं। एक मिनट बाद फिर कोशिश करें।'
        : 'AI की उपयोग सीमा अभी पूरी हुई है। बाद में कोशिश करें।';
  }
  if (statusCode == 503 && errorCode == 'rate_limit_unavailable') {
    return 'AI सेवा की सुरक्षा जाँच अभी उपलब्ध नहीं है। थोड़ी देर बाद फिर कोशिश करें।';
  }
  if (serverMessage != null && serverMessage.trim().isNotEmpty) {
    return serverMessage.trim();
  }
  return quiz
      ? 'AI प्रश्न अभी नहीं बना पाया। थोड़ी देर बाद फिर कोशिश करें।'
      : 'AI सेवा अभी उपलब्ध नहीं है। बाद में कोशिश करें।';
}
