import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/academics_courses/presentation/course_registration_screen.dart';
import '../../features/admin_console/presentation/admin_dashboard_screen.dart';
import '../../features/ai_assistant/presentation/ai_command_center_screen.dart';
import '../../features/ai_assistant/providers/ai_assistant_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/presentation/student_live_dashboard_screen.dart';
import '../../features/guidance_counseling/presentation/guidance_counseling_screen.dart';
import '../../features/hostel_virtual/presentation/virtual_explorer_screen.dart';
import '../../features/payments_remita/presentation/remita_billing_screen.dart';
import '../../features/public_verifier/public_verifier_screen.dart';
import '../models/student_model.dart';
import '../network/online_guard_banner.dart';
import '../theme/app_theme.dart';

class ResponsivePortalShell extends ConsumerStatefulWidget {
  const ResponsivePortalShell({super.key});

  @override
  ConsumerState<ResponsivePortalShell> createState() =>
      _ResponsivePortalShellState();
}

class _ResponsivePortalShellState extends ConsumerState<ResponsivePortalShell> {
  int _selectedIndex = 0;
  final _picker = ImagePicker();

  Future<void> _updateDashboardAvatar() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      ref.read(authProvider.notifier).updateProfilePhoto(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final intensity = ref.watch(prismIntensityProvider);
    final aiState = ref.watch(aiAssistantProvider);

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(
          (user?.isAiProSubscriber ?? false)
              ? Icons.workspace_premium_rounded
              : Icons.auto_awesome_outlined,
        ),
        label: 'AI Copilot',
      ),
      const NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        label: 'Courses',
      ),
      const NavigationDestination(
        icon: Icon(Icons.favorite_outline),
        label: 'Counseling',
      ),
      const NavigationDestination(
        icon: Icon(Icons.apartment_outlined),
        label: 'Hostels',
      ),
      const NavigationDestination(
        icon: Icon(Icons.payments_outlined),
        label: 'Remita',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          label: 'Admin',
        ),
    ];

    final screens = <Widget>[
      StudentLiveDashboardScreen(
        onSwitchTab: (idx) => setState(() => _selectedIndex = idx),
      ),
      const AiCommandCenterScreen(),
      const CourseRegistrationScreen(),
      const GuidanceCounselingScreen(),
      VirtualExplorerScreen(
        isAdmin: isAdmin,
        onNavigateToPayments: () => setState(() => _selectedIndex = 5),
      ),
      const RemitaBillingScreen(),
      if (isAdmin) const AdminDashboardScreen(),
    ];

    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.88),
            title: Row(
              children: [
                GestureDetector(
                  onTap: _updateDashboardAvatar,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: (user?.isAiProSubscriber ?? false)
                        ? const Color(0xFFFFD700)
                        : AppColors.electricIndigo,
                    backgroundImage: user?.profilePhotoBytes != null
                        ? MemoryImage(user!.profilePhotoBytes!)
                        : null,
                    child: user?.profilePhotoBytes == null
                        ? Text(
                      (user?.fullName ?? 'U')[0],
                      style: TextStyle(
                        color: (user?.isAiProSubscriber ?? false)
                            ? AppColors.deepObsidian
                            : Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Student Portal',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${user?.matricNumber ?? ""} • ${user?.level ?? ""} • ${user?.department ?? ""}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.mutedSlate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (user != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AiTierCrownBadge(
                    isPro: user.isAiProSubscriber,
                    freePromptsRemaining: aiState.remainingFreePrompts(user),
                    onTapUpgrade: () {
                      setState(() => _selectedIndex = 1);
                      ref
                          .read(aiAssistantProvider.notifier)
                          .sendPrompt('Upgrade my account to AI Pro');
                    },
                  ),
                ),
              IconButton(
                tooltip: 'Public QR Credential Verifier',
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PublicCredentialVerifierScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Toggle Prism Intensity',
                icon: Icon(
                  intensity == PrismIntensity.fullPrism
                      ? Icons.wb_sunny_outlined
                      : Icons.palette_outlined,
                ),
                onPressed: () {
                  ref.read(prismIntensityProvider.notifier).state =
                  intensity == PrismIntensity.fullPrism
                      ? PrismIntensity.softPastel
                      : PrismIntensity.fullPrism;
                },
              ),
              IconButton(
                tooltip: 'Sign Out',
                icon: const Icon(Icons.logout, color: AppColors.crimsonAlert),
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              const OnlineConnectivityBanner(),
              Expanded(
                child: Row(
                  children: [
                    if (isDesktop)
                      NavigationRail(
                        backgroundColor: Colors.white.withValues(alpha: 0.88),
                        selectedIndex: _selectedIndex,
                        labelType: NavigationRailLabelType.all,
                        onDestinationSelected: (idx) =>
                            setState(() => _selectedIndex = idx),
                        destinations: destinations
                            .map(
                              (d) => NavigationRailDestination(
                            icon: d.icon,
                            label: Text(d.label),
                          ),
                        )
                            .toList(),
                      ),
                    Expanded(child: screens[_selectedIndex]),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) =>
                setState(() => _selectedIndex = idx),
            destinations: destinations,
          ),
        );
      },
    );
  }
}