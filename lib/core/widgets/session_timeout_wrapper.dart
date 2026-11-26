import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/admin_console/providers/admin_provider.dart';

class SessionTimeoutWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const SessionTimeoutWrapper({super.key, required this.child});

  @override
  ConsumerState<SessionTimeoutWrapper> createState() =>
      _SessionTimeoutWrapperState();
}

class _SessionTimeoutWrapperState extends ConsumerState<SessionTimeoutWrapper> {
  Timer? _inactivityTimer;
  int _lastConfiguredMinutes = 15;

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetTimer(int timeoutMinutes, bool isAuthenticated) {
    _inactivityTimer?.cancel();
    if (!isAuthenticated) return;

    _inactivityTimer = Timer(Duration(minutes: timeoutMinutes), () {
      if (!mounted) return;
      ref.read(authProvider.notifier).logout(
        reason:
        'Session expired after $timeoutMinutes minutes of inactivity (University Security Policy).',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final policy = ref.watch(adminProvider).policy;

    if (policy.sessionTimeoutMinutes != _lastConfiguredMinutes ||
        (_inactivityTimer == null && authState.isAuthenticated)) {
      _lastConfiguredMinutes = policy.sessionTimeoutMinutes;
      _resetTimer(policy.sessionTimeoutMinutes, authState.isAuthenticated);
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) =>
          _resetTimer(policy.sessionTimeoutMinutes, authState.isAuthenticated),
      onPointerMove: (_) =>
          _resetTimer(policy.sessionTimeoutMinutes, authState.isAuthenticated),
      onPointerHover: (_) =>
          _resetTimer(policy.sessionTimeoutMinutes, authState.isAuthenticated),
      child: widget.child,
    );
  }
}