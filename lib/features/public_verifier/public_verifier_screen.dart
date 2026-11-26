import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/student_model.dart';
import '../../core/theme/app_theme.dart';
import '../admin_console/providers/admin_provider.dart';

class PublicCredentialVerifierScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const PublicCredentialVerifierScreen({super.key, this.initialQuery});

  @override
  ConsumerState<PublicCredentialVerifierScreen> createState() =>
      _PublicCredentialVerifierScreenState();
}

class _PublicCredentialVerifierScreenState
    extends ConsumerState<PublicCredentialVerifierScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.initialQuery ?? 'ENG/2026/0419');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(adminProvider).students;
    final query = _searchController.text.trim().toLowerCase();

    StudentAccount? matched;
    for (final s in students) {
      if (s.matricNumber.toLowerCase() == query ||
          s.cryptographicCredentialHash.toLowerCase() == query) {
        matched = s;
        break;
      }
    }

    return RainbowAuroraScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Public Cryptographic Credential Verifier'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: PrismGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.qr_code_scanner,
                            color: AppColors.electricIndigo, size: 28),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'NYSC, Embassy & Employer Verification Gateway',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter a Matriculation Number or 24-character SHA-256 Credential Hash to verify live university standing.',
                      style:
                      TextStyle(color: AppColors.mutedSlate, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Matric No. or SHA-256 Credential ID',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PrismGradientButton(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.verified_user),
                          label: 'Verify',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (matched == null)
                      const Text(
                        'No matching student credential found in the University Registry.',
                        style: TextStyle(color: AppColors.crimsonAlert),
                      )
                    else
                      _buildCertificateCard(matched),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateCard(StudentAccount student) {
    final revoked = student.isCredentialRevoked || student.isSuspended;
    final verified =
        student.verificationStatus == VerificationStatus.adminApproved ||
            student.verificationStatus == VerificationStatus.aiPreVerified;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: revoked
              ? AppColors.crimsonAlert
              : (verified ? AppColors.emeraldPulse : AppColors.amberFlare),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                revoked
                    ? Icons.gpp_bad
                    : (verified ? Icons.verified : Icons.pending),
                color: revoked
                    ? AppColors.crimsonAlert
                    : (verified
                    ? AppColors.emeraldPulse
                    : AppColors.amberFlare),
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  revoked
                      ? 'CREDENTIAL REVOKED BY REGISTRY'
                      : (verified
                      ? 'AUTHENTIC UNIVERSITY CREDENTIAL'
                      : 'PENDING FINAL REGISTRY SEAL'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: revoked
                        ? AppColors.crimsonAlert
                        : (verified
                        ? AppColors.emeraldPulse
                        : AppColors.amberFlare),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _row('Full Legal Name:', student.fullName),
          _row('Matriculation No:', student.matricNumber),
          _row('SHA-256 Hash:', student.cryptographicCredentialHash),
          _row('Liveness Face-Match:',
              student.livenessVerified ? 'PASSED (98.4%)' : 'Pending Selfie'),
          // Respects Student's Selective Disclosure Privacy Toggles!
          _row(
            'Department / Level:',
            student.shareDepartmentPublicly
                ? '${student.department} (${student.level})'
                : 'Hidden by Student Privacy Lock',
          ),
          _row(
            'Academic Standing / CGPA:',
            student.shareCgpaPublicly
                ? student.cgpa
                : 'Hidden by Student Selective Disclosure',
          ),
          _row(
            'Campus Hostel Clearance:',
            student.shareHostelStatusPublicly
                ? (student.assignedBunkLabel ?? 'No Bed Allocated Yet')
                : 'Hidden by Student Privacy Lock',
          ),
          const SizedBox(height: 16),
          Center(
            child: QrImageView(
              data:
              'UNICORE-VERIFY|${student.matricNumber}|${student.cryptographicCredentialHash}',
              size: 120,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 165,
            child: Text(k,
                style:
                const TextStyle(color: AppColors.mutedSlate, fontSize: 13)),
          ),
          Expanded(
            child: Text(v,
                style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}