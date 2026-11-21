import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/optional_study_context_read.dart';

void main() {
  group('loadOptionalStudyContext', () {
    test('returns the loaded value', () async {
      final value = await loadOptionalStudyContext<String>(
        load: () async => 'student context',
        fallback: '',
      );

      expect(value, 'student context');
    });

    test('uses the fallback when an optional read fails', () async {
      final value = await loadOptionalStudyContext<Map<String, dynamic>>(
        load: () async => throw StateError('permission-denied'),
        fallback: <String, dynamic>{},
      );

      expect(value, isEmpty);
    });

    test('uses the fallback when an optional read exceeds its deadline', () async {
      final gate = Completer<String>();
      final value = await loadOptionalStudyContext<String>(
        load: () => gate.future,
        fallback: 'context unavailable',
        timeout: const Duration(milliseconds: 10),
      );

      expect(value, 'context unavailable');
      gate.complete('late result');
    });

    test('starts the source once and does not mutate its fallback', () async {
      var calls = 0;
      final fallback = <String, dynamic>{'source': 'fallback'};
      final value = await loadOptionalStudyContext<Map<String, dynamic>>(
        load: () async {
          calls++;
          return <String, dynamic>{'source': 'student'};
        },
        fallback: fallback,
      );

      expect(calls, 1);
      expect(value, {'source': 'student'});
      expect(fallback, {'source': 'fallback'});
    });
  });
}
