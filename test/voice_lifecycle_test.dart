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

    test('does not stop voice merely because app is resumed or hidden', () {
      expect(shouldStopVoiceForLifecycleState(AppLifecycleState.resumed), isFalse);
      expect(shouldStopVoiceForLifecycleState(AppLifecycleState.hidden), isFalse);
    });
  });
}
