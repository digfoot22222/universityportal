import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls whether the UI renders in vibrant Full Prism or calmer Soft Pastel Aurora
enum PrismIntensity { fullPrism, softPastel }

final prismIntensityProvider =
StateProvider<PrismIntensity>((ref) => PrismIntensity.fullPrism);

class AppColors {
  // Multi-Stop Iridescent Rainbow Aurora Tokens
  static const Color electricMagenta = Color(0xFFFF3CAC);
  static const Color royalViolet = Color(0xFF784BA0);
  static const Color cyberBlue = Color(0xFF2B86C5);
  static const Color aquaMint = Color(0xFF00F5D4);
  static const Color solarGold = Color(0xFFFEE140);
  static const Color coralSunset = Color(0xFFFA709A);
  static const Color electricIndigo = Color(0xFF4F46E5);

  // High-Contrast Obsidian & Status Tokens
  static const Color deepObsidian = Color(0xFF0F172A);
  static const Color mutedSlate = Color(0xFF475569);
  static const Color emeraldPulse = Color(0xFF10B981);
  static const Color amberFlare = Color(0xFFF59E0B);
  static const Color crimsonAlert = Color(0xFFEF4444);

  static const List<Color> fullRainbowStops = [
    electricMagenta,
    royalViolet,
    cyberBlue,
    aquaMint,
    solarGold,
    coralSunset,
  ];

  static const List<Color> pastelAuroraStops = [
    Color(0xFFFFD6EC),
    Color(0xFFE5D9F2),
    Color(0xFFD6EEFF),
    Color(0xFFD4FCF4),
    Color(0xFFFFF8D6),
    Color(0xFFFFE0E9),
  ];

  static LinearGradient activeAuroraGradient(PrismIntensity intensity) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: intensity == PrismIntensity.fullPrism
          ? fullRainbowStops
          : pastelAuroraStops,
    );
  }

  static const LinearGradient rainbowBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      electricMagenta,
      cyberBlue,
      aquaMint,
      solarGold,
      coralSunset,
    ],
  );

  static const LinearGradient primaryCtaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [electricMagenta, royalViolet, electricIndigo],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.electricIndigo,
        primary: AppColors.electricIndigo,
        onSurface: AppColors.deepObsidian,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withValues(alpha: 0.78),
        foregroundColor: AppColors.deepObsidian,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.deepObsidian,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: AppColors.electricMagenta, width: 2),
        ),
      ),
    );
  }
}

/// Animated Flowing Aurora Mesh Background wrapping every screen
class RainbowAuroraScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const RainbowAuroraScaffold({super.key, required this.child});

  @override
  ConsumerState<RainbowAuroraScaffold> createState() =>
      _RainbowAuroraScaffoldState();
}

class _RainbowAuroraScaffoldState extends ConsumerState<RainbowAuroraScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(prismIntensityProvider);
    final colors = intensity == PrismIntensity.fullPrism
        ? AppColors.fullRainbowStops
        : AppColors.pastelAuroraStops;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (t * 0.8), -1.0),
              end: Alignment(1.0, 1.0 - (t * 0.8)),
              colors: colors,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// High-Contrast Frosted Glassmorphic Container with 1.5px Iridescent Border
class PrismGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const PrismGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: AppColors.rainbowBorderGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.royalViolet.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.6), // 1.6px Iridescent Prism Border
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1.6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(borderRadius - 1.6),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Animated Rainbow-to-Electric-Indigo Pill Button
class PrismGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  const PrismGradientButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryCtaGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.electricMagenta.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                      data: const IconThemeData(color: Colors.white, size: 18),
                      child: icon),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Distinct Visual Identity for Standard Free AI vs. Paid AI Pro (Gold Crown Orb)
class AiTierCrownBadge extends StatelessWidget {
  final bool isPro;
  final int freePromptsRemaining;
  final VoidCallback? onTapUpgrade;

  const AiTierCrownBadge({
    super.key,
    required this.isPro,
    this.freePromptsRemaining = 5,
    this.onTapUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    if (isPro) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD700), // Radiant Gold
              Color(0xFFFF8C00), // Solar Amber
              Color(0xFFFF3CAC), // Prism Magenta
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded,
                color: Color(0xFF0F172A), size: 18),
            SizedBox(width: 6),
            Text(
              'AI PRO UNLIMITED',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTapUpgrade,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cyberBlue.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.cyberBlue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_outlined,
                color: AppColors.cyberBlue, size: 16),
            const SizedBox(width: 6),
            Text(
              '$freePromptsRemaining / 5 Free AI Prompts Left',
              style: const TextStyle(
                color: AppColors.deepObsidian,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}