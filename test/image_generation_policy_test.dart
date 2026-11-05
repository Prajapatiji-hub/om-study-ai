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
}
