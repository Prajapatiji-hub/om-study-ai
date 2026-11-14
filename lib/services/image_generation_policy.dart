import 'dart:convert';
import 'dart:typed_data';

/// Accepts only a complete HTTPS endpoint without embedded credentials or query data.
/// The Worker URL is public routing configuration, never an authentication secret.
bool isValidImageWorkerUrl(String value) {
  if (value.isEmpty || value != value.trim()) return false;
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.isAbsolute &&
      uri.scheme.toLowerCase() == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment;
}

/// Validates a short prompt before it is sent to the authenticated image endpoint.
String validateImagePrompt(String value) {
  final prompt = value.trim();
  if (prompt.isEmpty || prompt.length > 500) {
    throw ArgumentError('चित्र का विवरण 1 से 500 अक्षरों के बीच रखें।');
  }
  return prompt;
}

/// Decodes only a bounded, complete JPEG payload returned by the authenticated Worker.
/// Reject unexpected MIME types, malformed base64, non-JPEG headers and missing
/// JPEG end markers before the image is passed to Flutter's renderer.
Uint8List decodeGeneratedImagePayload(Map<String, dynamic> payload) {
  if (payload['mimeType'] != 'image/jpeg') {
    throw const FormatException('Unsupported image MIME type.');
  }

  final encoded = payload['image'];
  if (encoded is! String ||
      encoded.isEmpty ||
      encoded.length > 8000000 ||
      !RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(encoded)) {
    throw const FormatException('Invalid image encoding.');
  }

  final bytes = base64Decode(encoded);
  if (bytes.length < 4 ||
      bytes.length > 6000000 ||
      bytes[0] != 0xFF ||
      bytes[1] != 0xD8 ||
      bytes[2] != 0xFF ||
      bytes[bytes.length - 2] != 0xFF ||
      bytes[bytes.length - 1] != 0xD9) {
    throw const FormatException('Invalid JPEG image payload.');
  }

  return Uint8List.fromList(bytes);
}
