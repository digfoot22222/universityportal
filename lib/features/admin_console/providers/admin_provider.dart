import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/admin_policy_model.dart';
import '../../../core/models/student_model.dart';

class AdminState {
  final AdminSecurityPolicy policy;
  final List<StudentAccount> students;
  final List<SecurityAuditLog> auditLogs;
  final String activeSaaSTier;
  final int onboardedInstitutionsCount;

  const AdminState({
    required this.policy,
    required this.students,
    required this.auditLogs,
    this.activeSaaSTier = 'Enterprise NUC Campus Multi-Tenant License',
    this.onboardedInstitutionsCount = 6,
  });

  AdminState copyWith({
    AdminSecurityPolicy? policy,
    List<StudentAccount>? students,
    List<SecurityAuditLog>? auditLogs,
    String? activeSaaSTier,
    int? onboardedInstitutionsCount,
  }) {
    return AdminState(
      policy: policy ?? this.policy,
      students: students ?? this.students,
      auditLogs: auditLogs ?? this.auditLogs,
      activeSaaSTier: activeSaaSTier ?? this.activeSaaSTier,
      onboardedInstitutionsCount:
      onboardedInstitutionsCount ?? this.onboardedInstitutionsCount,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier()
      : super(
    AdminState(
      policy: const AdminSecurityPolicy(
        biometricsEnabled: true,
        enforce2FA: false,
        sessionTimeoutMinutes: 15,
        maxConcurrentSessions: 2,
      ),
      students: const [
        // 1. PAID AI PRO STUDENT ACCOUNT (Gold Crown Active, Pre-Cleared, Ready to Print Slips)
        StudentAccount(
          id: 'stu_pro_001',
          matricNumber: 'CSC/2023/0419',
          fullName: 'Chinedu Okafor',
          email: 'chinedu.okafor@student.unicore.edu.ng',
          gender: StudentGender.male,
          department: 'Computer Science',
          level: '300 Level',
          semester: 'First Semester',
          cgpa: '4.78 / 5.00 (First Class Standing)',
          role: UserRole.student,
          verificationStatus: VerificationStatus.adminApproved,
          livenessVerified: true,
          livenessMatchScore: 0.992,
          isAiProSubscriber: true,
          courseFormApproved: true,
          assignedRoomId: 'M-ZIK-101',
          assignedBunkLabel: 'Bunk A (Lower)',
          registeredCourseCodes: [
            'CSC 301',
            'CSC 303',
            'CSC 305',
            'CSC 307',
            'CSC 309',
            'CSC 399',
          ],
          courseGrades: [
            CourseScoreRecord(
              courseCode: 'CSC 301',
              courseTitle: 'Operating Systems',
              creditUnits: 4,
              caScore: 28,
              examScore: 59,
              isPublished: true,
            ),
            CourseScoreRecord(
              courseCode: 'CSC 303',
              courseTitle: 'Database Design & Management',
              creditUnits: 4,
              caScore: 26,
              examScore: 55,
              isPublished: true,
            ),
            CourseScoreRecord(
              courseCode: 'CSC 305',
              courseTitle: 'Compiler Construction',
              creditUnits: 3,
              caScore: 25,
              examScore: 52,
              isPublished: true,
            ),
            CourseScoreRecord(
              courseCode: 'CSC 307',
              courseTitle: 'Computer Networks & Data Communication',
              creditUnits: 3,
              caScore: 27,
              examScore: 58,
              isPublished: true,
            ),
            CourseScoreRecord(
              courseCode: 'CSC 309',
              courseTitle: 'Artificial Intelligence & Machine Learning',
              creditUnits: 3,
              caScore: 29,
              examScore: 63,
              isPublished: true,
            ),
          ],
        ),

        // 2. STANDARD FREE STUDENT ACCOUNT (2/5 Prompts Remaining -> Demonstrates Paywall)
        StudentAccount(
          id: 'stu_free_002',
          matricNumber: 'NUR/2024/1108',
          fullName: 'Amina Bello',
          email: 'amina.bello@student.unicore.edu.ng',
          gender: StudentGender.female,
          department: 'Nursing Science (B.NSc)',
          level: '200 Level',
          semester: 'First Semester',
          cgpa: '4.15 / 5.00 (Second Class Upper)',
          role: UserRole.student,
          verificationStatus: VerificationStatus.aiPreVerified,
          livenessVerified: true,
          livenessMatchScore: 0.985,
          isAiProSubscriber: false,
          registeredCourseCodes: [
            'NSC 201',
            'ANA 204',
            'PHS 204',
            'NSC 203',
          ],
          courseGrades: [
            CourseScoreRecord(
              courseCode: 'NSC 201',
              courseTitle: 'Fundamentals of Nursing & Bedside Care',
              creditUnits: 4,
              caScore: 24,
              examScore: 48,
              isPublished: false,
            ),
          ],
        ),

        // 3. ADMIN & LECTURER ACCOUNT
        StudentAccount(
          id: 'adm_001',
          matricNumber: 'ADMIN/ICT/001',
          fullName: 'Prof. Adewale Ogunleye (Senate & SaaS ICT Director)',
          email: 'admin@unicore.edu.ng',
          gender: StudentGender.male,
          department: 'Enterprise ICT, Counseling & Senate Directorate',
          level: 'Executive Admin',
          role: UserRole.admin,
          verificationStatus: VerificationStatus.adminApproved,
          isAiProSubscriber: true,
        ),
      ],
      auditLogs: [
        SecurityAuditLog(
          id: 'log_1',
          actor: 'SYSTEM_BOOT',
          action: 'NUC_PORTAL_INITIALIZED',
          target: '12 Departments • 100L–600L • AI Pro & Grading Ready',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    ),
  );

  StudentAccount? findStudent(String query) {
    final normalized = query.trim().toLowerCase();
    for (final s in state.students) {
      if (s.matricNumber.toLowerCase() == normalized ||
          s.email.toLowerCase() == normalized) {
        return s;
      }
    }
    return null;
  }

  void upsertStudentAccount(StudentAccount student) {
    final exists =
    state.students.any((s) => s.matricNumber == student.matricNumber);
    if (exists) {
      state = state.copyWith(
        students: state.students
            .map((s) => s.matricNumber == student.matricNumber ? student : s)
            .toList(),
      );
    } else {
      state = state.copyWith(students: [student, ...state.students]);
    }
  }

  void updateStudentCourseGrade({
    required String studentId,
    required String courseCode,
    required double caScore,
    required double examScore,
    bool? publish,
  }) {
    final clampedCa = caScore.clamp(0.0, 30.0);
    final clampedExam = examScore.clamp(0.0, 70.0);

    state = state.copyWith(
      students: state.students.map((stu) {
        if (stu.id != studentId) return stu;
        final updatedGrades = stu.courseGrades.map((g) {
          if (g.courseCode != courseCode) return g;
          return g.copyWith(
            caScore: clampedCa,
            examScore: clampedExam,
            isPublished: publish ?? g.isPublished,
          );
        }).toList();
        return stu.copyWith(courseGrades: updatedGrades);
      }).toList(),
    );

    logSecurityEvent(
      actor: 'ADMIN/ICT/001',
      action: 'COURSE_GRADE_UPDATED',
      target:
      'Student=$studentId • $courseCode (CA=${clampedCa.toStringAsFixed(0)}, Exam=${clampedExam.toStringAsFixed(0)})',
    );
  }

  void publishAllGradesForStudent(String studentId) {
    state = state.copyWith(
      students: state.students.map((stu) {
        if (stu.id != studentId) return stu;
        final published =
        stu.courseGrades.map((g) => g.copyWith(isPublished: true)).toList();
        logSecurityEvent(
          actor: 'ADMIN/ICT/001',
          action: 'SENATE_RESULTS_PUBLISHED',
          target:
          '${stu.matricNumber} • GPA=${stu.computedLiveGpa.toStringAsFixed(2)}/5.00',
        );
        return stu.copyWith(courseGrades: published);
      }).toList(),
    );
  }

  void updatePolicy(AdminSecurityPolicy newPolicy) {
    state = state.copyWith(policy: newPolicy);
    logSecurityEvent(
      actor: 'ADMIN/ICT/001',
      action: 'SECURITY_POLICY_UPDATED',
      target:
      'Timeout=${newPolicy.sessionTimeoutMinutes}m, Biometrics=${newPolicy.biometricsEnabled}, 2FA=${newPolicy.enforce2FA}',
    );
  }

  void updateStudentRecord(StudentAccount updated) {
    state = state.copyWith(
      students: state.students
          .map((s) => s.id == updated.id ? updated : s)
          .toList(),
    );
  }

  void toggleSuspendStudent(String studentId) {
    state = state.copyWith(
      students: state.students.map((s) {
        if (s.id == studentId) {
          final next = s.copyWith(isSuspended: !s.isSuspended);
          logSecurityEvent(
            actor: 'ADMIN/ICT/001',
            action: next.isSuspended ? 'ACCOUNT_SUSPENDED' : 'ACCOUNT_RESTORED',
            target: s.matricNumber,
          );
          return next;
        }
        return s;
      }).toList(),
    );
  }

  void toggleRevokeCredential(String studentId) {
    state = state.copyWith(
      students: state.students.map((s) {
        if (s.id == studentId) {
          final next = s.copyWith(isCredentialRevoked: !s.isCredentialRevoked);
          logSecurityEvent(
            actor: 'ADMIN/ICT/001',
            action: next.isCredentialRevoked
                ? 'QR_CREDENTIAL_REVOKED'
                : 'QR_CREDENTIAL_REINSTATED',
            target: '${s.matricNumber} (${s.cryptographicCredentialHash})',
          );
          return next;
        }
        return s;
      }).toList(),
    );
  }

  void approveOrRejectVerification(String studentId, bool approve) {
    state = state.copyWith(
      students: state.students.map((s) {
        if (s.id == studentId) {
          final status = approve
              ? VerificationStatus.adminApproved
              : VerificationStatus.flagged;
          logSecurityEvent(
            actor: 'ADMIN/ICT/001',
            action: approve ? 'VERIFICATION_APPROVED' : 'VERIFICATION_REJECTED',
            target: s.matricNumber,
          );
          return s.copyWith(
            verificationStatus: status,
            isCredentialRevoked: false,
          );
        }
        return s;
      }).toList(),
    );
  }

  void logSecurityEvent({
    required String actor,
    required String action,
    required String target,
  }) {
    final entry = SecurityAuditLog(
      id: const Uuid().v4(),
      actor: actor,
      action: action,
      target: target,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(auditLogs: [entry, ...state.auditLogs]);
  }
}

final adminProvider =
StateNotifierProvider<AdminNotifier, AdminState>((ref) => AdminNotifier());