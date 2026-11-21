import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/voice_lifecycle.dart';
import 'package:om_study_ai/services/voice_preference_loader.dart';

void main() {
  group('loadVoicePreferenceData', () {
    test('starts profile and Study Setup reads concurrently', () async {
      final profileGate = Completer<Map<String, dynamic>>();
      final setupGate = Completer<Map<String, dynamic>>();
      var profileStarted = false;
      var setupStarted = false;

      final pending = loadVoicePreferenceData(
        loadProfile: () {
          profileStarted = true;
          return profileGate.future;
        },
        loadSetupAnswers: () {
          setupStarted = true;
          return setupGate.future;
        },
      );

      expect(profileStarted, isTrue);
      expect(setupStarted, isTrue);

      setupGate.complete({'language': 'en'});
      profileGate.complete({'language': 'hi'});
      final result = await pending;

      expect(result.profile['language'], 'hi');
      expect(result.setupAnswers['language'], 'en');
    });

    test('keeps Study Setup fallback when profile read fails', () async {
      final result = await loadVoicePreferenceData(
        loadProfile: () async => throw StateError('permission-denied'),
        loadSetupAnswers: () async => {'language': 'en'},
      );

      expect(
        resolveVoiceLocale(
          profile: result.profile,
          setupAnswers: result.setupAnswers,
        ),
        'en-US',
      );
    });

    test('keeps editable profile preference when Study Setup read fails', () async {
      final result = await loadVoicePreferenceData(
        loadProfile: () async => {'language': 'en'},
        loadSetupAnswers: () async => throw StateError('unavailable'),
      );

      expect(
        resolveVoiceLocale(
          profile: result.profile,
          setupAnswers: result.setupAnswers,
        ),
        'en-US',
      );
    });

    test('uses Hindi when both preference sources fail', () async {
      final result = await loadVoicePreferenceData(
        loadProfile: () async => throw StateError('profile unavailable'),
        loadSetupAnswers: () async => throw StateError('setup unavailable'),
      );

      expect(
        resolveVoiceLocale(
          profile: result.profile,
          setupAnswers: result.setupAnswers,
        ),
        'hi-IN',
      );
    });
  });
}
