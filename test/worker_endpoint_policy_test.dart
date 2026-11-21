import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/worker_endpoint_policy.dart';

void main() {
  group('isValidWorkerEndpointUrl', () {
    test('accepts HTTPS Workers and custom endpoint paths', () {
      expect(isValidWorkerEndpointUrl('https://om-study-ai.example.workers.dev'), isTrue);
      expect(isValidWorkerEndpointUrl('https://ai.example.com/v1/worker'), isTrue);
      expect(isValidWorkerEndpointUrl('HTTPS://ai.example.com/worker'), isTrue);
    });

    test('rejects missing, malformed and non-HTTPS endpoints', () {
      for (final value in [
        '',
        '   ',
        'not a URL',
        'https://',
        'http://ai.example.com',
        'ftp://ai.example.com',
        'https://ai.example.com:invalid',
      ]) {
        expect(isValidWorkerEndpointUrl(value), isFalse, reason: value);
      }
    });

    test('rejects embedded credentials, query strings, fragments and whitespace', () {
      for (final value in [
        'https://user:pass@ai.example.com',
        'https://ai.example.com?token=secret',
        'https://ai.example.com/#fragment',
        ' https://ai.example.com',
        'https://ai.example.com ',
      ]) {
        expect(isValidWorkerEndpointUrl(value), isFalse, reason: value);
      }
    });
  });
}
