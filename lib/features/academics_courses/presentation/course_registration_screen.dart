import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/academics_provider.dart';

class CourseRegistrationScreen extends ConsumerWidget {
  const CourseRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acadState = ref.watch(academicsProvider);
    final student = ref.watch(authProvider).currentUser;

    final validLevels = StudentAccount.validLevelsForDepartment(
        acadState.selectedDepartmentFilter);
    final filteredCourses = acadState.activeFilteredCourses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Department & NUC Level Switcher + Credit Unit Counter
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NUC-Standard Course Registration & AI Roadmap',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Browse all 12 departments across 100L–600L, register 15–24 units (C/R/E), and generate your QR CRF.',
                          style: TextStyle(
                              color: AppColors.mutedSlate, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: acadState.isCreditLoadValid
                            ? AppColors.emeraldPulse.withValues(alpha: 0.14)
                            : AppColors.amberFlare.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: acadState.isCreditLoadValid
                              ? AppColors.emeraldPulse
                              : AppColors.amberFlare,
                        ),
                      ),
                      child: Text(
                        'Selected Load: ${acadState.totalSelectedUnits} / 24 Units',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: acadState.isCreditLoadValid
                              ? AppColors.emeraldPulse
                              : AppColors.amberFlare,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Department & Level Dropdowns
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 340,
                      child: DropdownButtonFormField<String>(
                        value: acadState.selectedDepartmentFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Department (12 NUC Faculties)',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        items: AcademicsNotifier.twelveDepartments
                            .map((d) =>
                            DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            ref
                                .read(academicsProvider.notifier)
                                .selectDepartmentAndLevel(v);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: validLevels
                            .contains(acadState.selectedLevelFilter)
                            ? acadState.selectedLevelFilter
                            : validLevels.first,
                        decoration: const InputDecoration(
                          labelText: 'Academic Level',
                          prefixIcon: Icon(Icons.stairs_outlined),
                        ),
                        items: validLevels
                            .map((lvl) =>
                            DropdownMenuItem(value: lvl, child: Text(lvl)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            ref.read(academicsProvider.notifier).selectLevel(v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.deepObsidian,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.aquaMint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          acadState.aiAdvisorAdvice,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Course Selection Table / Cards
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${acadState.selectedDepartmentFilter} — ${acadState.selectedLevelFilter} Courses (${filteredCourses.length} Available)',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...filteredCourses.map((course) {
                  final isSelected =
                  acadState.selectedCourseCodes.contains(course.code);
                  final statusColor = course.status == 'C'
                      ? AppColors.crimsonAlert
                      : (course.status == 'R'
                      ? AppColors.electricIndigo
                      : AppColors.emeraldPulse);

                  return CheckboxListTile(
                    value: isSelected,
                    activeColor: AppColors.electricIndigo,
                    onChanged: (_) {
                      final error = ref
                          .read(academicsProvider.notifier)
                          .toggleCourse(course);
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.crimsonAlert,
                            content: Text(error),
                          ),
                        );
                      }
                    },
                    title: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${course.code} — ${course.title} (${course.creditUnits} Units)',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            course.status == 'C'
                                ? 'C • Compulsory'
                                : (course.status == 'R'
                                ? 'R • Required'
                                : 'E • Elective'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Schedule: ${course.timeSlot} • Prereq: ${course.prerequisite}',
                    ),
                  );
                }),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    PrismGradientButton(
                      onPressed:
                      (student == null || !acadState.isCreditLoadValid)
                          ? null
                          : () {
                        ref
                            .read(academicsProvider.notifier)
                            .submitCourseRegistration(student);
                        _showCourseFormDialog(
                          context,
                          student.matricNumber,
                          student.fullName,
                          acadState,
                        );
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: 'Approve & Generate QR Course Form (CRF)',
                    ),
                    if (!acadState.isCreditLoadValid)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Select between 15 and 24 credit units to lock your Course Registration Form.',
                          style: TextStyle(
                              color: AppColors.crimsonAlert, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Published Exam Results & Live 5.0 CGPA Transcript Card
          if (student != null &&
              student.courseGrades.any((g) => g.isPublished)) ...[
            PrismGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PUBLISHED SENATE SEMESTER RESULTS & CGPA',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.emeraldPulse,
                        ),
                      ),
                      Text(
                        'Live GPA: ${student.computedLiveGpa.toStringAsFixed(2)} / 5.00',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.electricIndigo,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ...student.courseGrades
                      .where((g) => g.isPublished)
                      .map(
                        (g) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${g.courseCode} — ${g.courseTitle}',
                          style:
                          const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(
                          'CA: ${g.caScore.toStringAsFixed(0)}/30 • Exam: ${g.examScore.toStringAsFixed(0)}/70 • Total: ${g.totalScore.toStringAsFixed(0)}/100'),
                      trailing: CircleAvatar(
                        backgroundColor: g.letterGrade == 'F'
                            ? AppColors.crimsonAlert
                            : AppColors.emeraldPulse,
                        child: Text(
                          g.letterGrade,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Interactive AI Course & Career Roadmap Visualizer
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route, color: AppColors.electricMagenta),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Career & Certification Roadmap (${acadState.selectedDepartmentFilter})',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...acadState.generatedRoadmap.map(
                      (stage) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                          AppColors.electricIndigo.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.phaseTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.electricIndigo,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Core Focus: ${stage.skillsAndCourses}'),
                        Text('Capstone Deliverable: ${stage.deliverableProject}'),
                        Text(
                          'Recommended Industry Cert: ${stage.industryCertification}',
                          style: const TextStyle(
                            color: AppColors.emeraldPulse,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  void _showCourseFormDialog(
      BuildContext context,
      String matric,
      String fullName,
      AcademicsState acadState,
      ) {
    final activeCodes = acadState.activeFilteredCourses
        .where((c) => acadState.selectedCourseCodes.contains(c.code))
        .map((c) => c.code)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Official Senate Course Registration Form (CRF)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$fullName ($matric)',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(
                '${acadState.selectedDepartmentFilter} • ${acadState.selectedLevelFilter}'),
            const SizedBox(height: 6),
            Text(
                'Registered Units: ${acadState.totalSelectedUnits} Units • ${activeCodes.join(", ")}'),
            const SizedBox(height: 14),
            QrImageView(
              data:
              'CRF-APPROVED|$matric|${acadState.selectedLevelFilter}|UNITS:${acadState.totalSelectedUnits}|COURSES:${activeCodes.join(",")}',
              size: 130,
            ),
          ],
        ),
        actions: [
          PrismGradientButton(
            onPressed: () => Navigator.of(ctx).pop(),
            icon: const Icon(Icons.check),
            label: 'Done',
          ),
        ],
      ),
    );
  }
}