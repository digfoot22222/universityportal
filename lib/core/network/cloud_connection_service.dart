import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class CloudConnectionState {
  final bool isOnline;
  final bool isChecking;
  final String statusLabel;
  final DateTime lastVerifiedAt;

  const CloudConnectionState({
    required this.isOnline,
    this.isChecking = false,
    required this.statusLabel,
    required this.lastVerifiedAt,
  });

  CloudConnectionState copyWith({
    bool? isOnline,
    bool? isChecking,
    String? statusLabel,
    DateTime? lastVerifiedAt,
  }) {
    return CloudConnectionState(
      isOnline: isOnline ?? this.isOnline,
      isChecking: isChecking ?? this.isChecking,
      statusLabel: statusLabel ?? this.statusLabel,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
    );
  }
}

class CloudConnectionNotifier extends StateNotifier<CloudConnectionState> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _periodicProbe;

  CloudConnectionNotifier()
      : super(
    CloudConnectionState(
      // Default to true so Web/Desktop never get stuck in a false-offline boot lock
      isOnline: true,
      statusLabel: 'Live Cloud & NUC Gateway Connected',
      lastVerifiedAt: DateTime.now(),
    ),
  ) {
    _init();
  }

  void _init() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      // On Web/Desktop, connectivity_plus often emits [ConnectivityResult.none] falsely;
      // verify with an actual lightweight probe before marking offline.
      if (results.contains(ConnectivityResult.none) && !kIsWeb) {
        verifyConnectionNow();
      } else {
        state = state.copyWith(
          isOnline: true,
          isChecking: false,
          statusLabel: 'Live Cloud & NUC Gateway Connected',
          lastVerifiedAt: DateTime.now(),
        );
      }
    });

    verifyConnectionNow();
    _periodicProbe = Timer.periodic(
      const Duration(seconds: 25),
          (_) => verifyConnectionNow(),
    );
  }

  Future<bool> verifyConnectionNow() async {
    state = state.copyWith(isChecking: true);
    try {
      // Fast CORS-safe public reachability check
      final response = await http
          .head(Uri.parse('https://www.google.com/generate_204'))
          .timeout(const Duration(seconds: 4));

      final connected = response.statusCode >= 200 && response.statusCode < 500;
      state = state.copyWith(
        isOnline: connected,
        isChecking: false,
        statusLabel: connected
            ? 'Live Cloud & NUC Gateway Connected'
            : 'Offline — Reconnecting to Campus Cloud...',
        lastVerifiedAt: DateTime.now(),
      );
      return connected;
    } catch (_) {
      // On Flutter Web, browser CORS policies on external HEAD requests can throw even when online.
      // Treat Web browser runtime as online unless explicitly disconnected.
      if (kIsWeb) {
        state = state.copyWith(
          isOnline: true,
          isChecking: false,
          statusLabel: 'Live Web Cloud Active',
          lastVerifiedAt: DateTime.now(),
        );
        return true;
      }

      state = state.copyWith(
        isOnline: false,
        isChecking: false,
        statusLabel: 'Offline — Reconnecting to Campus Cloud...',
        lastVerifiedAt: DateTime.now(),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _periodicProbe?.cancel();
    super.dispose();
  }
}

final cloudConnectionProvider =
StateNotifierProvider<CloudConnectionNotifier, CloudConnectionState>((ref) {
  return CloudConnectionNotifier();
});