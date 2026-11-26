import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../fresher_admissions/providers/fresher_provider.dart';
import '../../payments_remita/providers/payment_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  void _openGradeEditorDialog(StudentAccount student) {
    final caControllers = <String, TextEditingController>{};
    final examControllers = <String, TextEditingController>{};

    for (final code in student.registeredCourseCodes) {
      caControllers[code] = TextEditingController(text: '25');
      examControllers[code] = TextEditingController(text: '54');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            'Academic Grading: ${student.fullName} (${student.matricNumber})'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: student.registeredCourseCodes.map((code) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          code,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: caControllers[code],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CA (0–30)',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: examControllers[code],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Exam (0–70)',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          PrismGradientButton(
            onPressed: () {
              double totalPoints = 0;
              int count = 0;
              for (final code in student.registeredCourseCodes) {
                final ca = (double.tryParse(caControllers[code]!.text) ?? 20)
                    .clamp(0.0, 30.0);
                final exam =
                (double.tryParse(examControllers[code]!.text) ?? 50)
                    .clamp(0.0, 70.0);
                final total = ca + exam;
                final gp = total >= 70
                    ? 5.0
                    : (total >= 60
                    ? 4.0
                    : (total >= 50
                    ? 3.0
                    : (total >= 45 ? 2.0 : (total >= 40 ? 1.0 : 0.0))));
                totalPoints += gp;
                count++;
              }
              final newGpa =
              count > 0 ? (totalPoints / count) : student.computedLiveGpa;
              ref.read(adminProvider.notifier).logSecurityEvent(
                actor: 'ADMIN/ICT/001',
                action: 'LECTURER_GRADES_SUBMITTED',
                target:
                '${student.matricNumber} • Computed GPA: ${newGpa.toStringAsFixed(2)}',
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.emeraldPulse,
                  content: Text(
                    'CA & Exam scores recorded! Computed CGPA for ${student.fullName}: ${newGpa.toStringAsFixed(2)} / 5.00',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.save, size: 16),
            label: 'Save & Recompute CGPA',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final paymentState = ref.watch(paymentProvider);
    final fresherState = ref.watch(fresherProvider);
    final students =
    adminState.students.where((s) => s.role == UserRole.student).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Executive Revenue & Governance Banner
          PrismGlassCard(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Senate, Lecturer & Admissions Governance Console',
                      style:
                      TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Manage Fresher Admissions (JAMB CAPS), Student CA/Exam Grades, Curriculum & Remita Revenue',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedSlate,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldPulse.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.emeraldPulse),
                  ),
                  child: Text(
                    'Platform Split Revenue: ₦${NumberFormat('#,##0').format(paymentState.vendorPlatformSplitRevenue)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.emeraldPulse,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Fresher Admissions & JAMB CAPS Approval Queue (10 Universities)
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.how_to_reg_rounded,
                        color: AppColors.electricIndigo),
                    SizedBox(width: 8),
                    Text(
                      'Fresher Admissions & JAMB CAPS Approval Queue (10 Universities)',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Approve prospective applicants below to immediately flip their Fresher Portal from NOT ADMITTED to ADMITTED.',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedSlate),
                ),
                const SizedBox(height: 12),
                ...fresherState.applicants.map((applicant) {
                  final uni = fresherState
                      .universityByCode(applicant.universityCode);
                  final isAdmitted = applicant.status ==
                      AdmissionDecisionStatus.admittedOffered;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isAdmitted
                            ? AppColors.emeraldPulse
                            : AppColors.amberFlare,
                        width: 1.5,
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: 460,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${applicant.fullName} (${applicant.jambRegNumber})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${uni.name} • ${applicant.preferredDepartment} • UTME: ${applicant.utmeScore} (Cut-off: ${uni.jambCutOff})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.electricIndigo,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                applicant.oLevelSummary,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.mutedSlate),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${isAdmitted ? "ADMITTED OFFERED (JAMB CAPS APPROVED)" : "NOT ADMITTED — UNDER SCREENING"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isAdmitted
                                      ? AppColors.emeraldPulse
                                      : AppColors.amberFlare,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAdmitted
                                ? Colors.grey.shade300
                                : AppColors.emeraldPulse,
                            foregroundColor: isAdmitted
                                ? AppColors.deepObsidian
                                : Colors.white,
                          ),
                          onPressed: isAdmitted
                              ? null
                              : () {
                            ref
                                .read(fresherProvider.notifier)
                                .setAdminAdmissionDecision(
                              jambRegNumber:
                              applicant.jambRegNumber,
                              decision: AdmissionDecisionStatus
                                  .admittedOffered,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.emeraldPulse,
                                content: Text(
                                  'Admission Granted to ${applicant.fullName}! Their Fresher Portal is now ADMITTED.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.verified, size: 16),
                          label: Text(
                            isAdmitted
                                ? 'Admission Offered'
                                : 'Grant Admission Offer',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Lecturer Student Grading & Course Form Approval Roster
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enrolled Student Roster, CA/Exam Grading & Course Form Approval',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ...students.map((student) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${student.fullName} (${student.matricNumber})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            Text(
                              '${student.department} • ${student.level} • Live CGPA: ${student.computedLiveGpa.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.mutedSlate),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openGradeEditorDialog(student),
                              icon: const Icon(Icons.edit_note, size: 18),
                              label: const Text('Enter CA / Exam Scores'),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: student.courseFormApproved
                                    ? AppColors.emeraldPulse
                                    : AppColors.electricIndigo,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                final updated = student.copyWith(
                                  courseFormApproved:
                                  !student.courseFormApproved,
                                );
                                ref
                                    .read(adminProvider.notifier)
                                    .updateStudentRecord(updated);
                              },
                              icon: Icon(
                                student.courseFormApproved
                                    ? Icons.check_circle
                                    : Icons.approval,
                                size: 16,
                              ),
                              label: Text(
                                student.courseFormApproved
                                    ? 'Senate Approved'
                                    : 'Approve Course Form',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Zero-Trust Security Audit Log
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Institutional Security & Admissions Audit Trail',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                ...adminState.auditLogs.take(8).map(
                      (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• [${DateFormat('HH:mm:ss').format(log.timestamp)}] ${log.actor} → ${log.action}: ${log.target}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}