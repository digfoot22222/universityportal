import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/student_model.dart';
import '../../admin_console/providers/admin_provider.dart';

class UniversityCounselor {
  final String id;
  final String fullName;
  final String title;
  final String specialization;
  final String nextAvailableSlot;
  final String officeLocation;
  final bool isOnlineNow;

  const UniversityCounselor({
    required this.id,
    required this.fullName,
    required this.title,
    required this.specialization,
    required this.nextAvailableSlot,
    required this.officeLocation,
    this.isOnlineNow = true,
  });
}

class CounselingBooking {
  final String id;
  final String studentMatric;
  final String studentName;
  final String counselorName;
  final String mode; // 'Confidential Video Call' or 'In-Person Office'
  final String slot;
  final String topic;
  final DateTime bookedAt;

  const CounselingBooking({
    required this.id,
    required this.studentMatric,
    required this.studentName,
    required this.counselorName,
    required this.mode,
    required this.slot,
    required this.topic,
    required this.bookedAt,
  });
}

class CounselingMessage {
  final bool isUser;
  final String text;
  final bool showCrisisSupportBanner;

  const CounselingMessage({
    required this.isUser,
    required this.text,
    this.showCrisisSupportBanner = false,
  });
}

class CounselingState {
  final List<UniversityCounselor> counselors;
  final List<CounselingBooking> bookings;
  final List<CounselingMessage> confidentialChat;

  const CounselingState({
    required this.counselors,
    this.bookings = const [],
    required this.confidentialChat,
  });

  CounselingState copyWith({
    List<UniversityCounselor>? counselors,
    List<CounselingBooking>? bookings,
    List<CounselingMessage>? confidentialChat,
  }) {
    return CounselingState(
      counselors: counselors ?? this.counselors,
      bookings: bookings ?? this.bookings,
      confidentialChat: confidentialChat ?? this.confidentialChat,
    );
  }
}

class CounselingNotifier extends StateNotifier<CounselingState> {
  final Ref _ref;

  CounselingNotifier(this._ref)
      : super(
    const CounselingState(
      counselors: [
        UniversityCounselor(
          id: 'coun_01',
          fullName: 'Dr. Hauwa Abdullahi-Suleiman',
          title: 'Director of Student Guidance & Academic Advising',
          specialization:
          'CGPA Recovery • Carryover Planning • Course Load Optimization',
          nextAvailableSlot: 'Today • 2:00 PM (WAT)',
          officeLocation: 'Senate Student Affairs Annex, Room 104',
          isOnlineNow: true,
        ),
        UniversityCounselor(
          id: 'coun_02',
          fullName: 'Dr. Emmanuel Nwachukwu',
          title: 'Licensed Clinical & Campus Wellness Psychologist',
          specialization:
          'Exam Anxiety • Burnout Recovery • Confidential Emotional Support',
          nextAvailableSlot: 'Today • 4:30 PM (WAT)',
          officeLocation: 'University Health & Wellness Center, Wing B',
          isOnlineNow: true,
        ),
        UniversityCounselor(
          id: 'coun_03',
          fullName: 'Mrs. Funke Balogun-Ojo',
          title: 'Lead Career, SIWES & Global Scholarship Coach',
          specialization:
          'SIWES Placements • CV & SOP Review • Commonwealth/Chevening Prep',
          nextAvailableSlot: 'Tomorrow • 10:00 AM (WAT)',
          officeLocation: 'Career & Entrepreneurship Hub, 2nd Floor',
          isOnlineNow: false,
        ),
      ],
      confidentialChat: [
        CounselingMessage(
          isUser: false,
          text:
          'Welcome to the 24/7 Confidential University Guidance & Counseling Sanctuary. Everything shared here is private.\n\nTell me how you are feeling or what academic hurdle you are facing (e.g., exam stress, carryover recovery, career confusion, or financial aid options).',
        ),
      ],
    ),
  );

  void sendConfidentialMessage(String rawText, StudentAccount? student) {
    final text = rawText.trim();
    if (text.isEmpty) return;

    final userMsg = CounselingMessage(isUser: true, text: text);
    final lower = text.toLowerCase();

    final isDistress = lower.contains('hopeless') ||
        lower.contains('depress') ||
        lower.contains('panic') ||
        lower.contains('harm') ||
        lower.contains('give up');

    String replyText;
    if (isDistress) {
      replyText =
      'You do not have to carry this alone, ${student?.fullName ?? "friend"}. Please take a slow, steady breath. I have highlighted the direct 24/7 University Health & Wellness Crisis Desk below, and Dr. Emmanuel Nwachukwu has priority same-day confidential slots open today.';
    } else if (lower.contains('carryover') ||
        lower.contains('cgpa') ||
        lower.contains('fail') ||
        lower.contains('probation')) {
      replyText =
      'Academic Recovery Blueprint for ${student?.department ?? "your program"} (${student?.level ?? "Current Level"}):\n1. Prioritize clearing any Compulsory (C) prerequisite courses first so your graduation timeline stays intact.\n2. Cap your semester load at 18–20 units instead of 24 units to maximize A/B grades.\n3. Book a 15-minute review with Dr. Hauwa Abdullahi-Suleiman below to lock your tailored GPA recovery plan.';
    } else if (lower.contains('anxiety') ||
        lower.contains('stress') ||
        lower.contains('burnout') ||
        lower.contains('exam')) {
      replyText =
      'Exam & Burnout Decompression Strategy:\n• Break revision into 45-minute focused blocks followed by 10-minute screen-free rest.\n• Focus on high-yield past questions and lecturer learning objectives rather than rereading entire textbooks overnight.\n• Protect at least 6.5 hours of sleep before exam mornings—memory consolidation happens during deep sleep.';
    } else {
      replyText =
      'Thank you for sharing that openly. Balancing university coursework, finances, and future career pressure takes real resilience. Would you like a step-by-step study recovery schedule, scholarship/bursary guidance, or a confidential 1-on-1 session with one of our licensed university counselors below?';
    }

    final aiMsg = CounselingMessage(
      isUser: false,
      text: replyText,
      showCrisisSupportBanner: isDistress,
    );

    state = state.copyWith(
      confidentialChat: [...state.confidentialChat, userMsg, aiMsg],
    );
  }

  void bookCounselorSession({
    required StudentAccount student,
    required UniversityCounselor counselor,
    required String mode,
    required String topic,
  }) {
    final booking = CounselingBooking(
      id: const Uuid().v4(),
      studentMatric: student.matricNumber,
      studentName: student.fullName,
      counselorName: counselor.fullName,
      mode: mode,
      slot: counselor.nextAvailableSlot,
      topic: topic.trim().isEmpty ? 'General Academic & Wellness Check-In' : topic.trim(),
      bookedAt: DateTime.now(),
    );

    state = state.copyWith(bookings: [booking, ...state.bookings]);
    _ref.read(adminProvider.notifier).logSecurityEvent(
      actor: student.matricNumber,
      action: 'COUNSELING_SESSION_BOOKED',
      target: '${counselor.fullName} ($mode • ${counselor.nextAvailableSlot})',
    );
  }
}

final counselingProvider =
StateNotifierProvider<CounselingNotifier, CounselingState>((ref) {
  return CounselingNotifier(ref);
});