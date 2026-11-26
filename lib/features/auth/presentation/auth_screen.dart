import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/student_model.dart';
import '../../../core/network/online_guard_banner.dart';
import '../../../core/theme/app_theme.dart';
import '../../admin_console/providers/admin_provider.dart';
import '../../fresher_admissions/providers/fresher_provider.dart';
import '../../public_verifier/public_verifier_screen.dart';
import '../providers/auth_provider.dart';
import 'biometric_gate_dialog.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isFresherPortalMode = false;
  bool _isRegistrationMode = false;
  bool _obscurePassword = true;
  bool _livenessCompleted = false;
  Uint8List? _uploadedPortrait;

  StudentGender _selectedGender = StudentGender.male;
  String _selectedDepartment = 'Computer Science';
  String _selectedLevel = '100 Level';
  String _selectedUniversityCode = 'UNILAG';

  final _fullNameController = TextEditingController();
  final _matricController = TextEditingController(text: 'CSC/2023/0419');
  final _jambController = TextEditingController(text: '202630491829BA');
  final _utmeScoreController = TextEditingController(text: '274');
  final _oLevelController = TextEditingController(
      text:
      'WAEC: English (B2), Maths (A1), Physics (B2), Chemistry (B3), Further Maths (A1)');
  final _stateOriginController = TextEditingController(text: 'Anambra State');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Student@2026');
  final _otpController = TextEditingController(text: '202600');
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
    _fullNameController.dispose();
    _matricController.dispose();
    _jambController.dispose();
    _utmeScoreController.dispose();
    _oLevelController.dispose();
    _stateOriginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _pickPortraitPhoto() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _uploadedPortrait = bytes;
        _livenessCompleted = true;
      });
    }
  }

  Future<void> _handlePortalSignIn() async {
    if (_isFresherPortalMode) {
      if (_isRegistrationMode) {
        if (_fullNameController.text.trim().isEmpty ||
            _jambController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Enter Full Name and JAMB Registration Number.')),
          );
          return;
        }
        final verified = await BiometricGateDialog.requireVerification(
          context,
          userName: _fullNameController.text.trim(),
          identifierLabel: _jambController.text.trim().toUpperCase(),
          registeredPortraitBytes: _uploadedPortrait,
        );
        if (!verified) return;

        ref.read(fresherProvider.notifier).registerNewFresher(
          fullName: _fullNameController.text,
          jambRegNumber: _jambController.text,
          utmeScore: int.tryParse(_utmeScoreController.text.trim()) ?? 240,
          oLevelSummary: _oLevelController.text,
          stateOfOrigin: _stateOriginController.text,
          gender: _selectedGender,
          universityCode: _selectedUniversityCode,
          preferredDepartment: _selectedDepartment,
          password: _passwordController.text,
          portraitBytes: _uploadedPortrait,
        );
      } else {
        final applicant =
        ref.read(fresherProvider.notifier).authenticateFresher(
          jambRegNumber: _jambController.text,
          password: _passwordController.text,
        );
        if (applicant == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.crimsonAlert,
              content: Text(
                  'Invalid JAMB Reg No. or Password (Demo: 202630491829BA / Fresher@2026).'),
            ),
          );
          return;
        }

        final verified = await BiometricGateDialog.requireVerification(
          context,
          userName: applicant.fullName,
          identifierLabel: applicant.jambRegNumber,
          registeredPortraitBytes: applicant.portraitBytes,
        );
        if (!verified) return;

        ref
            .read(fresherProvider.notifier)
            .completeFresherLogin(applicant.jambRegNumber);
      }
      return;
    }

    final previewUser =
    ref.read(adminProvider.notifier).findStudent(_matricController.text);
    final verified = await BiometricGateDialog.requireVerification(
      context,
      userName: previewUser?.fullName ??
          (_fullNameController.text.isNotEmpty
              ? _fullNameController.text
              : 'University User'),
      identifierLabel: _matricController.text.trim().toUpperCase(),
      registeredPortraitBytes:
      _uploadedPortrait ?? previewUser?.profilePhotoBytes,
    );
    if (!verified) return;

    if (_isRegistrationMode) {
      await ref.read(authProvider.notifier).registerHardenedStudent(
        fullName: _fullNameController.text,
        matricNumber: _matricController.text,
        email: _emailController.text,
        gender: _selectedGender,
        department: _selectedDepartment,
        level: _selectedLevel,
        semester: 'First Semester',
        password: _passwordController.text,
        profilePhotoBytes: _uploadedPortrait,
        livenessCompleted: _livenessCompleted,
        enableBiometrics: true,
      );
    } else {
      await ref.read(authProvider.notifier).loginWithPassword(
        matricOrEmail: _matricController.text,
        password: _passwordController.text,
        otpCode: _otpController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final policy = ref.watch(adminProvider).policy;
    final intensity = ref.watch(prismIntensityProvider);
    final fresherState = ref.watch(fresherProvider);
    final passwordStrength =
    AuthNotifier.calculatePasswordStrength(_passwordController.text);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'UniCore SaaS Campus OS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.black.withValues(alpha: 0.28),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PublicCredentialVerifierScreen(),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('Public Credential Verifier'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Toggle Prism Intensity',
            icon: Icon(
              intensity == PrismIntensity.fullPrism
                  ? Icons.wb_sunny_outlined
                  : Icons.palette_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              ref.read(prismIntensityProvider.notifier).state =
              intensity == PrismIntensity.fullPrism
                  ? PrismIntensity.softPastel
                  : PrismIntensity.fullPrism;
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          const OnlineConnectivityBanner(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 940;
                final pitchCard = _buildCommercialPitchCard();
                final authCard = _buildAuthCard(
                  authState,
                  policy.enforce2FA,
                  passwordStrength,
                  fresherState,
                );

                if (isDesktop) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: pitchCard),
                            const SizedBox(width: 36),
                            Expanded(flex: 6, child: authCard),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      pitchCard,
                      const SizedBox(height: 18),
                      authCard,
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialPitchCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.deepObsidian.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: AppColors.primaryCtaGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              '4 INTEGRATED PORTALS • 10 NIGERIAN UNIVERSITIES • ZERO-TRUST BIOMETRICS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.7,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Autonomous University OS, Admissions & Smart Housing.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Select any of the 4 portals below (1-Click Autofill) and complete the mandatory Fingerprint / Face ID verification gate.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '1-CLICK PORTAL SWITCHER (4 PORTALS):',
            style: TextStyle(
              color: AppColors.aquaMint,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: const Color(0xFFFFD700),
                avatar: const Icon(Icons.workspace_premium_rounded,
                    size: 16, color: Color(0xFF0F172A)),
                label: const Text('1. AI Pro Student: CSC/2023/0419 (Chinedu)'),
                onPressed: () {
                  setState(() {
                    _isFresherPortalMode = false;
                    _isRegistrationMode = false;
                    _matricController.text = 'CSC/2023/0419';
                    _passwordController.text = 'Student@2026';
                  });
                },
              ),
              ActionChip(
                backgroundColor: Colors.white,
                avatar: const Icon(Icons.female, size: 16, color: Colors.pink),
                label: const Text('2. Free Student (2/5 Left): NUR/2024/1108'),
                onPressed: () {
                  setState(() {
                    _isFresherPortalMode = false;
                    _isRegistrationMode = false;
                    _matricController.text = 'NUR/2024/1108';
                    _passwordController.text = 'Student@2026';
                  });
                },
              ),
              ActionChip(
                backgroundColor: AppColors.aquaMint,
                avatar: const Icon(Icons.admin_panel_settings, size: 16),
                label: const Text('3. Prof. Ogunleye (Admin): ADMIN/ICT/001'),
                onPressed: () {
                  setState(() {
                    _isFresherPortalMode = false;
                    _isRegistrationMode = false;
                    _matricController.text = 'ADMIN/ICT/001';
                    _passwordController.text = 'Admin@2026';
                  });
                },
              ),
              ActionChip(
                backgroundColor: const Color(0xFFE0E7FF),
                avatar: const Icon(Icons.how_to_reg_rounded,
                    size: 16, color: AppColors.electricIndigo),
                label: const Text(
                    '4. Fresher Admissions Portal: 202630491829BA (Chidera)'),
                onPressed: () {
                  setState(() {
                    _isFresherPortalMode = true;
                    _isRegistrationMode = false;
                    _jambController.text = '202630491829BA';
                    _passwordController.text = 'Fresher@2026';
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(
      AuthState authState,
      bool enforce2FA,
      double passwordStrength,
      FresherState fresherState,
      ) {
    final validLevels =
    StudentAccount.validLevelsForDepartment(_selectedDepartment);
    if (!validLevels.contains(_selectedLevel)) {
      _selectedLevel = validLevels.first;
    }

    return PrismGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.school_outlined),
                label: Text('Student / Admin Portal'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.how_to_reg_outlined),
                label: Text('Fresher / New Student Admissions'),
              ),
            ],
            selected: {_isFresherPortalMode},
            onSelectionChanged: (val) {
              setState(() {
                _isFresherPortalMode = val.first;
                _isRegistrationMode = false;
                if (_isFresherPortalMode) {
                  _passwordController.text = 'Fresher@2026';
                } else {
                  _passwordController.text = 'Student@2026';
                }
              });
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(_isFresherPortalMode
                    ? 'Applicant Login (Check Status)'
                    : 'Returning Login'),
              ),
              ButtonSegment(
                value: true,
                label: Text(_isFresherPortalMode
                    ? 'Create New Applicant Account'
                    : 'Hardened Enrollment'),
              ),
            ],
            selected: {_isRegistrationMode},
            onSelectionChanged: (val) =>
                setState(() => _isRegistrationMode = val.first),
          ),
          const SizedBox(height: 16),
          if (authState.errorMessage != null && !_isFresherPortalMode) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.crimsonAlert.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.crimsonAlert),
              ),
              child: Text(
                authState.errorMessage!,
                style: const TextStyle(
                    color: AppColors.crimsonAlert, fontSize: 12),
              ),
            ),
          ],
          if (_isRegistrationMode) ...[
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Legal Name (Surname First)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_isFresherPortalMode) ...[
            TextField(
              controller: _jambController,
              decoration: const InputDecoration(
                labelText:
                'JAMB Registration Number or Application # (e.g., 202630491829BA)',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (_isRegistrationMode) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedUniversityCode,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText:
                  'Select Preferred Nigerian University (10 Institutions)',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                items: fresherState.universities
                    .map(
                      (u) => DropdownMenuItem(
                    value: u.code,
                    child: Text('${u.name} (Cut-off: ${u.jambCutOff})'),
                  ),
                )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedUniversityCode = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Preferred Course / Department (12 NUC Faculties)',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: twelveDepartments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedDepartment = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _utmeScoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'JAMB UTME Score (140–400)',
                        prefixIcon: Icon(Icons.score_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _stateOriginController,
                      decoration: const InputDecoration(
                        labelText: 'State of Origin',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _oLevelController,
                decoration: const InputDecoration(
                  labelText: 'O\'Level Results (WAEC / NECO / NABTEB Grades)',
                  prefixIcon: Icon(Icons.grading_outlined),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ] else ...[
            TextField(
              controller: _matricController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Matriculation No. or Admin ID',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (_isRegistrationMode) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Academic Department',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: twelveDepartments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedDepartment = v;
                      _selectedLevel =
                          StudentAccount.validLevelsForDepartment(v).first;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
          if (_isRegistrationMode) ...[
            Row(
              children: [
                const Text('Biological Gender:',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<StudentGender>(
                    segments: const [
                      ButtonSegment(
                          value: StudentGender.male,
                          icon: Icon(Icons.male),
                          label: Text('Male')),
                      ButtonSegment(
                          value: StudentGender.female,
                          icon: Icon(Icons.female),
                          label: Text('Female')),
                    ],
                    selected: {_selectedGender},
                    onSelectionChanged: (v) =>
                        setState(() => _selectedGender = v.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickPortraitPhoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(_uploadedPortrait != null
                  ? 'Passport Photograph Uploaded (Ready for Face ID)'
                  : 'Upload Passport Photograph (for Face ID & Form 01)'),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          if (!_isFresherPortalMode && !_isRegistrationMode && enforce2FA) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: '2FA Institutional OTP Code (Demo: 202600)',
                prefixIcon: Icon(Icons.security),
              ),
            ),
          ],
          if (_isRegistrationMode) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: passwordStrength,
              minHeight: 6,
              color: AppColors.emeraldPulse,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          PrismGradientButton(
            onPressed: authState.isLoading ? null : _handlePortalSignIn,
            icon: const Icon(Icons.fingerprint),
            label: _isFresherPortalMode
                ? (_isRegistrationMode
                ? 'Create Applicant Account & Verify Biometrics'
                : 'Sign In to Fresher Admissions (Biometric Lock)')
                : (_isRegistrationMode
                ? 'Complete Enrollment & Verify Biometrics'
                : 'Sign In & Scan Fingerprint / Face ID'),
          ),
        ],
      ),
    );
  }
}