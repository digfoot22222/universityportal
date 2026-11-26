import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/responsive_scaffold.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/fresher_admissions/presentation/fresher_portal_shell.dart';
import 'features/fresher_admissions/providers/fresher_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: UniversityPortalApp()));
}

class UniversityPortalApp extends ConsumerWidget {
  const UniversityPortalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final fresherState = ref.watch(fresherProvider);
    final intensity = ref.watch(prismIntensityProvider);

    Widget activeHome;
    if (fresherState.currentApplicant != null) {
      activeHome = const FresherPortalShell();
    } else if (authState.currentUser != null) {
      activeHome = const ResponsivePortalShell();
    } else {
      activeHome = const AuthScreen();
    }

    final isFullPrism = intensity == PrismIntensity.fullPrism;

    return MaterialApp(
      title: 'UniCore SaaS Campus OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isFullPrism
                ? const [
              Color(0xFF4F46E5),
              Color(0xFF9333EA),
              Color(0xFFEC4899),
              Color(0xFF06B6D4),
            ]
                : const [
              Color(0xFFEEF2FF),
              Color(0xFFFDF2F8),
              Color(0xFFECFEFF),
            ],
          ),
        ),
        child: activeHome,
      ),
    );
  }
}