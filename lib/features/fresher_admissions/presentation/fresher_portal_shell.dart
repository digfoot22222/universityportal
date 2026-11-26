import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/models/student_model.dart';
import '../../../core/network/online_guard_banner.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/fresher_provider.dart';

class FresherPortalShell extends ConsumerStatefulWidget {
  const FresherPortalShell({super.key});

  @override
  ConsumerState<FresherPortalShell> createState() => _FresherPortalShellState();
}

class _FresherPortalShellState extends ConsumerState<FresherPortalShell> {
  int _selectedNav = 0;
  int _wizardStep = 0;
  final _aiController = TextEditingController();
  final _picker = ImagePicker();

  static const List<String> twelveDepartments = [
    'Medicine & Surgery (MBBS)',
    'Pharmacy (Pharm.D)',
    'Nursing Science (B.NSc)',
    'Software Engineering',
    'Electrical & Electronics Engineering',
    'Mechanical Engineering',
    'Computer Science',
    'Cybersecurity & Digital Forensics',
    'Civil & Structural Engineering',
    'Accounting & Finance',
    'Business Administration & Entrepreneurship',
    'Mass Communication & Digital Media',
  ];

  @override
  void dispose() {
    _aiController.dispose();
    super.dispose();
  }

  Future<void> _uploadPassport(FresherApplicant app) async {
    final XFile? shot = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
    );
    if (shot != null) {
      final bytes = await shot.readAsBytes();
      ref
          .read(fresherProvider.notifier)
          .updateApplicantRecord(app.copyWith(portraitBytes: bytes));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fresherState = ref.watch(fresherProvider);
    final app = fresherState.currentApplicant;
    if (app == null) return const SizedBox.shrink();

    final uni = fresherState.universityByCode(app.universityCode);
    final isAdmitted = app.status == AdmissionDecisionStatus.admittedOffered;

    final navDestinations = const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        label: 'Application Form',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        label: 'Transactions',
      ),
      NavigationDestination(
        icon: Icon(Icons.print_outlined),
        label: 'Print Forms',
      ),
      NavigationDestination(
        icon: Icon(Icons.track_changes_outlined),
        label: 'App Tracker',
      ),
      NavigationDestination(
        icon: Icon(Icons.notifications_outlined),
        label: 'Notifications',
      ),
      NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        label: 'AI Copilot',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            title: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.amberFlare.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.amberFlare),
                  ),
                  child: const Text(
                    '2026/2027 SESSION',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${uni.name} • Undergraduate Admissions Portal',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            actions: [
              Chip(
                backgroundColor: isAdmitted
                    ? AppColors.emeraldPulse.withValues(alpha: 0.16)
                    : AppColors.amberFlare.withValues(alpha: 0.16),
                label: Text(
                  isAdmitted ? 'ADMITTED' : 'Admission: Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: isAdmitted
                        ? AppColors.emeraldPulse
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Logout Fresher Portal',
                icon: const Icon(Icons.logout, color: AppColors.crimsonAlert),
                onPressed: () =>
                    ref.read(fresherProvider.notifier).logoutFresher(),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.92),
                        selectedIndex: _selectedNav,
                        labelType: NavigationRailLabelType.all,
                        onDestinationSelected: (idx) =>
                            setState(() => _selectedNav = idx),
                        destinations: navDestinations
                            .map(
                              (d) => NavigationRailDestination(
                            icon: d.icon,
                            label: Text(d.label),
                          ),
                        )
                            .toList(),
                      ),
                    Expanded(
                      child: _buildSelectedView(app, uni, fresherState),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
            selectedIndex: _selectedNav,
            onDestinationSelected: (idx) =>
                setState(() => _selectedNav = idx),
            destinations: navDestinations.take(5).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSelectedView(
      FresherApplicant app,
      NigerianUniversitySpec uni,
      FresherState fresherState,
      ) {
    switch (_selectedNav) {
      case 0:
        return _buildMainFresherDashboard(app, uni, fresherState);
      case 1:
        return _build4StageApplicationWizard(app, uni, fresherState);
      case 2:
        return _buildTransactionsView(app, uni);
      case 3:
        return _buildPrintFormsView(app, uni);
      case 4:
        return _buildNucTrackerView(app, uni);
      case 5:
        return _buildNotificationsView(app);
      default:
        return _buildFullAiCopilotView(app, uni, fresherState);
    }
  }

  /// 1. AUTHENTIC NIGERIAN UNIVERSITY FRESHER DASHBOARD
  Widget _buildMainFresherDashboard(
      FresherApplicant app,
      NigerianUniversitySpec uni,
      FresherState fresherState,
      ) {
    final isAdmitted = app.status == AdmissionDecisionStatus.admittedOffered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Top 4-Card Application Progress Strip (Personal Info, Programme, Education, Guardian)
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _progressStripCard(
                title: 'PERSONAL INFO',
                isDone: app.personalInfoDone,
                icon: Icons.person_outline,
                onTap: () => setState(() {
                  _selectedNav = 1;
                  _wizardStep = 0;
                }),
              ),
              _progressStripCard(
                title: 'PROGRAMME OF STUDY',
                isDone: app.programmeDone,
                icon: Icons.school_outlined,
                onTap: () => setState(() {
                  _selectedNav = 1;
                  _wizardStep = 1;
                }),
              ),
              _progressStripCard(
                title: 'EDUCATION (JAMB & O\'LEVEL)',
                isDone: app.educationDone,
                icon: Icons.menu_book_outlined,
                onTap: () => setState(() {
                  _selectedNav = 1;
                  _wizardStep = 2;
                }),
              ),
              _progressStripCard(
                title: 'GUARDIAN INFO',
                isDone: app.guardianDone,
                icon: Icons.family_restroom_outlined,
                onTap: () => setState(() {
                  _selectedNav = 1;
                  _wizardStep = 3;
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // B. Center Split: Applicant Profile & Admission Status Card + Interactive Screening Calendar
          Wrap(
            spacing: 18,
            runSpacing: 18,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // Left: Applicant Profile & Live Admission Status Card
              SizedBox(
                width: 460,
                child: PrismGlassCard(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _uploadPassport(app),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: const Color(0xFFDC2626),
                              backgroundImage: app.portraitBytes != null
                                  ? MemoryImage(app.portraitBytes!)
                                  : null,
                              child: app.portraitBytes == null
                                  ? Text(
                                app.fullName[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                                  : null,
                            ),
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.electricIndigo,
                              child: Icon(Icons.camera_alt,
                                  size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        app.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        app.email,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.mutedSlate),
                      ),
                      const Divider(height: 22),
                      _kvRow('Phone Number', app.phoneNumber),
                      _kvRow('Application Type', app.applicationType),
                      _kvRow('Entry Type', app.entryType),
                      _kvRow('Application #', app.applicationNumber),
                      _kvRow('JAMB Reg #', app.jambRegNumber),
                      _kvRow('Institution', uni.name),
                      _kvRow('1st Choice Course', app.preferredDepartment),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Admission Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedSlate,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isAdmitted
                                  ? AppColors.emeraldPulse
                                  : AppColors.amberFlare,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAdmitted ? 'ADMITTED' : 'Pending',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isAdmitted) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: PrismGradientButton(
                            onPressed: () => setState(() => _selectedNav = 4),
                            icon: const Icon(Icons.celebration),
                            label: 'Accept Offer & Complete NUC Clearance',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Right: Interactive November 2026 Academic & Screening Calendar + Quick AI Strip
              SizedBox(
                width: 460,
                child: Column(
                  children: [
                    PrismGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'November 2026 — Admissions Calendar',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              Icon(Icons.calendar_month,
                                  color: AppColors.electricIndigo),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildNovember2026CalendarGrid(),
                          const SizedBox(height: 12),
                          const Text(
                            '• Nov 26 (Today): Active NUC & Post-UTME Verification\n• Nov 30: O\'Level Scratch-Card Upload & CAPS Batch Release',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedSlate,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick AI Admissions Assistant Card right on Dashboard
                    PrismGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: AppColors.electricMagenta),
                              SizedBox(width: 8),
                              Text(
                                'AI Admissions Copilot — Quick Assist',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ActionChip(
                                label: const Text('Auto-fill all 4 Forms'),
                                onPressed: () {
                                  ref
                                      .read(fresherProvider.notifier)
                                      .askFresherAi(
                                      'Complete and validate all 4 application cards');
                                  setState(() => _selectedNav = 6);
                                },
                              ),
                              ActionChip(
                                label: const Text('Check Cut-Off & Eligibility'),
                                onPressed: () {
                                  ref
                                      .read(fresherProvider.notifier)
                                      .askFresherAi(
                                      'Check my eligibility and recommend departments');
                                  setState(() => _selectedNav = 6);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _aiController,
                                  onSubmitted: (v) {
                                    ref
                                        .read(fresherProvider.notifier)
                                        .askFresherAi(v);
                                    _aiController.clear();
                                    setState(() => _selectedNav = 6);
                                  },
                                  decoration: const InputDecoration(
                                    hintText:
                                    'Ask AI to fill forms, check status, or pay fees...',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PrismGradientButton(
                                onPressed: () {
                                  if (_aiController.text.trim().isNotEmpty) {
                                    ref
                                        .read(fresherProvider.notifier)
                                        .askFresherAi(_aiController.text);
                                    _aiController.clear();
                                  }
                                  setState(() => _selectedNav = 6);
                                },
                                icon: const Icon(Icons.send, size: 16),
                                label: 'Ask AI',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressStripCard({
    required String title,
    required bool isDone,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final accent = isDone ? AppColors.emeraldPulse : AppColors.amberFlare;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 225,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent, width: 1.6),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isDone ? 'Done' : 'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kvRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedSlate,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNovember2026CalendarGrid() {
    const days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    // November 1, 2026 is a Sunday (30 days total)
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days
              .map((d) => SizedBox(
            width: 34,
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.mutedSlate,
              ),
            ),
          ))
              .toList(),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 18,
          runSpacing: 6,
          children: List.generate(30, (index) {
            final day = index + 1;
            final isToday = day == 26;
            final isMilestone = day == 20 || day == 30;
            return Container(
              width: 34,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.electricIndigo
                    : (isMilestone
                    ? AppColors.amberFlare.withValues(alpha: 0.2)
                    : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  (isToday || isMilestone) ? FontWeight.w900 : FontWeight.w500,
                  color: isToday ? Colors.white : AppColors.deepObsidian,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 2. 4-STAGE APPLICATION WIZARD
  Widget _build4StageApplicationWizard(
      FresherApplicant app,
      NigerianUniversitySpec uni,
      FresherState fresherState,
      ) {
    final ageValid = app.isMinimum16YearsOld();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: PrismGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                const Text(
                  '2026/2027 Undergraduate Application Wizard (4 Sections)',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                PrismGradientButton(
                  onPressed: () {
                    ref.read(fresherProvider.notifier).askFresherAi(
                        'Complete and validate all 4 application cards');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.emeraldPulse,
                        content: Text(
                            'AI Copilot validated and marked all 4 sections DONE!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: 'AI Auto-Complete All 4 Sections',
                ),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('1. Personal')),
                ButtonSegment(value: 1, label: Text('2. Programme')),
                ButtonSegment(value: 2, label: Text('3. JAMB & O\'Level')),
                ButtonSegment(value: 3, label: Text('4. Guardian')),
              ],
              selected: {_wizardStep},
              onSelectionChanged: (v) => setState(() => _wizardStep = v.first),
            ),
            const SizedBox(height: 18),
            if (_wizardStep == 0) ...[
              TextFormField(
                initialValue: app.fullName,
                decoration:
                const InputDecoration(labelText: 'Full Legal Name'),
                onChanged: (v) => ref
                    .read(fresherProvider.notifier)
                    .updateApplicantRecord(
                    app.copyWith(fullName: v.toUpperCase())),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: app.dateOfBirth,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth (YYYY-MM-DD — Min Age 16)',
                      ),
                      onChanged: (v) => ref
                          .read(fresherProvider.notifier)
                          .updateApplicantRecord(app.copyWith(dateOfBirth: v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: app.nin,
                      decoration: const InputDecoration(
                          labelText: 'NIN (11-Digit National ID)'),
                      onChanged: (v) => ref
                          .read(fresherProvider.notifier)
                          .updateApplicantRecord(app.copyWith(nin: v)),
                    ),
                  ),
                ],
              ),
              if (!ageValid)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Warning: JAMB/NUC 2026 policy requires applicants to be at least 16 years old by Sept 30, 2026.',
                    style: TextStyle(
                        color: AppColors.crimsonAlert,
                        fontWeight: FontWeight.w800,
                        fontSize: 12),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: app.stateOfOrigin,
                      decoration:
                      const InputDecoration(labelText: 'State of Origin'),
                      onChanged: (v) => ref
                          .read(fresherProvider.notifier)
                          .updateApplicantRecord(
                          app.copyWith(stateOfOrigin: v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: app.lga,
                      decoration: const InputDecoration(
                          labelText: 'Local Government Area (LGA)'),
                      onChanged: (v) => ref
                          .read(fresherProvider.notifier)
                          .updateApplicantRecord(app.copyWith(lga: v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(fresherProvider.notifier).updateApplicantRecord(
                      app.copyWith(personalInfoDone: true));
                  setState(() => _wizardStep = 1);
                },
                icon: const Icon(Icons.check),
                label: const Text('Save Personal Info & Continue'),
              ),
            ] else if (_wizardStep == 1) ...[
              DropdownButtonFormField<String>(
                initialValue: app.universityCode,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Preferred Nigerian University (10 Institutions)'),
                items: fresherState.universities
                    .map((u) => DropdownMenuItem(
                    value: u.code,
                    child: Text('${u.name} (Cut-off: ${u.jambCutOff})')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(fresherProvider.notifier).updateApplicantRecord(
                        app.copyWith(universityCode: v));
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: twelveDepartments.contains(app.preferredDepartment)
                    ? app.preferredDepartment
                    : twelveDepartments.first,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'First Choice Department (12 Faculties)'),
                items: twelveDepartments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(fresherProvider.notifier).updateApplicantRecord(
                        app.copyWith(preferredDepartment: v));
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                twelveDepartments.contains(app.secondChoiceDepartment)
                    ? app.secondChoiceDepartment
                    : twelveDepartments[1],
                isExpanded: true,
                decoration:
                const InputDecoration(labelText: 'Second Choice Department'),
                items: twelveDepartments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(fresherProvider.notifier).updateApplicantRecord(
                        app.copyWith(secondChoiceDepartment: v));
                  }
                },
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(fresherProvider.notifier)
                      .updateApplicantRecord(app.copyWith(programmeDone: true));
                  setState(() => _wizardStep = 2);
                },
                icon: const Icon(Icons.check),
                label: const Text('Save Programme & Continue'),
              ),
            ] else if (_wizardStep == 2) ...[
              TextFormField(
                initialValue: app.oLevelSummary,
                decoration: const InputDecoration(
                    labelText: 'O\'Level Results (WAEC / NECO / NABTEB Grades)'),
                onChanged: (v) => ref
                    .read(fresherProvider.notifier)
                    .updateApplicantRecord(app.copyWith(oLevelSummary: v)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: app.scratchCardPin,
                decoration: const InputDecoration(
                    labelText: 'WAEC / NECO Result Checker Scratch Card PIN'),
                onChanged: (v) => ref
                    .read(fresherProvider.notifier)
                    .updateApplicantRecord(app.copyWith(scratchCardPin: v)),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(fresherProvider.notifier)
                      .updateApplicantRecord(app.copyWith(educationDone: true));
                  setState(() => _wizardStep = 3);
                },
                icon: const Icon(Icons.check),
                label: const Text('Save JAMB & O\'Level Credentials'),
              ),
            ] else ...[
              TextFormField(
                initialValue: app.guardianName,
                decoration:
                const InputDecoration(labelText: 'Parent / Guardian Name'),
                onChanged: (v) => ref
                    .read(fresherProvider.notifier)
                    .updateApplicantRecord(app.copyWith(guardianName: v)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: app.guardianPhone,
                decoration:
                const InputDecoration(labelText: 'Guardian Phone Number'),
                onChanged: (v) => ref
                    .read(fresherProvider.notifier)
                    .updateApplicantRecord(app.copyWith(guardianPhone: v)),
              ),
              const SizedBox(height: 14),
              PrismGradientButton(
                onPressed: () {
                  ref
                      .read(fresherProvider.notifier)
                      .updateApplicantRecord(app.copyWith(guardianDone: true));
                  setState(() => _selectedNav = 0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.emeraldPulse,
                      content: Text(
                          'All 4 Application Sections Completed & Submitted!'),
                    ),
                  );
                },
                icon: const Icon(Icons.verified),
                label: 'Complete Guardian Info & Finish Application',
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 3. TRANSACTIONS & REMITA RRR
  Widget _buildTransactionsView(
      FresherApplicant app, NigerianUniversitySpec uni) {
    final isAdmitted = app.status == AdmissionDecisionStatus.admittedOffered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: PrismGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admissions Remita Treasury & RRR Transactions',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: app.postUtmeFeePaid
                      ? null
                      : () => ref
                      .read(fresherProvider.notifier)
                      .payPostUtmeScreeningFee(app.jambRegNumber),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(app.postUtmeFeePaid
                      ? 'Post-UTME Fee Paid (${app.postUtmeRrr})'
                      : 'Pay Post-UTME Screening Fee (₦${NumberFormat('#,##0').format(uni.postUtmeFeeNaira)})'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldPulse,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (!isAdmitted || app.acceptanceFeePaid)
                      ? null
                      : () => ref
                      .read(fresherProvider.notifier)
                      .payAcceptanceFee(app.jambRegNumber),
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(!isAdmitted
                      ? 'Acceptance Fee (Unlocks upon Admission)'
                      : (app.acceptanceFeePaid
                      ? 'Acceptance Fee Paid (${app.acceptanceRrr})'
                      : 'Pay Acceptance Fee (₦${NumberFormat('#,##0').format(uni.acceptanceFeeNaira)})')),
                ),
              ],
            ),
            const Divider(height: 24),
            ...app.transactions.map(
                  (tx) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.emeraldPulse,
                  child: Icon(Icons.check, color: Colors.white),
                ),
                title: Text(tx.title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('Remita RRR: ${tx.rrr} • Code 00 Verified'),
                trailing: Text(
                  '₦${NumberFormat('#,##0').format(tx.amountNaira)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.emeraldPulse),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. PRINT FORMS & SLIPS
  Widget _buildPrintFormsView(
      FresherApplicant app, NigerianUniversitySpec uni) {
    final isAdmitted = app.status == AdmissionDecisionStatus.admittedOffered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: PrismGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Official Printable Admissions & NUC Clearance Slips (PDF)',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.description,
                  color: AppColors.electricIndigo),
              title: const Text('Application Bio-Data Summary Form (Form 01)'),
              subtitle: const Text(
                  'Complete personal, JAMB, O\'Level & guardian bio-data printout'),
              trailing: ElevatedButton(
                onPressed: () => ref
                    .read(fresherProvider.notifier)
                    .printOfficialFresherDocument(
                  app,
                  documentTitle:
                  'APPLICATION BIO-DATA SUMMARY FORM (FORM 01)',
                ),
                child: const Text('Print PDF'),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.qr_code_2,
                  color: AppColors.electricMagenta),
              title: const Text('Post-UTME Screening Invitation Slip'),
              subtitle: Text('${uni.name} • ${uni.screeningMode}'),
              trailing: ElevatedButton(
                onPressed: () => ref
                    .read(fresherProvider.notifier)
                    .printOfficialFresherDocument(
                  app,
                  documentTitle: 'POST-UTME SCREENING INVITATION SLIP',
                ),
                child: const Text('Print PDF'),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.workspace_premium,
                color: isAdmitted
                    ? AppColors.emeraldPulse
                    : AppColors.mutedSlate,
              ),
              title: const Text('Official Provisional Offer of Admission Letter'),
              subtitle: Text(isAdmitted
                  ? 'Unlocked & QR-Stamped by ${uni.shortName} Registrar'
                  : 'Unlocks automatically once Admissions Admin approves your offer'),
              trailing: ElevatedButton(
                onPressed: !isAdmitted
                    ? null
                    : () => ref
                    .read(fresherProvider.notifier)
                    .printOfficialFresherDocument(
                  app,
                  documentTitle:
                  'OFFICIAL PROVISIONAL OFFER OF ADMISSION LETTER',
                ),
                child: const Text('Print Letter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. APPLICATION TRACKER & NUC CLEARANCE
  Widget _buildNucTrackerView(
      FresherApplicant app, NigerianUniversitySpec uni) {
    final isAdmitted = app.status == AdmissionDecisionStatus.admittedOffered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: PrismGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NUC Mandatory Freshers Clearance & Matriculation Pipeline (${app.completedClearanceDocsCount}/5 Verified)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (app.issuedMatricNumber != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.emeraldPulse.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.emeraldPulse),
                ),
                child: Text(
                  'CONGRATULATIONS! ISSUED MATRICULATION NUMBER: ${app.issuedMatricNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.emeraldPulse,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...app.nucClearanceDocs.entries.map(
                  (entry) => CheckboxListTile(
                value: entry.value,
                onChanged: !isAdmitted
                    ? null
                    : (_) => ref
                    .read(fresherProvider.notifier)
                    .toggleNucClearanceDocument(
                    app.jambRegNumber, entry.key),
                title: Text(entry.key),
                subtitle: Text(
                  !isAdmitted
                      ? 'Unlocks once Admission Status flips from Pending to ADMITTED'
                      : (entry.value
                      ? 'Uploaded & NUC Verified'
                      : 'Click to upload & verify credential'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 6. NOTIFICATIONS FEED
  Widget _buildNotificationsView(FresherApplicant app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: PrismGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admissions & JAMB CAPS Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...app.notifications.map(
                  (n) => ListTile(
                leading: const Icon(Icons.notifications_active,
                    color: AppColors.electricIndigo),
                title: Text(n, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 7. FULL-SCREEN FRESHER AI COPILOT
  Widget _buildFullAiCopilotView(
      FresherApplicant app,
      NigerianUniversitySpec uni,
      FresherState fresherState,
      ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: PrismGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fresher & NUC Admissions AI Copilot — ${uni.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Auto-complete all 4 application cards'),
                  onPressed: () => ref
                      .read(fresherProvider.notifier)
                      .askFresherAi('Complete all 4 application cards'),
                ),
                ActionChip(
                  label: const Text('Have I been admitted yet?'),
                  onPressed: () => ref
                      .read(fresherProvider.notifier)
                      .askFresherAi('Have I been admitted yet?'),
                ),
                ActionChip(
                  label: const Text('Check JAMB cut-off & recommend course'),
                  onPressed: () => ref
                      .read(fresherProvider.notifier)
                      .askFresherAi('Check cut-off and recommend department'),
                ),
                ActionChip(
                  label: const Text('Pay Remita Screening / Acceptance Fee'),
                  onPressed: () => ref
                      .read(fresherProvider.notifier)
                      .askFresherAi('Pay my Remita fee'),
                ),
                ActionChip(
                  label: const Text('Print Admission / Screening Form'),
                  onPressed: () => ref
                      .read(fresherProvider.notifier)
                      .askFresherAi('Print my form'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: fresherState.aiMessages.length,
                itemBuilder: (context, idx) {
                  final m = fresherState.aiMessages[idx];
                  return Align(
                    alignment:
                    m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 640),
                      decoration: BoxDecoration(
                        color: m.isUser
                            ? AppColors.electricIndigo
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: m.isUser
                            ? null
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(
                          color:
                          m.isUser ? Colors.white : AppColors.deepObsidian,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aiController,
                    onSubmitted: (v) {
                      ref.read(fresherProvider.notifier).askFresherAi(v);
                      _aiController.clear();
                    },
                    decoration: const InputDecoration(
                      hintText:
                      'Ask Fresher AI to fill forms, check admission status, or pay fees...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PrismGradientButton(
                  onPressed: () {
                    ref
                        .read(fresherProvider.notifier)
                        .askFresherAi(_aiController.text);
                    _aiController.clear();
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: 'Send',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}