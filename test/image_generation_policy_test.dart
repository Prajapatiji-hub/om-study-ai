import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/image_generation_policy.dart';

void main() {
  group('validateImagePrompt', () {
    test('trims a valid educational prompt', () {
      expect(validateImagePrompt('  Ohm law circuit diagram  '), 'Ohm law circuit diagram');
    });

    test('rejects empty and overlong prompts', () {
      expect(() => validateImagePrompt('  '), throwsArgumentError);
      expect(() => validateImagePrompt('x' * 501), throwsArgumentError);
    });

    test('accepts the documented 500 character maximum', () {
      expect(validateImagePrompt('x' * 500).length, 500);
    });
  });
  group('decodeGeneratedImagePayload', () {
    final validJpeg = <int>[0xFF, 0xD8, 0xFF, 0xD9];

    test('accepts a bounded JPEG with the declared MIME type', () {
      final bytes = decodeGeneratedImagePayload({
        'mimeType': 'image/jpeg',
        'image': base64Encode(validJpeg),
      });
      expect(bytes.toList(), validJpeg);
    });

    test('rejects missing or unexpected MIME types', () {
      expect(
        () => decodeGeneratedImagePayload({'image': base64Encode(validJpeg)}),
        throwsFormatException,
      );
      expect(
        () => decodeGeneratedImagePayload({
          'mimeType': 'image/png',
          'image': base64Encode(validJpeg),
        }),
        throwsFormatException,
      );
    });

    test('rejects malformed, empty and oversized base64 strings', () {
      expect(
        () => decodeGeneratedImagePayload({'mimeType': 'image/jpeg', 'image': ''}),
        throwsFormatException,
      );
      expect(
        () => decodeGeneratedImagePayload({'mimeType': 'image/jpeg', 'image': '***'}),
        throwsFormatException,
      );
      expect(
        () => decodeGeneratedImagePayload({
          'mimeType': 'image/jpeg',
          'image': 'A' * 8000001,
        }),
        throwsFormatException,
      );
    });

    test('rejects decoded bytes without a JPEG signature', () {
      expect(
        () => decodeGeneratedImagePayload({
          'mimeType': 'image/jpeg',
          'image': base64Encode([0x89, 0x50, 0x4E, 0x47]),
        }),
        throwsFormatException,
      );
    });
  });
}
