import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/student_model.dart';
import '../../admin_console/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';

class UniversityCourse {
  final String code;
  final String title;
  final String department;
  final String level; // '100 Level' .. '600 Level'
  final int creditUnits;
  final String status; // 'C' (Compulsory), 'R' (Required), 'E' (Elective)
  final String prerequisite;
  final String timeSlot;

  const UniversityCourse({
    required this.code,
    required this.title,
    required this.department,
    required this.level,
    required this.creditUnits,
    required this.status,
    this.prerequisite = 'None',
    required this.timeSlot,
  });
}

class CareerRoadmapStage {
  final String phaseTitle;
  final String skillsAndCourses;
  final String deliverableProject;
  final String industryCertification;

  const CareerRoadmapStage({
    required this.phaseTitle,
    required this.skillsAndCourses,
    required this.deliverableProject,
    required this.industryCertification,
  });
}

class AcademicsState {
  final List<UniversityCourse> catalog;
  final Set<String> selectedCourseCodes;
  final String selectedDepartmentFilter;
  final String selectedLevelFilter;
  final List<CareerRoadmapStage> generatedRoadmap;
  final String aiAdvisorAdvice;

  const AcademicsState({
    required this.catalog,
    this.selectedCourseCodes = const {},
    this.selectedDepartmentFilter = 'Computer Science',
    this.selectedLevelFilter = '300 Level',
    this.generatedRoadmap = const [],
    this.aiAdvisorAdvice = '',
  });

  List<UniversityCourse> get activeFilteredCourses {
    return catalog
        .where((c) =>
    c.department == selectedDepartmentFilter &&
        c.level == selectedLevelFilter)
        .toList();
  }

  int get totalSelectedUnits {
    int sum = 0;
    for (final c in catalog) {
      if (selectedCourseCodes.contains(c.code) &&
          c.department == selectedDepartmentFilter &&
          c.level == selectedLevelFilter) {
        sum += c.creditUnits;
      }
    }
    return sum;
  }

  bool get isCreditLoadValid =>
      totalSelectedUnits >= 15 && totalSelectedUnits <= 24;

  AcademicsState copyWith({
    List<UniversityCourse>? catalog,
    Set<String>? selectedCourseCodes,
    String? selectedDepartmentFilter,
    String? selectedLevelFilter,
    List<CareerRoadmapStage>? generatedRoadmap,
    String? aiAdvisorAdvice,
  }) {
    return AcademicsState(
      catalog: catalog ?? this.catalog,
      selectedCourseCodes: selectedCourseCodes ?? this.selectedCourseCodes,
      selectedDepartmentFilter:
      selectedDepartmentFilter ?? this.selectedDepartmentFilter,
      selectedLevelFilter: selectedLevelFilter ?? this.selectedLevelFilter,
      generatedRoadmap: generatedRoadmap ?? this.generatedRoadmap,
      aiAdvisorAdvice: aiAdvisorAdvice ?? this.aiAdvisorAdvice,
    );
  }
}

class AcademicsNotifier extends StateNotifier<AcademicsState> {
  final Ref _ref;

  AcademicsNotifier(this._ref)
      : super(
    AcademicsState(
      catalog: _buildCompleteNucCatalog(),
      selectedCourseCodes: {
        'CSC 301',
        'CSC 303',
        'CSC 305',
        'CSC 307',
        'CSC 309',
      },
      aiAdvisorAdvice:
      'NUC Benchmark Check: 17 Compulsory/Required units selected for Computer Science (300 Level). Add CSC 399 (SIWES) to complete your 21-unit load without timetable clashes.',
      generatedRoadmap: _buildRoadmapForDepartment('Computer Science'),
    ),
  );

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

  void selectDepartmentAndLevel(String dept, {String? level}) {
    final validLevels = StudentAccount.validLevelsForDepartment(dept);
    final resolvedLevel =
    (level != null && validLevels.contains(level)) ? level : validLevels.first;

    final autoPreselect = state.catalog
        .where((c) =>
    c.department == dept &&
        c.level == resolvedLevel &&
        c.status == 'C')
        .map((c) => c.code)
        .toSet();

    state = state.copyWith(
      selectedDepartmentFilter: dept,
      selectedLevelFilter: resolvedLevel,
      selectedCourseCodes: autoPreselect,
      generatedRoadmap: _buildRoadmapForDepartment(dept),
      aiAdvisorAdvice:
      'AI Course Advisor synced for $dept ($resolvedLevel • Max ${validLevels.last}): Compulsory (C) NUC core courses pre-selected. Target 15–24 credit units.',
    );
  }

  void selectLevel(String level) {
    selectDepartmentAndLevel(state.selectedDepartmentFilter, level: level);
  }

  String? toggleCourse(UniversityCourse course) {
    final next = Set<String>.from(state.selectedCourseCodes);
    if (next.contains(course.code)) {
      next.remove(course.code);
      state = state.copyWith(selectedCourseCodes: next);
      return null;
    }

    for (final existing in state.activeFilteredCourses) {
      if (next.contains(existing.code) &&
          existing.timeSlot == course.timeSlot) {
        return 'Timetable Clash: ${course.code} conflicts with ${existing.code} (${course.timeSlot}).';
      }
    }

    if (state.totalSelectedUnits + course.creditUnits > 24) {
      return 'Credit Overload: Adding ${course.code} exceeds the 24-unit NUC Senate maximum.';
    }

    next.add(course.code);
    state = state.copyWith(selectedCourseCodes: next);
    return null;
  }

  void addCustomCourse(UniversityCourse course) {
    state = state.copyWith(catalog: [course, ...state.catalog]);
  }

  void submitCourseRegistration(StudentAccount student) {
    final activeCodes = state.activeFilteredCourses
        .where((c) => state.selectedCourseCodes.contains(c.code))
        .map((c) => c.code)
        .toList();

    // Seed initial score records so Admin/Lecturer Marking Console can grade them immediately
    final initialGrades = state.activeFilteredCourses
        .where((c) => activeCodes.contains(c.code))
        .map(
          (c) => CourseScoreRecord(
        courseCode: c.code,
        courseTitle: c.title,
        creditUnits: c.creditUnits,
        caScore: 24,
        examScore: 52,
        isPublished: false,
      ),
    )
        .toList();

    final updated = student.copyWith(
      department: state.selectedDepartmentFilter,
      level: state.selectedLevelFilter,
      registeredCourseCodes: activeCodes,
      courseGrades: initialGrades,
      courseFormApproved: true,
    );

    _ref.read(adminProvider.notifier).updateStudentRecord(updated);
    _ref.read(authProvider.notifier).syncUpdatedUser(updated);
    _ref.read(adminProvider.notifier).logSecurityEvent(
      actor: student.matricNumber,
      action: 'NUC_COURSE_FORM_APPROVED',
      target:
      '${state.selectedDepartmentFilter} (${state.selectedLevelFilter}) • ${state.totalSelectedUnits} Units',
    );
  }

  static List<CareerRoadmapStage> _buildRoadmapForDepartment(String dept) {
    if (dept.contains('Medicine') ||
        dept.contains('Pharmacy') ||
        dept.contains('Nursing')) {
      return const [
        CareerRoadmapStage(
          phaseTitle: 'Phase 1 • Pre-Clinical & Basic Medical Sciences (100L–200L)',
          skillsAndCourses: 'Gross Anatomy, Medical Biochemistry, Human Physiology, Organic Chemistry',
          deliverableProject: 'Clinical Case-Study Digital Portfolio & Vital Signs Audit',
          industryCertification: 'Basic Life Support (BLS) & Red Cross Certification',
        ),
        CareerRoadmapStage(
          phaseTitle: 'Phase 2 • Pathology, Pharmacology & Ward Postings (300L–400L)',
          skillsAndCourses: 'Systemic Pathology, Clinical Pharmacology, Medical Microbiology & Clerkships',
          deliverableProject: 'Rural Primary Healthcare & Epidemiological Field Report',
          industryCertification: 'Advanced Cardiovascular Life Support (ACLS)',
        ),
        CareerRoadmapStage(
          phaseTitle: 'Phase 3 • Senior Clinical Clerkships & Board Licensure (500L–600L)',
          skillsAndCourses: 'Internal Medicine, Surgery, Obstetrics/Gynaecology, Paediatrics & Dissertation',
          deliverableProject: 'Final Year Clinical Research Dissertation',
          industryCertification: 'MDCN / PCN / NMCN Council Induction & Housemanship',
        ),
      ];
    }

    if (dept.contains('Cybersecurity') ||
        dept.contains('Computer') ||
        dept.contains('Software')) {
      return const [
        CareerRoadmapStage(
          phaseTitle: 'Phase 1 • Computing & Mathematical Foundations (100L–200L)',
          skillsAndCourses: 'Python/Java/Dart, Data Structures & Algorithms, Discrete Math, Computer Architecture',
          deliverableProject: 'Full-Stack Campus Utility App & Packet Tracer VLAN Lab',
          industryCertification: 'Cisco CCNA / AWS Cloud Practitioner',
        ),
        CareerRoadmapStage(
          phaseTitle: 'Phase 2 • Systems Engineering, Security & SIWES (300L)',
          skillsAndCourses: 'Operating Systems, SIEM/SOC Defense, Database Systems, Ethical Hacking & SIWES',
          deliverableProject: '6-Month SIWES Enterprise SOC or Mobile App Capstone',
          industryCertification: 'CompTIA Security+ / Blue Team Level 1 (BTL1)',
        ),
        CareerRoadmapStage(
          phaseTitle: 'Phase 3 • Distributed Cloud, AI & Final Thesis (400L–500L)',
          skillsAndCourses: 'Cloud Microservices, Deep Learning, Threat Intelligence & Final Year Thesis',
          deliverableProject: 'Production SaaS or AI Forensic Verification Platform',
          industryCertification: 'AWS Solutions Architect / Certified Ethical Hacker (CEH)',
        ),
      ];
    }

    return [
      CareerRoadmapStage(
        phaseTitle: 'Phase 1 • Core Foundations & Quantitative Methods (100L–200L)',
        skillsAndCourses: '$dept Core Principles, Applied Statistics, Commercial Law & Business Computing',
        deliverableProject: 'Sector Case Study & Quantitative Financial/Design Model',
        industryCertification: 'Google Data Analytics / Microsoft Office Specialist',
      ),
      CareerRoadmapStage(
        phaseTitle: 'Phase 2 • Professional Practice & Industrial Attachment (300L)',
        skillsAndCourses: 'Advanced Domain Systems, Research Methodology, Entrepreneurship & SIWES',
        deliverableProject: 'Industrial Field Report & Enterprise Strategy Blueprint',
        industryCertification: 'COREN / ICAN / NIM / NIPR Student Membership',
      ),
      CareerRoadmapStage(
        phaseTitle: 'Phase 3 • Executive Specialization & Final Dissertation (400L–500L)',
        skillsAndCourses: 'Strategic Policy, Emerging Technologies & Final Year Research Project',
        deliverableProject: 'Final Year Empirical Dissertation & Venture Pitch',
        industryCertification: 'Chartered Professional Examinations & NYSC Readiness',
      ),
    ];
  }

  /// Helper to compactly seed courses per department & level
  static List<UniversityCourse> _lvl(
      String dept,
      String level,
      List<(String, String, int, String, String)> rows,
      ) {
    return rows
        .map(
          (r) => UniversityCourse(
        code: r.$1,
        title: r.$2,
        department: dept,
        level: level,
        creditUnits: r.$3,
        status: r.$4,
        timeSlot: r.$5,
      ),
    )
        .toList();
  }

  /// Complete NUC-Standard Course Catalog across all 12 Departments and every level (100L-600L)
  static List<UniversityCourse> _buildCompleteNucCatalog() {
    return [
      // =========================================================================
      // 1. MEDICINE & SURGERY (MBBS) — 100L to 600L (6+ courses per level)
      // =========================================================================
      ..._lvl('Medicine & Surgery (MBBS)', '100 Level', [
        ('GST 101', 'Use of English & Communication I', 2, 'C', 'Mon 08:00–10:00'),
        ('BIO 101', 'General Biology & Cell Genetics', 4, 'C', 'Mon 10:00–12:00'),
        ('CHM 101', 'Organic & Physical Chemistry', 4, 'C', 'Tue 08:00–10:00'),
        ('PHY 101', 'General Physics for Life Sciences', 3, 'C', 'Wed 09:00–11:00'),
        ('MTH 101', 'Elementary Mathematics I', 3, 'R', 'Thu 09:00–11:00'),
        ('GST 103', 'Nigerian Peoples & Culture', 2, 'R', 'Fri 10:00–12:00'),
        ('MED 102', 'Introduction to Medical Ethics', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Medicine & Surgery (MBBS)', '200 Level', [
        ('ANA 201', 'Gross Anatomy of Upper & Lower Limbs', 4, 'C', 'Mon 08:00–10:00'),
        ('PHS 201', 'Excitable Tissues & Autonomic Physiology', 4, 'C', 'Tue 08:00–10:00'),
        ('BCH 201', 'Chemistry of Biomolecules & Enzymology', 4, 'C', 'Wed 08:00–10:00'),
        ('ANA 203', 'General Histology & Embryology', 3, 'C', 'Thu 09:00–11:00'),
        ('PHS 203', 'Blood & Cardiovascular Physiology', 3, 'R', 'Fri 09:00–11:00'),
        ('GST 201', 'Entrepreneurship & Innovation', 2, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Medicine & Surgery (MBBS)', '300 Level', [
        ('PAT 301', 'General Pathology & Cellular Injury', 4, 'C', 'Mon 08:00–10:00'),
        ('PHM 301', 'Principles of Pharmacology & Chemotherapy', 4, 'C', 'Tue 08:00–10:00'),
        ('MCB 301', 'Medical Microbiology & Parasitology', 4, 'C', 'Wed 08:00–10:00'),
        ('ANA 301', 'Neuroanatomy & Head/Neck Anatomy', 3, 'C', 'Thu 09:00–11:00'),
        ('PHS 301', 'Renal & Respiratory Physiology', 3, 'R', 'Fri 09:00–11:00'),
        ('COM 301', 'Biostatistics & Epidemiology', 2, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Medicine & Surgery (MBBS)', '400 Level', [
        ('PAT 401', 'Systemic Pathology & Histopathology', 4, 'C', 'Mon 08:00–10:00'),
        ('PHM 403', 'Systemic Pharmacology & Toxicology', 4, 'C', 'Tue 08:00–10:00'),
        ('MED 401', 'Introductory Clinical Medicine & Clerkship', 4, 'C', 'Wed 08:00–10:00'),
        ('SUR 401', 'Principles of Surgery & Wound Healing', 4, 'C', 'Thu 09:00–11:00'),
        ('COM 401', 'Primary Health Care & Community Posting', 3, 'R', 'Fri 09:00–11:00'),
        ('RAD 401', 'Clinical Radiology & Imaging', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Medicine & Surgery (MBBS)', '500 Level', [
        ('OBG 501', 'Obstetrics & Antenatal Care', 4, 'C', 'Mon 08:00–10:00'),
        ('PAE 501', 'Paediatrics & Child Health', 4, 'C', 'Tue 08:00–10:00'),
        ('PSY 501', 'Clinical Psychiatry & Mental Health', 3, 'C', 'Wed 08:00–10:00'),
        ('OPH 501', 'Ophthalmology & ENT Posting', 3, 'R', 'Thu 09:00–11:00'),
        ('SUR 503', 'Orthopaedic & Trauma Surgery', 3, 'R', 'Fri 09:00–11:00'),
        ('MED 503', 'Infectious Diseases & Dermatology', 3, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Medicine & Surgery (MBBS)', '600 Level', [
        ('MED 601', 'Senior Internal Medicine Clerkship', 4, 'C', 'Mon 08:00–10:00'),
        ('SUR 601', 'Senior General & Subspecialty Surgery', 4, 'C', 'Tue 08:00–10:00'),
        ('OBG 603', 'Gynaecology & Reproductive Health', 4, 'C', 'Wed 08:00–10:00'),
        ('PAE 603', 'Neonatology & Paediatric Emergencies', 4, 'C', 'Thu 09:00–11:00'),
        ('COM 601', 'Rural Community Health Posting', 3, 'R', 'Fri 09:00–11:00'),
        ('MED 699', 'Clinical Research Dissertation', 4, 'C', 'Fri 14:00–16:00'),
      ]),

      // =========================================================================
      // 2. PHARMACY (PHARM.D) — 100L to 600L (5-7 courses per level)
      // =========================================================================
      ..._lvl('Pharmacy (Pharm.D)', '100 Level', [
        ('GST 101', 'Communication in English', 2, 'C', 'Mon 08:00–10:00'),
        ('CHM 101', 'General Chemistry I', 4, 'C', 'Mon 10:00–12:00'),
        ('BIO 101', 'Cell Biology & Genetics', 4, 'C', 'Tue 09:00–11:00'),
        ('PHY 101', 'Mechanics & Properties of Matter', 3, 'C', 'Wed 09:00–11:00'),
        ('MTH 101', 'Algebra & Trigonometry', 3, 'R', 'Thu 09:00–11:00'),
        ('PHM 102', 'Orientation to Pharmacy Profession', 2, 'R', 'Fri 10:00–12:00'),
        ('GST 105', 'Philosophy & Logic', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Pharmacy (Pharm.D)', '200 Level', [
        ('PCH 201', 'Pharmaceutical Inorganic Chemistry', 4, 'C', 'Mon 08:00–10:00'),
        ('PCE 201', 'Physical Pharmaceutics I', 4, 'C', 'Tue 08:00–10:00'),
        ('PCG 201', 'Introductory Pharmacognosy & Medicinal Plants', 3, 'C', 'Wed 09:00–11:00'),
        ('PHS 202', 'Human Physiology for Pharmacy', 3, 'C', 'Thu 09:00–11:00'),
        ('ANA 202', 'Basic Human Anatomy', 3, 'R', 'Fri 09:00–11:00'),
        ('PMB 201', 'Pharmaceutical Microbiology I', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Pharmacy (Pharm.D)', '300 Level', [
        ('PCH 301', 'Medicinal & Organic Pharmaceutical Chemistry', 4, 'C', 'Mon 08:00–10:00'),
        ('PCE 303', 'Dosage Form Design & Formulation', 4, 'C', 'Tue 08:00–10:00'),
        ('PCG 303', 'Phytochemistry & Natural Products', 3, 'C', 'Wed 09:00–11:00'),
        ('PCL 301', 'Autonomic & Cardiovascular Pharmacology', 4, 'C', 'Thu 09:00–11:00'),
        ('PMB 303', 'Sterile Products & Preservation', 3, 'R', 'Fri 09:00–11:00'),
        ('BCH 302', 'Clinical Biochemistry', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Pharmacy (Pharm.D)', '400 Level', [
        ('PCL 401', 'Chemotherapy & Endocrine Pharmacology', 4, 'C', 'Mon 08:00–10:00'),
        ('PCE 405', 'Biopharmaceutics & Pharmacokinetics', 4, 'C', 'Tue 08:00–10:00'),
        ('PCH 403', 'Pharmaceutical Analysis & Quality Control', 3, 'C', 'Wed 09:00–11:00'),
        ('CLP 401', 'Pathophysiology & Therapeutics I', 4, 'C', 'Thu 09:00–11:00'),
        ('PAD 401', 'Pharmacy Management & Jurisprudence', 3, 'R', 'Fri 09:00–11:00'),
        ('PCG 405', 'Herbal Medicine Standardization', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Pharmacy (Pharm.D)', '500 Level', [
        ('CLP 501', 'Clinical Pharmacy & Pharmacotherapeutics II', 4, 'C', 'Mon 08:00–10:00'),
        ('PCE 501', 'Industrial Pharmacy & Manufacturing', 4, 'C', 'Tue 08:00–10:00'),
        ('PCL 503', 'Clinical Toxicology & Poison Management', 3, 'C', 'Wed 09:00–11:00'),
        ('CLP 503', 'Hospital & Community Pharmacy Clerkship', 4, 'C', 'Thu 09:00–11:00'),
        ('PAD 503', 'Pharmacoeconomics & Drug Policy', 3, 'R', 'Fri 09:00–11:00'),
        ('PHM 505', 'Drug Information & Literature Evaluation', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Pharmacy (Pharm.D)', '600 Level', [
        ('CLP 601', 'Advanced Clinical Clerkship (Internal Medicine)', 4, 'C', 'Mon 08:00–10:00'),
        ('CLP 603', 'Paediatric & Geriatric Pharmacotherapy', 4, 'C', 'Tue 08:00–10:00'),
        ('CLP 605', 'Oncology & Critical Care Pharmacy', 4, 'C', 'Wed 09:00–11:00'),
        ('PAD 601', 'Regulatory Affairs & NAFDAC Compliance', 3, 'R', 'Thu 09:00–11:00'),
        ('PHM 699', 'Pharm.D Clinical Research Project', 4, 'C', 'Fri 10:00–12:00'),
      ]),

      // =========================================================================
      // 3. NURSING SCIENCE (B.NSC) — 100L to 500L (5-7 courses per level)
      // =========================================================================
      ..._lvl('Nursing Science (B.NSc)', '100 Level', [
        ('GST 101', 'Use of English', 2, 'C', 'Mon 08:00–10:00'),
        ('BIO 101', 'General Biology', 4, 'C', 'Mon 10:00–12:00'),
        ('CHM 101', 'General Chemistry', 4, 'C', 'Tue 09:00–11:00'),
        ('PHY 101', 'General Physics', 3, 'C', 'Wed 09:00–11:00'),
        ('NSC 102', 'Foundations of Nursing Practice', 3, 'C', 'Thu 09:00–11:00'),
        ('PSY 101', 'Developmental Psychology', 2, 'R', 'Fri 10:00–12:00'),
        ('SOC 101', 'Medical Sociology', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Nursing Science (B.NSc)', '200 Level', [
        ('NSC 201', 'Fundamentals of Nursing & Bedside Care', 4, 'C', 'Mon 08:00–10:00'),
        ('ANA 204', 'Systemic Anatomy for Nurses', 4, 'C', 'Tue 08:00–10:00'),
        ('PHS 204', 'Human Physiology for Nurses', 4, 'C', 'Wed 09:00–11:00'),
        ('BCH 204', 'Nursing Biochemistry & Nutrition', 3, 'R', 'Thu 09:00–11:00'),
        ('NSC 203', 'Health Assessment & Physical Examination', 3, 'C', 'Fri 09:00–11:00'),
        ('MCB 204', 'Microbiology & Infection Control', 2, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Nursing Science (B.NSc)', '300 Level', [
        ('NSC 301', 'Medical-Surgical Nursing I', 4, 'C', 'Mon 08:00–10:00'),
        ('NSC 303', 'Maternal & Child Health Nursing I', 4, 'C', 'Tue 08:00–10:00'),
        ('NSC 305', 'Mental Health & Psychiatric Nursing', 3, 'C', 'Wed 09:00–11:00'),
        ('PHM 304', 'Clinical Pharmacology for Nurses', 3, 'C', 'Thu 09:00–11:00'),
        ('NSC 307', 'Community Health Nursing I', 3, 'R', 'Fri 09:00–11:00'),
        ('NSC 309', 'Nursing Informatics & Ethics', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Nursing Science (B.NSc)', '400 Level', [
        ('NSC 401', 'Medical-Surgical Nursing II (Critical Care)', 4, 'C', 'Mon 08:00–10:00'),
        ('NSC 403', 'Midwifery & Obstetric Nursing Practicum', 4, 'C', 'Tue 08:00–10:00'),
        ('NSC 405', 'Paediatric Nursing & Immunization', 3, 'C', 'Wed 09:00–11:00'),
        ('NSC 407', 'Nursing Research Methodology & Biostatistics', 3, 'C', 'Thu 09:00–11:00'),
        ('NSC 409', 'Epidemiology & Disease Surveillance', 3, 'R', 'Fri 09:00–11:00'),
        ('NSC 411', 'Oncology & Palliative Nursing', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Nursing Science (B.NSc)', '500 Level', [
        ('NSC 501', 'Nursing Leadership & Ward Management', 4, 'C', 'Mon 08:00–10:00'),
        ('NSC 503', 'Advanced Community & Public Health Nursing', 4, 'C', 'Tue 08:00–10:00'),
        ('NSC 505', 'Emergency & Trauma Nursing Practicum', 4, 'C', 'Wed 09:00–11:00'),
        ('NSC 507', 'Health Economics & Policy in Nursing', 3, 'R', 'Thu 09:00–11:00'),
        ('NSC 599', 'B.NSc Research Project & Seminar', 4, 'C', 'Fri 10:00–12:00'),
      ]),

      // =========================================================================
      // 4. SOFTWARE ENGINEERING — 100L to 500L (5-7 courses per level)
      // =========================================================================
      ..._lvl('Software Engineering', '100 Level', [
        ('COS 101', 'Introduction to Computing Sciences', 3, 'C', 'Mon 08:00–10:00'),
        ('MTH 101', 'Elementary Mathematics I', 3, 'C', 'Mon 10:00–12:00'),
        ('PHY 101', 'General Physics I', 3, 'C', 'Tue 09:00–11:00'),
        ('GST 101', 'Communication in English', 2, 'C', 'Wed 09:00–11:00'),
        ('SEN 102', 'Problem Solving & Algorithmic Thinking', 3, 'C', 'Thu 09:00–11:00'),
        ('STA 111', 'Descriptive Statistics', 3, 'R', 'Fri 10:00–12:00'),
        ('GST 107', 'Nigerian History & Culture', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Software Engineering', '200 Level', [
        ('SEN 201', 'Introduction to Software Engineering', 3, 'C', 'Mon 08:00–10:00'),
        ('CSC 201', 'Object-Oriented Programming (Java/Dart)', 4, 'C', 'Tue 08:00–10:00'),
        ('CSC 203', 'Data Structures & Algorithms', 4, 'C', 'Wed 09:00–11:00'),
        ('SEN 203', 'Software Requirements Engineering', 3, 'C', 'Thu 09:00–11:00'),
        ('MTH 201', 'Discrete Structures & Logic', 3, 'R', 'Fri 09:00–11:00'),
        ('CSC 205', 'Computer Architecture & Organization', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Software Engineering', '300 Level', [
        ('SEN 301', 'Software Architecture & Design Patterns', 4, 'C', 'Mon 08:00–10:00'),
        ('SEN 303', 'Web & Mobile Application Development', 4, 'C', 'Tue 08:00–10:00'),
        ('CSC 301', 'Database Management Systems (SQL/NoSQL)', 3, 'C', 'Wed 09:00–11:00'),
        ('SEN 305', 'Software Testing & Quality Assurance', 3, 'C', 'Thu 09:00–11:00'),
        ('CSC 305', 'Operating Systems & Concurrency', 3, 'R', 'Fri 09:00–11:00'),
        ('ENT 301', 'Tech Entrepreneurship & Venture Creation', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Software Engineering', '400 Level', [
        ('SEN 401', 'Agile Project Management & DevOps', 3, 'C', 'Mon 08:00–10:00'),
        ('SEN 403', 'Human-Computer Interaction & UI/UX', 3, 'C', 'Tue 08:00–10:00'),
        ('SEN 405', 'Cloud-Native Microservices & Containers', 4, 'C', 'Wed 09:00–11:00'),
        ('SEN 407', 'Secure Software Development Lifecycle', 3, 'R', 'Thu 09:00–11:00'),
        ('SEN 499', 'SIWES Industrial Training Report (6 Months)', 6, 'C', 'Fri 09:00–11:00'),
      ]),
      ..._lvl('Software Engineering', '500 Level', [
        ('SEN 501', 'Enterprise Software Systems & ERP', 4, 'C', 'Mon 08:00–10:00'),
        ('SEN 503', 'AI-Driven Software Engineering & MLOps', 4, 'C', 'Tue 08:00–10:00'),
        ('SEN 505', 'Software Metrics, Maintenance & Evolution', 3, 'R', 'Wed 09:00–11:00'),
        ('SEN 507', 'Distributed Systems & Fault Tolerance', 3, 'C', 'Thu 09:00–11:00'),
        ('SEN 599', 'Final Year Software Engineering Capstone', 6, 'C', 'Fri 10:00–12:00'),
      ]),

      // =========================================================================
      // 5. ELECTRICAL & ELECTRONICS ENGINEERING — 100L to 500L (5-7 courses/lvl)
      // =========================================================================
      ..._lvl('Electrical & Electronics Engineering', '100 Level', [
        ('MTH 101', 'Calculus & Algebra', 3, 'C', 'Mon 08:00–10:00'),
        ('PHY 101', 'Mechanics & Thermal Physics', 3, 'C', 'Mon 10:00–12:00'),
        ('CHM 101', 'Engineering Chemistry', 3, 'C', 'Tue 09:00–11:00'),
        ('GET 101', 'Engineer in Society', 2, 'R', 'Wed 09:00–11:00'),
        ('GET 102', 'Engineering Graphics & CAD', 3, 'C', 'Thu 09:00–11:00'),
        ('GST 101', 'Use of English', 2, 'C', 'Fri 10:00–12:00'),
        ('COS 101', 'Computing for Engineers', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Electrical & Electronics Engineering', '200 Level', [
        ('GET 201', 'Applied Mechanics & Strength of Materials', 3, 'C', 'Mon 08:00–10:00'),
        ('EEE 201', 'Fundamentals of Electrical Engineering I', 4, 'C', 'Tue 08:00–10:00'),
        ('EEE 203', 'Basic Electronics & Semiconductor Devices', 3, 'C', 'Wed 09:00–11:00'),
        ('MTH 202', 'Differential Equations & Vector Analysis', 3, 'C', 'Thu 09:00–11:00'),
        ('GET 203', 'Workshop Practice & Fabrication', 2, 'R', 'Fri 09:00–11:00'),
        ('EEE 205', 'Electric Circuit Theory', 3, 'C', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Electrical & Electronics Engineering', '300 Level', [
        ('EEE 301', 'Electromagnetic Field Theory', 3, 'C', 'Mon 08:00–10:00'),
        ('EEE 303', 'Analogue & Digital Electronics', 4, 'C', 'Tue 08:00–10:00'),
        ('EEE 305', 'Electrical Machines & Transformers', 4, 'C', 'Wed 09:00–11:00'),
        ('EEE 307', 'Signals, Systems & Measurement', 3, 'C', 'Thu 09:00–11:00'),
        ('EEE 309', 'Microprocessors & Embedded Systems', 3, 'R', 'Fri 09:00–11:00'),
        ('GET 301', 'Engineering Mathematics III', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Electrical & Electronics Engineering', '400 Level', [
        ('EEE 401', 'Control Systems Engineering', 4, 'C', 'Mon 08:00–10:00'),
        ('EEE 403', 'Power Systems Generation & Transmission', 4, 'C', 'Tue 08:00–10:00'),
        ('EEE 405', 'Digital Communication Principles', 3, 'C', 'Wed 09:00–11:00'),
        ('EEE 407', 'Power Electronics & Drives', 3, 'R', 'Thu 09:00–11:00'),
        ('EEE 499', 'SIWES Industrial Attachment (6 Months)', 6, 'C', 'Fri 09:00–11:00'),
      ]),
      ..._lvl('Electrical & Electronics Engineering', '500 Level', [
        ('EEE 501', 'High Voltage & Power System Protection', 4, 'C', 'Mon 08:00–10:00'),
        ('EEE 503', 'Renewable Energy & Smart Grid Systems', 4, 'C', 'Tue 08:00–10:00'),
        ('EEE 505', 'Digital Signal Processing (DSP)', 3, 'C', 'Wed 09:00–11:00'),
        ('EEE 507', 'Telecommunications & Fiber Optics', 3, 'E', 'Thu 09:00–11:00'),
        ('EEE 599', 'Final Year Engineering Design Project', 6, 'C', 'Fri 10:00–12:00'),
      ]),

      // =========================================================================
      // 6. MECHANICAL ENGINEERING — 100L to 500L (5-7 courses per level)
      // =========================================================================
      ..._lvl('Mechanical Engineering', '100 Level', [
        ('MTH 101', 'Elementary Mathematics I', 3, 'C', 'Mon 08:00–10:00'),
        ('PHY 101', 'General Physics I', 3, 'C', 'Mon 10:00–12:00'),
        ('CHM 101', 'General Chemistry I', 3, 'C', 'Tue 09:00–11:00'),
        ('GET 101', 'Engineer in Society', 2, 'R', 'Wed 09:00–11:00'),
        ('GET 102', 'Technical Drawing & SolidWorks', 3, 'C', 'Thu 09:00–11:00'),
        ('GST 101', 'Communication in English', 2, 'C', 'Fri 10:00–12:00'),
        ('STA 111', 'Engineering Statistics', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Mechanical Engineering', '200 Level', [
        ('MEE 201', 'Engineering Thermodynamics I', 4, 'C', 'Mon 08:00–10:00'),
        ('MEE 203', 'Fluid Mechanics I', 4, 'C', 'Tue 08:00–10:00'),
        ('GET 201', 'Statics & Dynamics', 3, 'C', 'Wed 09:00–11:00'),
        ('GET 203', 'Workshop Technology & Machining', 2, 'R', 'Thu 09:00–11:00'),
        ('MTH 202', 'Mathematical Methods II', 3, 'C', 'Fri 09:00–11:00'),
        ('MEE 205', 'Engineering Metallurgy & Materials', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Mechanical Engineering', '300 Level', [
        ('MEE 301', 'Mechanics of Machines & Kinematics', 4, 'C', 'Mon 08:00–10:00'),
        ('MEE 303', 'Heat & Mass Transfer', 4, 'C', 'Tue 08:00–10:00'),
        ('MEE 305', 'Machine Design I', 3, 'C', 'Wed 09:00–11:00'),
        ('MEE 307', 'Applied Thermodynamics II', 3, 'C', 'Thu 09:00–11:00'),
        ('MEE 309', 'Fluid Mechanics II & Hydraulics', 3, 'R', 'Fri 09:00–11:00'),
        ('GET 301', 'Numerical Methods in Engineering', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Mechanical Engineering', '400 Level', [
        ('MEE 401', 'Manufacturing & Production Engineering', 4, 'C', 'Mon 08:00–10:00'),
        ('MEE 403', 'Mechanical Vibrations & Acoustics', 3, 'C', 'Tue 08:00–10:00'),
        ('MEE 405', 'Internal Combustion Engines & Automotive', 4, 'C', 'Wed 09:00–11:00'),
        ('MEE 407', 'Refrigeration & Air Conditioning', 3, 'E', 'Thu 09:00–11:00'),
        ('MEE 499', 'SIWES Industrial Training (6 Months)', 6, 'C', 'Fri 09:00–11:00'),
      ]),
      ..._lvl('Mechanical Engineering', '500 Level', [
        ('MEE 501', 'Robotics, Mechatronics & Automation', 4, 'C', 'Mon 08:00–10:00'),
        ('MEE 503', 'Computer-Aided Design & Manufacturing (CAD/CAM)', 4, 'C', 'Tue 08:00–10:00'),
        ('MEE 505', 'Power Plant & Energy Engineering', 3, 'C', 'Wed 09:00–11:00'),
        ('MEE 507', 'Industrial Safety & Maintenance Engineering', 3, 'R', 'Thu 09:00–11:00'),
        ('MEE 599', 'Final Year Mechanical Design Thesis', 6, 'C', 'Fri 10:00–12:00'),
      ]),

      // =========================================================================
      // 7. COMPUTER SCIENCE — 100L to 400L (6-7 courses per level)
      // =========================================================================
      ..._lvl('Computer Science', '100 Level', [
        ('COS 101', 'Introduction to Computer Science', 3, 'C', 'Mon 08:00–10:00'),
        ('COS 102', 'Problem Solving in Python', 3, 'C', 'Mon 10:00–12:00'),
        ('MTH 101', 'Elementary Mathematics I', 3, 'C', 'Tue 09:00–11:00'),
        ('PHY 101', 'General Physics I', 3, 'C', 'Wed 09:00–11:00'),
        ('STA 111', 'Probability & Statistics I', 3, 'R', 'Thu 09:00–11:00'),
        ('GST 101', 'Use of English', 2, 'C', 'Fri 10:00–12:00'),
        ('GST 103', 'Nigerian Peoples & Culture', 2, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Computer Science', '200 Level', [
        ('CSC 201', 'Computer Programming II (Java/C++)', 4, 'C', 'Mon 08:00–10:00'),
        ('CSC 203', 'Data Structures & Algorithms', 4, 'C', 'Tue 08:00–10:00'),
        ('CSC 205', 'Digital Logic Design & Computer Architecture', 3, 'C', 'Wed 09:00–11:00'),
        ('MTH 201', 'Discrete Mathematics', 3, 'C', 'Thu 09:00–11:00'),
        ('CSC 207', 'Systems Analysis & Design', 3, 'R', 'Fri 09:00–11:00'),
        ('ENT 201', 'Entrepreneurship Studies', 2, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Computer Science', '300 Level', [
        ('CSC 301', 'Operating Systems', 4, 'C', 'Mon 08:00–10:00'),
        ('CSC 303', 'Database Design & Management', 4, 'C', 'Tue 08:00–10:00'),
        ('CSC 305', 'Compiler Construction', 3, 'C', 'Wed 09:00–11:00'),
        ('CSC 307', 'Computer Networks & Data Communication', 3, 'C', 'Thu 09:00–11:00'),
        ('CSC 309', 'Artificial Intelligence & Machine Learning', 3, 'R', 'Fri 09:00–11:00'),
        ('CSC 399', 'SIWES Industrial Training', 4, 'C', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Computer Science', '400 Level', [
        ('CSC 401', 'Algorithms & Complexity Analysis', 3, 'C', 'Mon 08:00–10:00'),
        ('CSC 403', 'Distributed & Cloud Computing', 3, 'C', 'Tue 08:00–10:00'),
        ('CSC 405', 'Deep Learning & Computer Vision', 3, 'E', 'Wed 09:00–11:00'),
        ('CSC 407', 'Net-Centric & Mobile Computing', 3, 'C', 'Thu 09:00–11:00'),
        ('CSC 409', 'Human-Computer Interaction', 3, 'R', 'Fri 09:00–11:00'),
        ('CSC 499', 'Final Year Research Project', 6, 'C', 'Fri 14:00–16:00'),
      ]),

      // =========================================================================
      // 8. CYBERSECURITY & DIGITAL FORENSICS — 100L to 400L (6-7 courses/lvl)
      // =========================================================================
      ..._lvl('Cybersecurity & Digital Forensics', '100 Level', [
        ('COS 101', 'Introduction to Computing', 3, 'C', 'Mon 08:00–10:00'),
        ('CYB 102', 'Fundamentals of Cybersecurity', 3, 'C', 'Mon 10:00–12:00'),
        ('MTH 101', 'Elementary Mathematics I', 3, 'C', 'Tue 09:00–11:00'),
        ('PHY 101', 'General Physics I', 3, 'C', 'Wed 09:00–11:00'),
        ('GST 101', 'Use of English', 2, 'C', 'Thu 09:00–11:00'),
        ('STA 111', 'Probability & Statistics', 3, 'R', 'Fri 10:00–12:00'),
        ('GST 105', 'Logic & Critical Thinking', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Cybersecurity & Digital Forensics', '200 Level', [
        ('CYB 201', 'Cryptography & Number Theory', 4, 'C', 'Mon 08:00–10:00'),
        ('CYB 203', 'System & Network Administration (Linux/Windows)', 4, 'C', 'Tue 08:00–10:00'),
        ('CSC 203', 'Data Structures & Algorithms', 3, 'C', 'Wed 09:00–11:00'),
        ('CYB 205', 'Information Security Governance & Risk', 3, 'R', 'Thu 09:00–11:00'),
        ('CSC 205', 'Computer Architecture', 3, 'R', 'Fri 09:00–11:00'),
        ('CYB 207', 'Cyber Law & Nigerian NDPR Compliance', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Cybersecurity & Digital Forensics', '300 Level', [
        ('CYB 301', 'Ethical Hacking & Penetration Testing', 4, 'C', 'Mon 08:00–10:00'),
        ('CYB 303', 'Digital Forensics & Incident Response', 4, 'C', 'Tue 08:00–10:00'),
        ('CYB 305', 'Network Security & Intrusion Detection', 3, 'C', 'Wed 09:00–11:00'),
        ('CYB 307', 'Web & Mobile Application Security', 3, 'C', 'Thu 09:00–11:00'),
        ('CYB 309', 'Malware Analysis & Reverse Engineering', 3, 'R', 'Fri 09:00–11:00'),
        ('CYB 399', 'SIWES Security Operations Placement', 4, 'C', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Cybersecurity & Digital Forensics', '400 Level', [
        ('CYB 401', 'Cloud & IoT Security Architecture', 3, 'C', 'Mon 08:00–10:00'),
        ('CYB 403', 'Security Operations Center (SOC) & SIEM Analytics', 4, 'C', 'Tue 08:00–10:00'),
        ('CYB 405', 'Cyber Threat Intelligence & Hunting', 3, 'C', 'Wed 09:00–11:00'),
        ('CYB 407', 'Biometrics & Identity Access Management', 3, 'R', 'Thu 09:00–11:00'),
        ('CYB 409', 'Blockchain & FinTech Security', 2, 'E', 'Fri 09:00–11:00'),
        ('CYB 499', 'Final Year Cybersecurity Project', 6, 'C', 'Fri 14:00–16:00'),
      ]),

      // =========================================================================
      // 9. CIVIL & STRUCTURAL ENGINEERING — 100L to 400L (6-7 courses/lvl)
      // =========================================================================
      ..._lvl('Civil & Structural Engineering', '100 Level', [
        ('MTH 101', 'Elementary Mathematics I', 3, 'C', 'Mon 08:00–10:00'),
        ('PHY 101', 'General Physics I', 3, 'C', 'Mon 10:00–12:00'),
        ('CHM 101', 'General Chemistry I', 3, 'C', 'Tue 09:00–11:00'),
        ('CVE 102', 'Introduction to Civil Engineering', 3, 'C', 'Wed 09:00–11:00'),
        ('GET 102', 'Engineering Drawing', 3, 'C', 'Thu 09:00–11:00'),
        ('GST 101', 'Use of English', 2, 'C', 'Fri 10:00–12:00'),
        ('STA 111', 'Engineering Statistics', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Civil & Structural Engineering', '200 Level', [
        ('CVE 201', 'Engineering Surveying & Geomatics', 4, 'C', 'Mon 08:00–10:00'),
        ('CVE 203', 'Strength of Materials', 4, 'C', 'Tue 08:00–10:00'),
        ('CVE 205', 'Fluid Mechanics & Hydrology', 3, 'C', 'Wed 09:00–11:00'),
        ('CVE 207', 'Engineering Geology & Soil Mechanics', 3, 'C', 'Thu 09:00–11:00'),
        ('MTH 202', 'Differential Equations', 3, 'R', 'Fri 09:00–11:00'),
        ('CVE 209', 'Civil Engineering Materials & Concrete Tech', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Civil & Structural Engineering', '300 Level', [
        ('CVE 301', 'Structural Analysis & Theory of Structures', 4, 'C', 'Mon 08:00–10:00'),
        ('CVE 303', 'Reinforced Concrete Design', 4, 'C', 'Tue 08:00–10:00'),
        ('CVE 305', 'Geotechnical & Foundation Engineering', 3, 'C', 'Wed 09:00–11:00'),
        ('CVE 307', 'Highway & Transportation Engineering', 3, 'C', 'Thu 09:00–11:00'),
        ('CVE 309', 'Water Resources & Environmental Engineering', 3, 'R', 'Fri 09:00–11:00'),
        ('CVE 399', 'Site & Industrial Attachment', 4, 'C', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Civil & Structural Engineering', '400 Level', [
        ('CVE 401', 'Structural Steel & Timber Design', 4, 'C', 'Mon 08:00–10:00'),
        ('CVE 403', 'Bridge & Tall Building Engineering', 4, 'C', 'Tue 08:00–10:00'),
        ('CVE 405', 'Construction Management & Quantity Estimation', 3, 'C', 'Wed 09:00–11:00'),
        ('CVE 407', 'Coastal & Dam Engineering', 3, 'E', 'Thu 09:00–11:00'),
        ('CVE 409', 'GIS & Remote Sensing in Civil Works', 2, 'R', 'Fri 09:00–11:00'),
        ('CVE 499', 'Civil Engineering Design Project', 6, 'C', 'Fri 14:00–16:00'),
      ]),

      // =========================================================================
      // 10. ACCOUNTING & FINANCE — 100L to 400L (6-7 courses per level)
      // =========================================================================
      ..._lvl('Accounting & Finance', '100 Level', [
        ('ACC 101', 'Introduction to Financial Accounting I', 4, 'C', 'Mon 08:00–10:00'),
        ('ECO 101', 'Principles of Microeconomics', 3, 'C', 'Mon 10:00–12:00'),
        ('BUS 101', 'Introduction to Business', 3, 'C', 'Tue 09:00–11:00'),
        ('MTH 103', 'Mathematics for Management Sciences', 3, 'C', 'Wed 09:00–11:00'),
        ('GST 101', 'Communication in English', 2, 'C', 'Thu 09:00–11:00'),
        ('COS 101', 'Business Computing & Spreadsheets', 3, 'R', 'Fri 10:00–12:00'),
        ('GST 103', 'Nigerian Peoples & Culture', 2, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Accounting & Finance', '200 Level', [
        ('ACC 201', 'Financial Accounting II & IFRS Standards', 4, 'C', 'Mon 08:00–10:00'),
        ('ACC 203', 'Cost & Management Accounting', 4, 'C', 'Tue 08:00–10:00'),
        ('FIN 201', 'Principles of Corporate Finance', 3, 'C', 'Wed 09:00–11:00'),
        ('LAW 201', 'Nigerian Business & Commercial Law', 3, 'C', 'Thu 09:00–11:00'),
        ('ACC 205', 'Accounting Information Systems', 3, 'R', 'Fri 09:00–11:00'),
        ('STA 201', 'Business Statistics', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Accounting & Finance', '300 Level', [
        ('ACC 301', 'Advanced Financial Reporting', 4, 'C', 'Mon 08:00–10:00'),
        ('ACC 303', 'Auditing & Assurance Services', 4, 'C', 'Tue 08:00–10:00'),
        ('ACC 305', 'Nigerian Taxation & Fiscal Policy', 3, 'C', 'Wed 09:00–11:00'),
        ('ACC 307', 'Public Sector Accounting & IPSAS', 3, 'C', 'Thu 09:00–11:00'),
        ('FIN 303', 'Investment & Portfolio Management', 3, 'R', 'Fri 09:00–11:00'),
        ('ENT 301', 'Entrepreneurship & SME Accounting', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Accounting & Finance', '400 Level', [
        ('ACC 401', 'Forensic Accounting & Fraud Investigation', 4, 'C', 'Mon 08:00–10:00'),
        ('ACC 403', 'Strategic Financial Management', 4, 'C', 'Tue 08:00–10:00'),
        ('ACC 405', 'International Accounting & Multinationals', 3, 'C', 'Wed 09:00–11:00'),
        ('ACC 407', 'Bankruptcy, Executorship & Trusteeship', 3, 'R', 'Thu 09:00–11:00'),
        ('ACC 409', 'Corporate Governance & Ethics', 2, 'E', 'Fri 09:00–11:00'),
        ('ACC 499', 'Accounting Research Project', 6, 'C', 'Fri 14:00–16:00'),
      ]),

      // =========================================================================
      // 11. BUSINESS ADMINISTRATION & ENTREPRENEURSHIP — 100L to 400L
      // =========================================================================
      ..._lvl('Business Administration & Entrepreneurship', '100 Level', [
        ('BUS 101', 'Principles of Management', 3, 'C', 'Mon 08:00–10:00'),
        ('ECO 101', 'Principles of Economics', 3, 'C', 'Mon 10:00–12:00'),
        ('ACC 101', 'Basic Accounting', 3, 'C', 'Tue 09:00–11:00'),
        ('MTH 103', 'Business Mathematics', 3, 'C', 'Wed 09:00–11:00'),
        ('GST 101', 'Use of English', 2, 'C', 'Thu 09:00–11:00'),
        ('PSY 102', 'Organizational Psychology', 3, 'R', 'Fri 10:00–12:00'),
        ('GST 105', 'Philosophy & Logic', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Business Administration & Entrepreneurship', '200 Level', [
        ('BUS 201', 'Organizational Behaviour', 3, 'C', 'Mon 08:00–10:00'),
        ('MKT 201', 'Principles of Marketing', 4, 'C', 'Tue 08:00–10:00'),
        ('BUS 203', 'Business Communication & Negotiation', 3, 'C', 'Wed 09:00–11:00'),
        ('BUS 205', 'Production & Operations Management', 3, 'C', 'Thu 09:00–11:00'),
        ('LAW 201', 'Commercial Law', 3, 'R', 'Fri 09:00–11:00'),
        ('STA 201', 'Quantitative Analysis for Business', 3, 'R', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Business Administration & Entrepreneurship', '300 Level', [
        ('BUS 301', 'Human Resource Management', 4, 'C', 'Mon 08:00–10:00'),
        ('ENT 301', 'Venture Creation & Business Plan Design', 4, 'C', 'Tue 08:00–10:00'),
        ('BUS 303', 'Supply Chain & Logistics Management', 3, 'C', 'Wed 09:00–11:00'),
        ('MKT 303', 'Digital Marketing & E-Commerce', 3, 'C', 'Thu 09:00–11:00'),
        ('BUS 305', 'Research Methods in Management', 3, 'R', 'Fri 09:00–11:00'),
        ('FIN 301', 'Financial Management for SMEs', 3, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Business Administration & Entrepreneurship', '400 Level', [
        ('BUS 401', 'Strategic Management & Business Policy', 4, 'C', 'Mon 08:00–10:00'),
        ('BUS 403', 'International Business & Global Trade', 3, 'C', 'Tue 08:00–10:00'),
        ('BUS 405', 'Project Management & Risk Analysis', 3, 'C', 'Wed 09:00–11:00'),
        ('BUS 407', 'Corporate Social Responsibility & Ethics', 2, 'R', 'Thu 09:00–11:00'),
        ('BUS 409', 'Leadership & Change Management', 3, 'E', 'Fri 09:00–11:00'),
        ('BUS 499', 'Business Administration Thesis', 6, 'C', 'Fri 14:00–16:00'),
      ]),

      // =========================================================================
      // 12. MASS COMMUNICATION & DIGITAL MEDIA — 100L to 400L
      // =========================================================================
      ..._lvl('Mass Communication & Digital Media', '100 Level', [
        ('MAC 101', 'Introduction to Mass Communication', 3, 'C', 'Mon 08:00–10:00'),
        ('MAC 103', 'History of Nigerian Media', 3, 'C', 'Mon 10:00–12:00'),
        ('MAC 105', 'Writing for the Mass Media', 3, 'C', 'Tue 09:00–11:00'),
        ('GST 101', 'Use of English', 2, 'C', 'Wed 09:00–11:00'),
        ('SOC 102', 'Sociology of Mass Communication', 3, 'R', 'Thu 09:00–11:00'),
        ('COS 101', 'Digital Literacy & Multimedia Tools', 3, 'R', 'Fri 10:00–12:00'),
        ('GST 103', 'Nigerian Peoples & Culture', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Mass Communication & Digital Media', '200 Level', [
        ('MAC 201', 'News Reporting & Feature Writing', 4, 'C', 'Mon 08:00–10:00'),
        ('MAC 203', 'Broadcast Journalism (Radio & TV)', 4, 'C', 'Tue 08:00–10:00'),
        ('MAC 205', 'Photojournalism & Visual Storytelling', 3, 'C', 'Wed 09:00–11:00'),
        ('MAC 207', 'Theories of Mass Communication', 3, 'C', 'Thu 09:00–11:00'),
        ('MAC 209', 'Editing & Graphics of Communication', 3, 'R', 'Fri 09:00–11:00'),
        ('ENT 201', 'Media Entrepreneurship', 2, 'E', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Mass Communication & Digital Media', '300 Level', [
        ('MAC 301', 'Public Relations & Corporate Reputation', 4, 'C', 'Mon 08:00–10:00'),
        ('MAC 303', 'Advertising Principles & Campaign Design', 4, 'C', 'Tue 08:00–10:00'),
        ('MAC 305', 'Digital Journalism & Social Media Analytics', 3, 'C', 'Wed 09:00–11:00'),
        ('MAC 307', 'Media Law & Nigerian Press Ethics', 3, 'C', 'Thu 09:00–11:00'),
        ('MAC 309', 'Development Communication', 3, 'R', 'Fri 09:00–11:00'),
        ('MAC 399', 'Media House Industrial Attachment', 4, 'C', 'Fri 14:00–16:00'),
      ]),
      ..._lvl('Mass Communication & Digital Media', '400 Level', [
        ('MAC 401', 'Investigative & Data Journalism', 4, 'C', 'Mon 08:00–10:00'),
        ('MAC 403', 'Film Production & Documentary Directing', 4, 'C', 'Tue 08:00–10:00'),
        ('MAC 405', 'International & Crisis Communication', 3, 'C', 'Wed 09:00–11:00'),
        ('MAC 407', 'Media Management & Economics', 3, 'R', 'Thu 09:00–11:00'),
        ('MAC 409', 'Political Communication & Public Opinion', 2, 'E', 'Fri 09:00–11:00'),
        ('MAC 499', 'Mass Communication Research Project', 6, 'C', 'Fri 14:00–16:00'),
      ]),
    ];
  }
}

final academicsProvider =
StateNotifierProvider<AcademicsNotifier, AcademicsState>((ref) {
  return AcademicsNotifier(ref);
});