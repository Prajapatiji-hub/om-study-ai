/// Validates a public Worker endpoint before any authenticated request is sent.
///
/// Worker URLs are routing configuration, not secrets: require HTTPS and reject
/// embedded credentials, query tokens, fragments and accidental whitespace.
bool isValidWorkerEndpointUrl(String value) {
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
