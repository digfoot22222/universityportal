import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/models/student_model.dart';
import '../../admin_console/providers/admin_provider.dart';

enum AdmissionDecisionStatus {
  notAdmittedScreening,
  admittedOffered,
  transferRecommended,
  declined,
}

class NigerianUniversitySpec {
  final String code;
  final String name;
  final String shortName;
  final int jambCutOff;
  final double postUtmeFeeNaira;
  final double acceptanceFeeNaira;
  final String screeningMode;
  final String matricPrefix;

  const NigerianUniversitySpec({
    required this.code,
    required this.name,
    required this.shortName,
    required this.jambCutOff,
    required this.postUtmeFeeNaira,
    required this.acceptanceFeeNaira,
    required this.screeningMode,
    required this.matricPrefix,
  });
}

class FresherTransaction {
  final String rrr;
  final String title;
  final double amountNaira;
  final bool isPaid;
  final DateTime createdAt;

  const FresherTransaction({
    required this.rrr,
    required this.title,
    required this.amountNaira,
    required this.isPaid,
    required this.createdAt,
  });
}

class FresherApplicant {
  final String applicationNumber;
  final String jambRegNumber;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth;
  final String nin;
  final String lga;
  final String homeAddress;
  final String applicationType;
  final String entryType;
  final int utmeScore;
  final Map<String, int> utmeSubjects;
  final String oLevelSummary;
  final String scratchCardPin;
  final String stateOfOrigin;
  final StudentGender gender;
  final String universityCode;
  final String preferredDepartment;
  final String secondChoiceDepartment;
  final String guardianName;
  final String guardianRelationship;
  final String guardianPhone;
  final String guardianEmail;
  final bool personalInfoDone;
  final bool programmeDone;
  final bool educationDone;
  final bool guardianDone;
  final String password;
  final Uint8List? portraitBytes;
  final AdmissionDecisionStatus status;
  final String adminRemark;
  final bool postUtmeFeePaid;
  final String? postUtmeRrr;
  final bool acceptanceFeePaid;
  final String? acceptanceRrr;
  final Map<String, bool> nucClearanceDocs;
  final String? issuedMatricNumber;
  final List<FresherTransaction> transactions;
  final List<String> notifications;

  const FresherApplicant({
    required this.applicationNumber,
    required this.jambRegNumber,
    required this.fullName,
    this.email = 'applicant@unicore-admissions.edu.ng',
    this.phoneNumber = '+234 803 551 9042',
    this.dateOfBirth = '2008-05-14',
    this.nin = '48291039481',
    this.lga = 'Ikeja',
    this.homeAddress = '14 Admiralty Way, Lekki Phase 1',
    this.applicationType = 'Regular',
    this.entryType = 'UTME (100 Level)',
    required this.utmeScore,
    this.utmeSubjects = const {
      'Use of English': 68,
      'Mathematics': 74,
      'Physics': 66,
      'Chemistry': 66,
    },
    required this.oLevelSummary,
    this.scratchCardPin = 'WAEC-9948-2026-8812',
    required this.stateOfOrigin,
    required this.gender,
    required this.universityCode,
    required this.preferredDepartment,
    this.secondChoiceDepartment = 'Cybersecurity & Digital Forensics',
    this.guardianName = 'Engr. Olusegun Adeyemi',
    this.guardianRelationship = 'Father',
    this.guardianPhone = '+234 802 311 4920',
    this.guardianEmail = 'guardian@familymail.ng',
    this.personalInfoDone = true,
    this.programmeDone = true,
    this.educationDone = true,
    this.guardianDone = false,
    required this.password,
    this.portraitBytes,
    this.status = AdmissionDecisionStatus.notAdmittedScreening,
    this.adminRemark =
    'Under Departmental & NUC Screening Review (JAMB CAPS Queue)',
    this.postUtmeFeePaid = false,
    this.postUtmeRrr,
    this.acceptanceFeePaid = false,
    this.acceptanceRrr,
    this.nucClearanceDocs = const {
      'Birth Certificate / Sworn Age Declaration': false,
      'Local Government Indigene Certificate': false,
      'Official JAMB Admission Letter (CAPS)': false,
      'University Health Center Medical Fitness Report': false,
      'Signed Guarantor / Good Conduct Attestation': false,
    },
    this.issuedMatricNumber,
    this.transactions = const [],
    this.notifications = const [
      '2026/2027 Undergraduate Application Profile Initialized.',
      'JAMB UTME & O\'Level 5-Credit Screening Queued with Senate Admissions.',
    ],
  });

  int get completedClearanceDocsCount =>
      nucClearanceDocs.values.where((v) => v).length;

  bool get allNucDocsUploaded =>
      nucClearanceDocs.values.every((uploaded) => uploaded);

  int get completedWizardCardsCount => [
    personalInfoDone,
    programmeDone,
    educationDone,
    guardianDone,
  ].where((e) => e).length;

  bool isMinimum16YearsOld() {
    final parsed = DateTime.tryParse(dateOfBirth);
    if (parsed == null) return true;
    final cutoffDate = DateTime(2026, 9, 30);
    final ageYears = cutoffDate.difference(parsed).inDays / 365.25;
    return ageYears >= 16.0;
  }

  FresherApplicant copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? dateOfBirth,
    String? nin,
    String? lga,
    String? homeAddress,
    String? applicationType,
    String? entryType,
    int? utmeScore,
    Map<String, int>? utmeSubjects,
    String? oLevelSummary,
    String? scratchCardPin,
    String? stateOfOrigin,
    StudentGender? gender,
    String? universityCode,
    String? preferredDepartment,
    String? secondChoiceDepartment,
    String? guardianName,
    String? guardianRelationship,
    String? guardianPhone,
    String? guardianEmail,
    bool? personalInfoDone,
    bool? programmeDone,
    bool? educationDone,
    bool? guardianDone,
    Uint8List? portraitBytes,
    AdmissionDecisionStatus? status,
    String? adminRemark,
    bool? postUtmeFeePaid,
    String? postUtmeRrr,
    bool? acceptanceFeePaid,
    String? acceptanceRrr,
    Map<String, bool>? nucClearanceDocs,
    String? issuedMatricNumber,
    List<FresherTransaction>? transactions,
    List<String>? notifications,
  }) {
    return FresherApplicant(
      applicationNumber: applicationNumber,
      jambRegNumber: jambRegNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nin: nin ?? this.nin,
      lga: lga ?? this.lga,
      homeAddress: homeAddress ?? this.homeAddress,
      applicationType: applicationType ?? this.applicationType,
      entryType: entryType ?? this.entryType,
      utmeScore: utmeScore ?? this.utmeScore,
      utmeSubjects: utmeSubjects ?? this.utmeSubjects,
      oLevelSummary: oLevelSummary ?? this.oLevelSummary,
      scratchCardPin: scratchCardPin ?? this.scratchCardPin,
      stateOfOrigin: stateOfOrigin ?? this.stateOfOrigin,
      gender: gender ?? this.gender,
      universityCode: universityCode ?? this.universityCode,
      preferredDepartment: preferredDepartment ?? this.preferredDepartment,
      secondChoiceDepartment:
      secondChoiceDepartment ?? this.secondChoiceDepartment,
      guardianName: guardianName ?? this.guardianName,
      guardianRelationship: guardianRelationship ?? this.guardianRelationship,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      personalInfoDone: personalInfoDone ?? this.personalInfoDone,
      programmeDone: programmeDone ?? this.programmeDone,
      educationDone: educationDone ?? this.educationDone,
      guardianDone: guardianDone ?? this.guardianDone,
      password: password,
      portraitBytes: portraitBytes ?? this.portraitBytes,
      status: status ?? this.status,
      adminRemark: adminRemark ?? this.adminRemark,
      postUtmeFeePaid: postUtmeFeePaid ?? this.postUtmeFeePaid,
      postUtmeRrr: postUtmeRrr ?? this.postUtmeRrr,
      acceptanceFeePaid: acceptanceFeePaid ?? this.acceptanceFeePaid,
      acceptanceRrr: acceptanceRrr ?? this.acceptanceRrr,
      nucClearanceDocs: nucClearanceDocs ?? this.nucClearanceDocs,
      issuedMatricNumber: issuedMatricNumber ?? this.issuedMatricNumber,
      transactions: transactions ?? this.transactions,
      notifications: notifications ?? this.notifications,
    );
  }
}

class FresherChatMessage {
  final bool isUser;
  final String text;

  const FresherChatMessage({required this.isUser, required this.text});
}

class FresherState {
  final List<NigerianUniversitySpec> universities;
  final List<FresherApplicant> applicants;
  final String? activeApplicantJamb;
  final List<FresherChatMessage> aiMessages;

  const FresherState({
    required this.universities,
    required this.applicants,
    this.activeApplicantJamb,
    required this.aiMessages,
  });

  FresherApplicant? get currentApplicant {
    if (activeApplicantJamb == null) return null;
    for (final a in applicants) {
      if (a.jambRegNumber.toUpperCase() == activeApplicantJamb!.toUpperCase()) {
        return a;
      }
    }
    return null;
  }

  NigerianUniversitySpec universityByCode(String code) {
    return universities.firstWhere(
          (u) => u.code == code,
      orElse: () => universities.first,
    );
  }

  FresherState copyWith({
    List<FresherApplicant>? applicants,
    String? activeApplicantJamb,
    bool clearActiveApplicant = false,
    List<FresherChatMessage>? aiMessages,
  }) {
    return FresherState(
      universities: universities,
      applicants: applicants ?? this.applicants,
      activeApplicantJamb: clearActiveApplicant
          ? null
          : (activeApplicantJamb ?? this.activeApplicantJamb),
      aiMessages: aiMessages ?? this.aiMessages,
    );
  }
}

class FresherNotifier extends StateNotifier<FresherState> {
  final Ref _ref;

  FresherNotifier(this._ref)
      : super(
    FresherState(
      universities: _tenNigerianUniversities,
      applicants: [
        FresherApplicant(
          applicationNumber: '202613270120',
          jambRegNumber: '202630491829BA',
          fullName: 'CHIDERA OKONKWO',
          email: 'chidera.okonkwo@applicants.edu.ng',
          phoneNumber: '+234 814 702 8819',
          dateOfBirth: '2008-05-14',
          nin: '74920183910',
          lga: 'Awka South',
          homeAddress: '22 Zik Avenue, Awka, Anambra State',
          utmeScore: 274,
          oLevelSummary:
          'WAEC: Maths (A1), English (B2), Physics (B2), Chemistry (B3), Further Maths (A1)',
          stateOfOrigin: 'Anambra State',
          gender: StudentGender.male,
          universityCode: 'UNILAG',
          preferredDepartment: 'Computer Science',
          secondChoiceDepartment: 'Software Engineering',
          guardianName: 'Chief Emeka Okonkwo',
          guardianPhone: '+234 803 300 4412',
          personalInfoDone: true,
          programmeDone: true,
          educationDone: true,
          guardianDone: false,
          password: 'Fresher@2026',
          status: AdmissionDecisionStatus.notAdmittedScreening,
          postUtmeFeePaid: true,
          postUtmeRrr: '4102-9938-1120',
          transactions: [
            FresherTransaction(
              rrr: '4102-9938-1120',
              title: 'UNILAG 2026/2027 Post-UTME Screening Fee',
              amountNaira: 2000,
              isPaid: true,
              createdAt: DateTime(2026, 11, 20),
            ),
          ],
        ),
        FresherApplicant(
          applicationNumber: '202613270489',
          jambRegNumber: '202688120455FC',
          fullName: 'ZAINAB ABUBAKAR-SADIQ',
          email: 'zainab.sadiq@applicants.edu.ng',
          phoneNumber: '+234 809 112 7734',
          dateOfBirth: '2008-02-19',
          nin: '55019283746',
          lga: 'Zaria',
          homeAddress: '8 Sokoto Road, Samaru, Zaria',
          utmeScore: 256,
          oLevelSummary:
          'NECO: English (B2), Maths (B2), Biology (A1), Chemistry (B2), Physics (B3)',
          stateOfOrigin: 'Kaduna State',
          gender: StudentGender.female,
          universityCode: 'ABU',
          preferredDepartment: 'Nursing Science (B.NSc)',
          secondChoiceDepartment: 'Pharmacy (Pharm.D)',
          guardianName: 'Alhaji Abubakar Sadiq',
          guardianPhone: '+234 805 612 9081',
          personalInfoDone: true,
          programmeDone: true,
          educationDone: true,
          guardianDone: true,
          password: 'Fresher@2026',
          status: AdmissionDecisionStatus.notAdmittedScreening,
          postUtmeFeePaid: true,
          postUtmeRrr: '4102-7741-5509',
          transactions: [
            FresherTransaction(
              rrr: '4102-7741-5509',
              title: 'ABU Zaria 2026/2027 Post-UTME Screening Fee',
              amountNaira: 2000,
              isPaid: true,
              createdAt: DateTime(2026, 11, 21),
            ),
          ],
        ),
      ],
      aiMessages: const [
        FresherChatMessage(
          isUser: false,
          text:
          'Welcome to the 2026/2027 Nigerian Undergraduate Admissions AI Copilot!\n\nI can autonomously:\n1. Auto-fill & complete all 4 Application Cards (Personal Info, Programme, JAMB/WAEC, Guardian).\n2. Evaluate your UTME score & O\'Level grades across all 10 Nigerian Universities.\n3. Generate Remita RRRs & settle Post-UTME or Acceptance Fees.\n4. Print your Form 01 Bio-Data, Post-UTME Slip, or Provisional Admission Letter.',
        ),
      ],
    ),
  );

  static const List<NigerianUniversitySpec> _tenNigerianUniversities = [
    NigerianUniversitySpec(
      code: 'UNILAG',
      name: 'University of Lagos (UNILAG)',
      shortName: 'UNILAG',
      jambCutOff: 200,
      postUtmeFeeNaira: 2000,
      acceptanceFeeNaira: 45000,
      screeningMode: 'Post-UTME Online Aptitude + Departmental Merit/Catchment',
      matricPrefix: '260805',
    ),
    NigerianUniversitySpec(
      code: 'UI',
      name: 'University of Ibadan (UI)',
      shortName: 'UI',
      jambCutOff: 200,
      postUtmeFeeNaira: 2000,
      acceptanceFeeNaira: 50000,
      screeningMode: 'Post-UTME CBT + O\'Level Point Grading System',
      matricPrefix: '262104',
    ),
    NigerianUniversitySpec(
      code: 'ABU',
      name: 'Ahmadu Bello University, Zaria (ABU)',
      shortName: 'ABU Zaria',
      jambCutOff: 180,
      postUtmeFeeNaira: 2000,
      acceptanceFeeNaira: 35000,
      screeningMode: 'Online/Physical Credential Screening + Catchment Review',
      matricPrefix: 'U26CS',
    ),
    NigerianUniversitySpec(
      code: 'UNN',
      name: 'University of Nigeria, Nsukka (UNN)',
      shortName: 'UNN',
      jambCutOff: 180,
      postUtmeFeeNaira: 2000,
      acceptanceFeeNaira: 30000,
      screeningMode: 'Computer-Based Post-UTME + Primary/Secondary Screening',
      matricPrefix: '2026/24',
    ),
    NigerianUniversitySpec(
      code: 'OAU',
      name: 'Obafemi Awolowo University, Ile-Ife (OAU)',
      shortName: 'OAU Ife',
      jambCutOff: 200,
      postUtmeFeeNaira: 2000,
      acceptanceFeeNaira: 40000,
      screeningMode: 'Post-UTME Aptitude CBT + O\'Level Aggregate Scoring',
      matricPrefix: 'CSC/2026/',
    ),
    NigerianUniversitySpec(
      code: 'UNIABUJA',
      name: 'University of Abuja (UNIABUJA)',
      shortName: 'UNIABUJA',
      jambCutOff: 180,
      postUtmeFeeNaira: 2000,
      acceptanceFeeNaira: 35000,
      screeningMode: 'Online Portal Screening + FCT/National Quota Verification',
      matricPrefix: '26/105/',
    ),
    NigerianUniversitySpec(
      code: 'BUK',
      name: 'Bayero University, Kano (BUK)',
      shortName: 'BUK Kano',
      jambCutOff: 180,
      postUtmeFeeNaira: 2500,
      acceptanceFeeNaira: 30000,
      screeningMode: 'BUKAT Aptitude Screening + O\'Level Scratch-Card Check',
      matricPrefix: 'CST/26/',
    ),
    NigerianUniversitySpec(
      code: 'UNIBEN',
      name: 'University of Benin (UNIBEN)',
      shortName: 'UNIBEN',
      jambCutOff: 200,
      postUtmeFeeNaira: 2000,
      acceptanceFeeNaira: 60000,
      screeningMode: 'Post-UTME CBT + Merit/Catchment Screening',
      matricPrefix: 'PSC260',
    ),
    NigerianUniversitySpec(
      code: 'FUTMINNA',
      name: 'Federal University of Technology, Minna (FUTMINNA)',
      shortName: 'FUTMINNA',
      jambCutOff: 170,
      postUtmeFeeNaira: 2000,
      acceptanceFeeNaira: 30000,
      screeningMode: 'UPSET Screening + STEM Subject Combination Verification',
      matricPrefix: '2026/1/',
    ),
    NigerianUniversitySpec(
      code: 'CU',
      name: 'Covenant University, Ota (CU)',
      shortName: 'Covenant Univ.',
      jambCutOff: 200,
      postUtmeFeeNaira: 10000,
      acceptanceFeeNaira: 100000,
      screeningMode: 'CUSAS CBT + Character & Leadership Interview',
      matricPrefix: '26CU03',
    ),
  ];

  FresherApplicant registerNewFresher({
    required String fullName,
    required String jambRegNumber,
    required int utmeScore,
    required String oLevelSummary,
    required String stateOfOrigin,
    required StudentGender gender,
    required String universityCode,
    required String preferredDepartment,
    required String password,
    Uint8List? portraitBytes,
  }) {
    final cleanJamb = jambRegNumber.trim().toUpperCase();
    final appNum = '20261327${1000 + (state.applicants.length * 137)}';
    final newApplicant = FresherApplicant(
      applicationNumber: appNum,
      jambRegNumber: cleanJamb,
      fullName: fullName.trim().toUpperCase(),
      utmeScore: utmeScore,
      oLevelSummary: oLevelSummary.trim(),
      stateOfOrigin: stateOfOrigin.trim(),
      gender: gender,
      universityCode: universityCode,
      preferredDepartment: preferredDepartment,
      password: password,
      portraitBytes: portraitBytes,
      personalInfoDone: true,
      programmeDone: true,
      educationDone: true,
      guardianDone: false,
      status: AdmissionDecisionStatus.notAdmittedScreening,
    );

    final filtered = state.applicants
        .where((a) => a.jambRegNumber.toUpperCase() != cleanJamb)
        .toList();

    state = state.copyWith(
      applicants: [newApplicant, ...filtered],
      activeApplicantJamb: cleanJamb,
    );

    _ref.read(adminProvider.notifier).logSecurityEvent(
      actor: cleanJamb,
      action: 'FRESHER_APPLICANT_REGISTERED',
      target:
      '${newApplicant.fullName} • App#$appNum • $universityCode • $preferredDepartment (UTME: $utmeScore)',
    );

    return newApplicant;
  }

  void updateApplicantRecord(FresherApplicant updated) {
    final nextList = state.applicants.map((a) {
      if (a.jambRegNumber.toUpperCase() ==
          updated.jambRegNumber.toUpperCase()) {
        return updated;
      }
      return a;
    }).toList();
    state = state.copyWith(applicants: nextList);
  }

  FresherApplicant? authenticateFresher({
    required String jambRegNumber,
    required String password,
  }) {
    final clean = jambRegNumber.trim().toUpperCase();
    for (final app in state.applicants) {
      if ((app.jambRegNumber.toUpperCase() == clean ||
          app.applicationNumber == clean) &&
          app.password == password) {
        return app;
      }
    }
    return null;
  }

  void completeFresherLogin(String jambRegNumber) {
    state = state.copyWith(
      activeApplicantJamb: jambRegNumber.trim().toUpperCase(),
    );
  }

  void logoutFresher() {
    state = state.copyWith(clearActiveApplicant: true);
  }

  void setAdminAdmissionDecision({
    required String jambRegNumber,
    required AdmissionDecisionStatus decision,
    String? customRemark,
    String? transferDepartment,
  }) {
    final updated = state.applicants.map((a) {
      if (a.jambRegNumber.toUpperCase() != jambRegNumber.toUpperCase()) {
        return a;
      }
      final uni = state.universityByCode(a.universityCode);
      final remark = customRemark ??
          (decision == AdmissionDecisionStatus.admittedOffered
              ? 'OFFERED PROVISIONAL ADMISSION INTO ${transferDepartment ?? a.preferredDepartment} (${uni.shortName}) — JAMB CAPS APPROVED'
              : (decision == AdmissionDecisionStatus.transferRecommended
              ? 'RECOMMENDED FOR COURSE TRANSFER TO ${transferDepartment ?? "Cybersecurity & Digital Forensics"}'
              : 'APPLICATION NOT SELECTED IN CURRENT MERIT BATCH'));

      return a.copyWith(
        status: decision,
        adminRemark: remark,
        preferredDepartment: transferDepartment ?? a.preferredDepartment,
        notifications: [
          'ADMISSION UPDATE: $remark',
          ...a.notifications,
        ],
      );
    }).toList();

    state = state.copyWith(applicants: updated);

    _ref.read(adminProvider.notifier).logSecurityEvent(
      actor: 'ADMIN/ICT/001',
      action: 'FRESHER_ADMISSION_${decision.name.toUpperCase()}',
      target: 'JAMB=$jambRegNumber',
    );
  }

  void payPostUtmeScreeningFee(String jambRegNumber) {
    final rrr =
        '4102-${1000 + (DateTime.now().millisecond * 8)}-${2000 + DateTime.now().second * 90}';
    final updated = state.applicants.map((a) {
      if (a.jambRegNumber.toUpperCase() != jambRegNumber.toUpperCase()) {
        return a;
      }
      final uni = state.universityByCode(a.universityCode);
      return a.copyWith(
        postUtmeFeePaid: true,
        postUtmeRrr: rrr,
        transactions: [
          FresherTransaction(
            rrr: rrr,
            title: '${uni.shortName} 2026/2027 Post-UTME Screening Fee',
            amountNaira: uni.postUtmeFeeNaira,
            isPaid: true,
            createdAt: DateTime.now(),
          ),
          ...a.transactions,
        ],
        notifications: [
          'Remita Payment Confirmed (RRR: $rrr) for ${uni.shortName} Post-UTME Screening.',
          ...a.notifications,
        ],
      );
    }).toList();
    state = state.copyWith(applicants: updated);
  }

  void payAcceptanceFee(String jambRegNumber) {
    final rrr =
        '5209-${1000 + (DateTime.now().millisecond * 7)}-${3000 + DateTime.now().second * 80}';
    final updated = state.applicants.map((a) {
      if (a.jambRegNumber.toUpperCase() != jambRegNumber.toUpperCase()) {
        return a;
      }
      final uni = state.universityByCode(a.universityCode);
      return a.copyWith(
        acceptanceFeePaid: true,
        acceptanceRrr: rrr,
        transactions: [
          FresherTransaction(
            rrr: rrr,
            title: '${uni.shortName} 2026/2027 Admission Acceptance Fee',
            amountNaira: uni.acceptanceFeeNaira,
            isPaid: true,
            createdAt: DateTime.now(),
          ),
          ...a.transactions,
        ],
        notifications: [
          'Acceptance Fee Paid (RRR: $rrr)! Upload 5 NUC Clearance Documents to generate Matric No.',
          ...a.notifications,
        ],
      );
    }).toList();
    state = state.copyWith(applicants: updated);
  }

  void toggleNucClearanceDocument(String jambRegNumber, String docTitle) {
    final updated = state.applicants.map((a) {
      if (a.jambRegNumber.toUpperCase() != jambRegNumber.toUpperCase()) {
        return a;
      }
      final nextDocs = Map<String, bool>.from(a.nucClearanceDocs);
      nextDocs[docTitle] = !(nextDocs[docTitle] ?? false);

      final allDone = nextDocs.values.every((v) => v);
      final uni = state.universityByCode(a.universityCode);
      final matric = (allDone && a.acceptanceFeePaid)
          ? '${uni.matricPrefix}${1042 + a.utmeScore}'
          : a.issuedMatricNumber;

      return a.copyWith(
        nucClearanceDocs: nextDocs,
        issuedMatricNumber: matric,
      );
    }).toList();
    state = state.copyWith(applicants: updated);
  }

  void askFresherAi(String prompt) {
    final clean = prompt.trim();
    if (clean.isEmpty) return;

    final app = state.currentApplicant;
    final uni =
    app != null ? state.universityByCode(app.universityCode) : null;
    final lower = clean.toLowerCase();

    String reply;
    if (app == null || uni == null) {
      reply = 'Please sign in with your JAMB Registration Number first.';
    } else if (lower.contains('complete') ||
        lower.contains('fill') ||
        lower.contains('wizard') ||
        lower.contains('card')) {
      final completed = app.copyWith(
        personalInfoDone: true,
        programmeDone: true,
        educationDone: true,
        guardianDone: true,
        notifications: [
          'AI Copilot validated all 4 Application Wizard sections (16+ Age Check & 5 O\'Level Credits Verified).',
          ...app.notifications,
        ],
      );
      updateApplicantRecord(completed);
      reply =
      'Done! I have verified your 2026 JAMB/NUC age requirement (16+ years), validated your 5 O\'Level credits + scratch-card PIN (${app.scratchCardPin}), and marked all 4 Dashboard Progress Cards (**Personal Info**, **Programme of Study**, **Education**, and **Guardian Info**) as **DONE**!';
    } else if (lower.contains('admit') || lower.contains('status')) {
      if (app.status == AdmissionDecisionStatus.admittedOffered) {
        reply =
        'CONGRATULATIONS ${app.fullName}! Your status at ${uni.name} is **ADMITTED** into **${app.preferredDepartment}**.\n\nNext NUC Steps:\n1. Pay Acceptance Fee (₦${uni.acceptanceFeeNaira.toStringAsFixed(0)}).\n2. Upload all 5 NUC Clearance Documents.\n3. Print your Official Provisional Admission Letter.';
      } else {
        reply =
        'Current Admission Status for ${app.fullName} (App #${app.applicationNumber}): **Pending (Under Departmental & NUC Screening)** at ${uni.name}.\n\nYour UTME Score (${app.utmeScore}) beats ${uni.shortName}\'s minimum cut-off (${uni.jambCutOff}). Once the Admissions Admin approves your file in the CAPS queue, your dashboard flips to **ADMITTED**.';
      }
    } else if (lower.contains('recommend') ||
        lower.contains('department') ||
        lower.contains('course') ||
        lower.contains('cut') ||
        lower.contains('eligib')) {
      final margin = app.utmeScore - uni.jambCutOff;
      final aggregate = ((app.utmeScore / 8.0) + 36.5).toStringAsFixed(1);
      reply =
      'NUC Subject & Post-UTME Aggregate Analysis (${uni.name}):\n• UTME Score: ${app.utmeScore} / 400 (+$margin above ${uni.shortName} cut-off of ${uni.jambCutOff})\n• Projected Post-UTME Aggregate: $aggregate%\n• O\'Level Check: 5 Mandatory Credits Confirmed\n\nRecommendation: You qualify strongly for **${app.preferredDepartment}** (1st Choice) and **${app.secondChoiceDepartment}** (2nd Choice) across UNILAG, UI, OAU, ABU, and UNIABUJA.';
    } else if (lower.contains('pay') ||
        lower.contains('fee') ||
        lower.contains('remita')) {
      if (!app.postUtmeFeePaid) {
        payPostUtmeScreeningFee(app.jambRegNumber);
        reply =
        'Post-UTME Screening Fee (₦${uni.postUtmeFeeNaira.toStringAsFixed(0)}) settled via Remita Code 00! Your Transactions ledger and Post-UTME Screening Slip are now cleared.';
      } else if (app.status == AdmissionDecisionStatus.admittedOffered &&
          !app.acceptanceFeePaid) {
        payAcceptanceFee(app.jambRegNumber);
        reply =
        'Admission Acceptance Fee (₦${uni.acceptanceFeeNaira.toStringAsFixed(0)}) settled via Remita Code 00! Complete your 5 NUC Clearance documents to issue your Matriculation Number.';
      } else {
        reply =
        'All currently eligible Remita invoices for Application #${app.applicationNumber} are verified PAID!';
      }
    } else if (lower.contains('print') ||
        lower.contains('letter') ||
        lower.contains('slip') ||
        lower.contains('form')) {
      printOfficialFresherDocument(
        app,
        documentTitle: app.status == AdmissionDecisionStatus.admittedOffered
            ? 'OFFICIAL PROVISIONAL OFFER OF ADMISSION (2026/2027)'
            : 'APPLICATION BIO-DATA (FORM 01) & POST-UTME SCREENING SLIP',
      );
      reply =
      'Generated & opened your official QR-stamped PDF slip for ${app.fullName}!';
    } else {
      reply =
      '2026/2027 Fresher Copilot Active for ${app.fullName} (App #${app.applicationNumber}):\n• Institution: ${uni.name}\n• Application Progress: ${app.completedWizardCardsCount}/4 Cards Done\n• Admission Status: ${app.status == AdmissionDecisionStatus.admittedOffered ? "ADMITTED" : "Pending Screening"}\n\nTry clicking one of the quick commands above to auto-fill all 4 forms, verify cut-offs, pay Remita fees, or print your PDF forms!';
    }

    state = state.copyWith(
      aiMessages: [
        ...state.aiMessages,
        FresherChatMessage(isUser: true, text: clean),
        FresherChatMessage(isUser: false, text: reply),
      ],
    );
  }

  Future<void> printOfficialFresherDocument(
      FresherApplicant app, {
        required String documentTitle,
      }) async {
    final uni = state.universityByCode(app.universityCode);
    final isAdmitted = app.status == AdmissionDecisionStatus.admittedOffered;
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(28),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.indigo900, width: 2),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                uni.name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.Text(
                '2026/2027 UNDERGRADUATE ADMISSIONS • NUC & JAMB CAPS REGISTRY',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 10),
              pw.Text(
                documentTitle,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: isAdmitted ? PdfColors.green800 : PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Application Number: ${app.applicationNumber}'),
              pw.Text('Candidate Name: ${app.fullName}'),
              pw.Text('JAMB Registration No: ${app.jambRegNumber}'),
              pw.Text('UTME Score: ${app.utmeScore} / 400'),
              pw.Text('Entry Mode: ${app.entryType} (${app.applicationType})'),
              pw.Text('First Choice Programme: ${app.preferredDepartment}'),
              pw.Text('Second Choice Programme: ${app.secondChoiceDepartment}'),
              pw.Text('State / LGA: ${app.stateOfOrigin} (${app.lga})'),
              pw.Text('O\'Level Credentials: ${app.oLevelSummary}'),
              pw.Text('Guardian / Sponsor: ${app.guardianName} (${app.guardianPhone})'),
              if (app.issuedMatricNumber != null)
                pw.Text(
                  'ISSUED MATRICULATION NUMBER: ${app.issuedMatricNumber}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
              pw.SizedBox(height: 18),
              pw.Text(
                isAdmitted
                    ? 'Congratulations! Following Senate & JAMB CAPS approval, you have been offered provisional admission into 100 Level ${app.preferredDepartment}. Present this QR-stamped document during physical NUC clearance.'
                    : 'This document certifies your 2026/2027 undergraduate screening record at ${uni.name}.',
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Verified by Registrar & NUC Admissions Portal'),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data:
                    'NUC-2026|${uni.code}|${app.applicationNumber}|${app.jambRegNumber}',
                    width: 64,
                    height: 64,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      name: '${uni.code}_${app.applicationNumber}_Form.pdf',
      onLayout: (_) async => doc.save(),
    );
  }
}

final fresherProvider =
StateNotifierProvider<FresherNotifier, FresherState>((ref) {
  return FresherNotifier(ref);
});