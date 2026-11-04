import 'package:flutter/widgets.dart';

/// Voice capture and speech output must stop when the app leaves the foreground.
bool shouldStopVoiceForLifecycleState(AppLifecycleState state) =>
    state == AppLifecycleState.inactive ||
    state == AppLifecycleState.paused ||
    state == AppLifecycleState.detached;
