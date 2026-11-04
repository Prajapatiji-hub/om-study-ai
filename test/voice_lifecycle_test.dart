import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:om_study_ai/services/voice_lifecycle.dart';

void main() {
  group('shouldStopVoiceForLifecycleState', () {
    test('stops capture and playback when app is inactive, paused or detached', () {
      expect(shouldStopVoiceForLifecycleState(AppLifecycleState.inactive), isTrue);
      expect(shouldStopVoiceForLifecycleState(AppLifecycleState.paused), isTrue);
      expect(shouldStopVoiceForLifecycleState(AppLifecycleState.detached), isTrue);
    });

    test('stops voice when app is hidden', () {
      expect(shouldStopVoiceForLifecycleState(AppLifecycleState.hidden), isTrue);
    });

    test('does not stop voice when app is resumed', () {
      expect(shouldStopVoiceForLifecycleState(AppLifecycleState.resumed), isFalse);
    });
  group('canStartVoiceForLifecycleState', () {
    test('allows voice only while app is resumed', () {
      expect(canStartVoiceForLifecycleState(AppLifecycleState.resumed), isTrue);
      expect(canStartVoiceForLifecycleState(AppLifecycleState.inactive), isFalse);
      expect(canStartVoiceForLifecycleState(AppLifecycleState.hidden), isFalse);
      expect(canStartVoiceForLifecycleState(AppLifecycleState.paused), isFalse);
      expect(canStartVoiceForLifecycleState(AppLifecycleState.detached), isFalse);
    });
  });

  });
}
