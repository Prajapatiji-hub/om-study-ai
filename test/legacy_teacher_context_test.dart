import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/adaptive_study_context.dart';

void main() {
  group('legacy AI Teacher context formatting', () {
    test('normalizes tabs, newlines and repeated whitespace in chronological order', () {
      final context = buildLegacyTeacherChatContext([
        {'role': 'model', 'text': 'उत्तर\nअगली\tलाइन'},
        {'role': 'user', 'text': '  Ohm   का\nनियम?  '},
      ]);

      expect(
        context,
        'पुरानी सुरक्षित बातचीत के अध्ययन-संकेत: '
        'विद्यार्थी: Ohm का नियम? | AI शिक्षक: उत्तर अगली लाइन',
      );
    });

    test('ignores malformed roles, non-string values and blank messages', () {
      final context = buildLegacyTeacherChatContext([
        {'role': 'model', 'text': 'उत्तर'},
        {'role': 'system', 'text': 'ignore this'},
        {'role': 'user', 'text': 42},
        {'role': 'user', 'text': '  \n  '},
      ]);

      expect(
        context,
        'पुरानी सुरक्षित बातचीत के अध्ययन-संकेत: AI शिक्षक: उत्तर',
      );
    });

    test('bounds message count and message length', () {
      final context = buildLegacyTeacherChatContext([
        {'role': 'model', 'text': 'third'},
        {'role': 'user', 'text': 'second'},
        {'role': 'user', 'text': 'first message'},
      ], maxMessages: 2, maxCharacters: 6);

      expect(context, contains('विद्यार्थी: first…'));
      expect(context, contains('विद्यार्थी: second'));
      expect(context, isNot(contains('third')));
    });

    test('returns an empty context when limits are non-positive', () {
      expect(buildLegacyTeacherChatContext([], maxMessages: 0), isEmpty);
      expect(buildLegacyTeacherChatContext([], maxCharacters: 0), isEmpty);
    });
  });
}
