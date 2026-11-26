import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'cloud_connection_service.dart';

class OnlineConnectivityBanner extends ConsumerWidget {
  const OnlineConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(cloudConnectionProvider);

    // Hide banner completely when connected so the workspace stays clean
    if (conn.isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.crimsonAlert,
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Live Cloud Connection Required — ${conn.statusLabel}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.deepObsidian,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: conn.isChecking
                ? null
                : () async {
              final ok = await ref
                  .read(cloudConnectionProvider.notifier)
                  .verifyConnectionNow();
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.emeraldPulse,
                    content: Text('Live Cloud Connection Restored!'),
                  ),
                );
              }
            },
            icon: conn.isChecking
                ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh, size: 16),
            label: Text(conn.isChecking ? 'Checking...' : 'Retry Now'),
          ),
        ],
      ),
    );
  }
}