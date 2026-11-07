import 'package:flutter/widgets.dart';

/// Voice capture and speech output must stop when the app leaves the foreground.
bool shouldStopVoiceForLifecycleState(AppLifecycleState state) =>
    state == AppLifecycleState.inactive ||
    state == AppLifecycleState.hidden ||
    state == AppLifecycleState.paused ||
    state == AppLifecycleState.detached;

/// Voice may only start while the app is fully resumed in the foreground.
bool canStartVoiceForLifecycleState(AppLifecycleState state) =>
    state == AppLifecycleState.resumed;
