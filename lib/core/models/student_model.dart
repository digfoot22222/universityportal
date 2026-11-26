import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

enum VerificationStatus { unverified, aiPreVerified, adminApproved, flagged }

enum UserRole { student, admin }

enum StudentGender { male, female }

class CourseScoreRecord {
  final String courseCode;
  final String courseTitle;
  final int creditUnits;
  final double caScore; // 0 - 30
  final double examScore; // 0 - 70
  final bool isPublished;

  const CourseScoreRecord({
    required this.courseCode,
    required this.courseTitle,
    required this.creditUnits,
    required this.caScore,
    required this.examScore,
    this.isPublished = false,
  });

  double get totalScore => (caScore + examScore).clamp(0, 100);

  String get letterGrade {
    final t = totalScore;
    if (t >= 70) return 'A';
    if (t >= 60) return 'B';
    if (t >= 50) return 'C';
    if (t >= 45) return 'D';
    if (t >= 40) return 'E';
    return 'F';
  }

  double get gradePoint {
    switch (letterGrade) {
      case 'A':
        return 5.0;
      case 'B':
        return 4.0;
      case 'C':
        return 3.0;
      case 'D':
        return 2.0;
      case 'E':
        return 1.0;
      default:
        return 0.0;
    }
  }

  CourseScoreRecord copyWith({
    double? caScore,
    double? examScore,
    bool? isPublished,
  }) {
    return CourseScoreRecord(
      courseCode: courseCode,
      courseTitle: courseTitle,
      creditUnits: creditUnits,
      caScore: caScore ?? this.caScore,
      examScore: examScore ?? this.examScore,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

class StudentAccount {
  final String id;
  final String matricNumber;
  final String jambRegNumber;
  final String fullName;
  final String email;
  final StudentGender gender;
  final String department;
  final String faculty;
  final String level;
  final String semester;
  final String cgpa;
  final UserRole role;
  final VerificationStatus verificationStatus;
  final bool isSuspended;
  final bool isCredentialRevoked;
  final bool livenessVerified;
  final double livenessMatchScore;
  final Uint8List? profilePhotoBytes;
  final String? extractedDocumentSummary;
  final double? aiConfidenceScore;
  final List<int>? uploadedDocumentBytes;
  final String? assignedRoomId;
  final String? assignedBunkLabel;

  // NUC Academic & Grading Fields
  final List<String> registeredCourseCodes;
  final List<CourseScoreRecord> courseGrades;
  final bool courseFormApproved;
  final bool isAiProSubscriber;
  final String characterSummary;

  // Privacy controls for Public Credential Verifier
  final bool shareDepartmentPublicly;
  final bool shareCgpaPublicly;
  final bool shareHostelStatusPublicly;

  const StudentAccount({
    required this.id,
    required this.matricNumber,
    this.jambRegNumber = '2026948102BA',
    required this.fullName,
    required this.email,
    required this.gender,
    required this.department,
    this.faculty = 'NUC Accredited Faculty',
    required this.level,
    this.semester = 'First Semester',
    this.cgpa = '4.62 / 5.00 (First Class Standing)',
    this.role = UserRole.student,
    this.verificationStatus = VerificationStatus.unverified,
    this.isSuspended = false,
    this.isCredentialRevoked = false,
    this.livenessVerified = false,
    this.livenessMatchScore = 0.0,
    this.profilePhotoBytes,
    this.extractedDocumentSummary,
    this.aiConfidenceScore,
    this.uploadedDocumentBytes,
    this.assignedRoomId,
    this.assignedBunkLabel,
    this.registeredCourseCodes = const [],
    this.courseGrades = const [],
    this.courseFormApproved = false,
    this.isAiProSubscriber = false,
    this.characterSummary =
    'Quiet night-owl scholar • High cleanliness • Structured routine',
    this.shareDepartmentPublicly = true,
    this.shareCgpaPublicly = true,
    this.shareHostelStatusPublicly = true,
  });

  static List<String> validLevelsForDepartment(String dept) {
    if (dept == 'Medicine & Surgery (MBBS)' || dept == 'Pharmacy (Pharm.D)') {
      return const [
        '100 Level',
        '200 Level',
        '300 Level',
        '400 Level',
        '500 Level',
        '600 Level',
      ];
    }
    if (dept == 'Nursing Science (B.NSc)' ||
        dept == 'Software Engineering' ||
        dept == 'Electrical & Electronics Engineering' ||
        dept == 'Mechanical Engineering') {
      return const [
        '100 Level',
        '200 Level',
        '300 Level',
        '400 Level',
        '500 Level',
      ];
    }
    return const [
      '100 Level',
      '200 Level',
      '300 Level',
      '400 Level',
    ];
  }

  double get computedLiveGpa {
    if (courseGrades.isEmpty) return 4.62;
    double totalPoints = 0;
    int totalUnits = 0;
    for (final g in courseGrades) {
      totalPoints += g.gradePoint * g.creditUnits;
      totalUnits += g.creditUnits;
    }
    if (totalUnits == 0) return 0.0;
    return totalPoints / totalUnits;
  }

  String get cryptographicCredentialHash {
    final payload = '$id|$matricNumber|$fullName|$department|UNICORE_NUC_2026';
    return sha256
        .convert(utf8.encode(payload))
        .toString()
        .substring(0, 24)
        .toUpperCase();
  }

  String get maskedMatric {
    if (matricNumber.length < 6) return matricNumber;
    return '${matricNumber.substring(0, 4)}***${matricNumber.substring(matricNumber.length - 3)}';
  }

  StudentAccount copyWith({
    StudentGender? gender,
    String? department,
    String? level,
    String? semester,
    VerificationStatus? verificationStatus,
    bool? isSuspended,
    bool? isCredentialRevoked,
    bool? livenessVerified,
    double? livenessMatchScore,
    Uint8List? profilePhotoBytes,
    String? extractedDocumentSummary,
    double? aiConfidenceScore,
    List<int>? uploadedDocumentBytes,
    String? assignedRoomId,
    String? assignedBunkLabel,
    List<String>? registeredCourseCodes,
    List<CourseScoreRecord>? courseGrades,
    bool? courseFormApproved,
    bool? isAiProSubscriber,
    String? characterSummary,
    bool? shareDepartmentPublicly,
    bool? shareCgpaPublicly,
    bool? shareHostelStatusPublicly,
  }) {
    return StudentAccount(
      id: id,
      matricNumber: matricNumber,
      jambRegNumber: jambRegNumber,
      fullName: fullName,
      email: email,
      gender: gender ?? this.gender,
      department: department ?? this.department,
      faculty: faculty,
      level: level ?? this.level,
      semester: semester ?? this.semester,
      cgpa: cgpa,
      role: role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isSuspended: isSuspended ?? this.isSuspended,
      isCredentialRevoked: isCredentialRevoked ?? this.isCredentialRevoked,
      livenessVerified: livenessVerified ?? this.livenessVerified,
      livenessMatchScore: livenessMatchScore ?? this.livenessMatchScore,
      profilePhotoBytes: profilePhotoBytes ?? this.profilePhotoBytes,
      extractedDocumentSummary:
      extractedDocumentSummary ?? this.extractedDocumentSummary,
      aiConfidenceScore: aiConfidenceScore ?? this.aiConfidenceScore,
      uploadedDocumentBytes:
      uploadedDocumentBytes ?? this.uploadedDocumentBytes,
      assignedRoomId: assignedRoomId ?? this.assignedRoomId,
      assignedBunkLabel: assignedBunkLabel ?? this.assignedBunkLabel,
      registeredCourseCodes:
      registeredCourseCodes ?? this.registeredCourseCodes,
      courseGrades: courseGrades ?? this.courseGrades,
      courseFormApproved: courseFormApproved ?? this.courseFormApproved,
      isAiProSubscriber: isAiProSubscriber ?? this.isAiProSubscriber,
      characterSummary: characterSummary ?? this.characterSummary,
      shareDepartmentPublicly:
      shareDepartmentPublicly ?? this.shareDepartmentPublicly,
      shareCgpaPublicly: shareCgpaPublicly ?? this.shareCgpaPublicly,
      shareHostelStatusPublicly:
      shareHostelStatusPublicly ?? this.shareHostelStatusPublicly,
    );
  }
}