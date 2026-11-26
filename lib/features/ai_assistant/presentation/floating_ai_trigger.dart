import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FloatingAiTrigger extends StatelessWidget {
  final VoidCallback onPressed;
  const FloatingAiTrigger({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryCtaGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricMagenta.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        onPressed: onPressed,
        icon: const Icon(Icons.auto_awesome),
        label: const Text(
          'AI Forensics',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}