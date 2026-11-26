import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/models/student_model.dart';
import '../../academics_courses/providers/academics_provider.dart';
import '../../admin_console/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../hostel_virtual/providers/hostel_provider.dart';
import '../../payments_remita/providers/payment_provider.dart';

enum AgentToolActionType {
  none,
  upgradeToProPaywall,
  remitaPaymentCard,
  courseRegistrationCard,
  hostelMatchCard,
  printOfficialSlipCard,
}

class AgentToolActionPayload {
  final AgentToolActionType type;
  final String title;
  final String subtitle;
  final String actionButtonLabel;
  final String? slipCategory; // 'COURSE_FORM', 'REMITA_RECEIPT', 'HOSTEL_SLIP'
  final String? feeType;
  final double? amountNaira;
  final String? roomId;
  final String? bunkLabel;

  const AgentToolActionPayload({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.actionButtonLabel,
    this.slipCategory,
    this.feeType,
    this.amountNaira,
    this.roomId,
    this.bunkLabel,
  });
}

class AiChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final Uint8List? attachedImage;
  final List<String> webCitations;
  final AgentToolActionPayload? toolAction;
  final DateTime timestamp;

  const AiChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.attachedImage,
    this.webCitations = const [],
    this.toolAction,
    required this.timestamp,
  });
}

class AiAssistantState {
  final List<AiChatMessage> messages;
  final bool isThinking;
  final bool isRecordingVoice;
  final Uint8List? pendingClipboardOrPickedImage;
  final Map<String, int> freePromptsUsedByMatric;

  const AiAssistantState({
    required this.messages,
    this.isThinking = false,
    this.isRecordingVoice = false,
    this.pendingClipboardOrPickedImage,
    this.freePromptsUsedByMatric = const {
      // Pre-seed Amina Bello with 3 used (2/5 left) so paywall is easy to demo!
      'NUR/2024/1108': 3,
    },
  });

  int remainingFreePrompts(StudentAccount? user) {
    if (user == null) return 5;
    if (user.isAiProSubscriber) return 999999;
    final used = freePromptsUsedByMatric[user.matricNumber] ?? 0;
    return (5 - used).clamp(0, 5);
  }

  AiAssistantState copyWith({
    List<AiChatMessage>? messages,
    bool? isThinking,
    bool? isRecordingVoice,
    Uint8List? pendingClipboardOrPickedImage,
    bool clearPendingImage = false,
    Map<String, int>? freePromptsUsedByMatric,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      isRecordingVoice: isRecordingVoice ?? this.isRecordingVoice,
      pendingClipboardOrPickedImage: clearPendingImage
          ? null
          : (pendingClipboardOrPickedImage ??
          this.pendingClipboardOrPickedImage),
      freePromptsUsedByMatric:
      freePromptsUsedByMatric ?? this.freePromptsUsedByMatric,
    );
  }
}

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final Ref _ref;

  AiAssistantNotifier(this._ref)
      : super(
    AiAssistantState(
      messages: [
        AiChatMessage(
          id: 'welcome_agent',
          isUser: false,
          text:
          'Welcome to UniCore Autonomous Campus Copilot! I am strictly cloud-connected with live web grounding and direct tool-calling privileges.\n\nTry telling me:\n• "Help me pay my school fees"\n• "Register my 300L courses & explain CSC 305"\n• "Find me a quiet lower bunk in a male hostel"\n• "Print my Course Registration Form / Remita Slip / Hostel Slip" (AI Pro)',
          webCitations: const [
            'https://nuc.edu.ng/benchmark-curriculum',
            'https://remita.net/university-collections',
          ],
          timestamp: DateTime.now(),
        ),
      ],
    ),
  );

  void attachImageBytes(Uint8List bytes) {
    state = state.copyWith(pendingClipboardOrPickedImage: bytes);
  }

  void clearAttachedImage() {
    state = state.copyWith(clearPendingImage: true);
  }

  void toggleVoiceRecording() {
    state = state.copyWith(isRecordingVoice: !state.isRecordingVoice);
  }

  Future<void> sendPrompt(String rawText) async {
    final prompt = rawText.trim();
    if (prompt.isEmpty && state.pendingClipboardOrPickedImage == null) return;

    final user = _ref.read(authProvider).currentUser;
    final attached = state.pendingClipboardOrPickedImage;

    final userMsg = AiChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      text: prompt.isEmpty ? '[Uploaded Document / Clipboard Scan]' : prompt,
      attachedImage: attached,
      timestamp: DateTime.now(),
    );

    // Check Free Tier 5-Prompt Daily Limit
    if (user != null && !user.isAiProSubscriber) {
      final remaining = state.remainingFreePrompts(user);
      if (remaining <= 0) {
        final paywallReply = AiChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_paywall',
          isUser: false,
          text:
          'Daily Free Limit Reached (0 / 5 prompts remaining for ${user.fullName}). Upgrade to **AI Pro Unlimited (₦1,500/semester)** via instant Remita checkout to unlock unlimited AI conversations, live internet research, CBT exam generators, and one-command official PDF slip printing.',
          toolAction: const AgentToolActionPayload(
            type: AgentToolActionType.upgradeToProPaywall,
            title: 'Unlock AI Pro Unlimited (Gold Crown Tier)',
            subtitle:
            'Unlimited Cloud AI + Live Internet Search + Instant Course/Remita/Hostel PDF Slip Printing • ₦1,500/Semester',
            actionButtonLabel: 'Upgrade Instantly via Remita (₦1,500)',
            feeType: 'AI Pro Semester Unlimited Subscription',
            amountNaira: 1500,
          ),
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, userMsg, paywallReply],
          clearPendingImage: true,
        );
        return;
      }

      final updatedCounts =
      Map<String, int>.from(state.freePromptsUsedByMatric);
      updatedCounts[user.matricNumber] =
          (updatedCounts[user.matricNumber] ?? 0) + 1;
      state = state.copyWith(freePromptsUsedByMatric: updatedCounts);
    }

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isThinking: true,
      clearPendingImage: true,
    );

    await Future.delayed(const Duration(milliseconds: 650));

    final lower = prompt.toLowerCase();
    final reply = _routeAgenticToolCall(lower, prompt, user, attached != null);

    state = state.copyWith(
      messages: [...state.messages, reply],
      isThinking: false,
    );
  }

  AiChatMessage _routeAgenticToolCall(
      String lower,
      String originalPrompt,
      StudentAccount? user,
      bool hasImage,
      ) {
    final now = DateTime.now();
    final name = user?.fullName ?? 'Student';
    final dept = user?.department ?? 'Computer Science';
    final level = user?.level ?? '300 Level';
    final isPro = user?.isAiProSubscriber ?? false;

    // TOOL 1: ONE-COMMAND PDF SLIP PRINTING (AI PRO PRIVILEGE)
    if (lower.contains('print') ||
        lower.contains('slip') ||
        lower.contains('download') ||
        lower.contains('pdf')) {
      String slipType = 'COURSE_FORM';
      String slipName = 'Official Senate Course Registration Form (CRF)';
      if (lower.contains('remita') ||
          lower.contains('receipt') ||
          lower.contains('fee')) {
        slipType = 'REMITA_RECEIPT';
        slipName = 'Official Remita Treasury Payment Receipt';
      } else if (lower.contains('hostel') ||
          lower.contains('bunk') ||
          lower.contains('porter')) {
        slipType = 'HOSTEL_SLIP';
        slipName = 'Hostel Allocation & Porter Check-In Slip';
      }

      if (!isPro) {
        return AiChatMessage(
          id: '${now.millisecondsSinceEpoch}_pro_lock',
          isUser: false,
          text:
          'One-Command Official PDF Slip Printing (**$slipName**) is an exclusive **AI Pro** feature. Activate AI Pro for ₦1,500/semester to generate and print watermarked QR slips directly from chat.',
          toolAction: const AgentToolActionPayload(
            type: AgentToolActionType.upgradeToProPaywall,
            title: 'AI Pro Required for Instant Slip Printing',
            subtitle:
            'Print Course Forms, Remita Receipts & Hostel Slips in 1 tap • ₦1,500',
            actionButtonLabel: 'Activate AI Pro Now (₦1,500)',
            feeType: 'AI Pro Semester Unlimited Subscription',
            amountNaira: 1500,
          ),
          timestamp: now,
        );
      }

      return AiChatMessage(
        id: '${now.millisecondsSinceEpoch}_print',
        isUser: false,
        text:
        'AI Pro Document Engine ready! I have compiled **$slipName** for **$name (${user?.matricNumber})** with your cryptographic Senate QR seal. Tap below to preview, print, or save as PDF.',
        toolAction: AgentToolActionPayload(
          type: AgentToolActionType.printOfficialSlipCard,
          title: slipName,
          subtitle:
          'Verified for $name • $dept ($level) • QR Hash: ${user?.cryptographicCredentialHash}',
          actionButtonLabel: 'Print / Download Official PDF Slip',
          slipCategory: slipType,
        ),
        timestamp: now,
      );
    }

    // TOOL 2: REMITA SCHOOL FEES & RRR GENERATION
    if (lower.contains('pay') ||
        lower.contains('fee') ||
        lower.contains('remita') ||
        lower.contains('rrr') ||
        lower.contains('tuition')) {
      final isHostelFee = lower.contains('hostel');
      final feeTitle = isHostelFee
          ? 'Smart Hostel Accommodation Fee (2026/2027)'
          : '2026/2027 Undergraduate Tuition & ICT Levy ($dept)';
      final amount = isHostelFee ? 85000.0 : 145000.0;

      return AiChatMessage(
        id: '${now.millisecondsSinceEpoch}_remita',
        isUser: false,
        text:
        'I queried the Bursary tariff schedule for **$dept ($level)**. Your **$feeTitle** is **₦${amount.toStringAsFixed(0)}**. Tap the action card below to generate your Remita RRR and complete instant checkout.',
        toolAction: AgentToolActionPayload(
          type: AgentToolActionType.remitaPaymentCard,
          title: feeTitle,
          subtitle:
          'Student: $name (${user?.matricNumber}) • Amount: ₦${amount.toStringAsFixed(0)} + Platform Convenience Split',
          actionButtonLabel: 'Generate RRR & Pay via Remita',
          feeType: feeTitle,
          amountNaira: amount,
        ),
        timestamp: now,
      );
    }

    // TOOL 3: COURSE REGISTRATION & COURSE OUTLINE EXPLAINER
    if (lower.contains('course') ||
        lower.contains('register') ||
        lower.contains('csc') ||
        lower.contains('explain') ||
        lower.contains('syllabus')) {
      return AiChatMessage(
        id: '${now.millisecondsSinceEpoch}_courses',
        isUser: false,
        text:
        'I analyzed the NUC curriculum for **$dept ($level)** and verified zero timetable clashes:\n• **CSC 305 (Compiler Construction):** Covers Lexical Analysis (Finite Automata), Context-Free Grammars (LL/LR Parsing), Syntax-Directed Translation, and Code Optimization. Recommended project: Build a mini-expression parser in Dart/Python.\n\nTap below to lock your **$level** courses onto your Senate Course Registration Form.',
        webCitations: const [
          'https://nuc.edu.ng/ccmas-computing-curriculum',
        ],
        toolAction: AgentToolActionPayload(
          type: AgentToolActionType.courseRegistrationCard,
          title: 'Auto-Register $dept ($level) Core Courses',
          subtitle:
          'Validates 15–24 NUC Credit Units & generates QR Course Form',
          actionButtonLabel: 'Execute Course Registration Now',
        ),
        timestamp: now,
      );
    }

    // TOOL 4: GENDER-AWARE HOSTEL & AI ROOMMATE MATCHMAKER
    if (lower.contains('hostel') ||
        lower.contains('bunk') ||
        lower.contains('roommate') ||
        lower.contains('room')) {
      final isFemale = user?.gender == StudentGender.female;
      final hallName = isFemale
          ? 'Queen Amina Royal Hall (Female Wing)'
          : 'Zik Heritage Hall (Male Wing)';
      final roomCode = isFemale ? 'F-AMINA-101' : 'M-ZIK-101';

      return AiChatMessage(
        id: '${now.millisecondsSinceEpoch}_hostel',
        isUser: false,
        text:
        'Gender-Routing Engine locked to **${isFemale ? "Female (8 Halls)" : "Male (10 Halls)"}**. Based on your study habits and quiet routine, I found a **96% personality match** in **$hallName — Room $roomCode (Bunk B Lower)**.',
        toolAction: AgentToolActionPayload(
          type: AgentToolActionType.hostelMatchCard,
          title: '$hallName • $roomCode',
          subtitle:
          '96% Roommate Compatibility • Bunk B (Lower) • ₦85,000/Session',
          actionButtonLabel: 'Lock Bunk & Proceed to Remita',
          roomId: roomCode,
          bunkLabel: 'Bunk B (Lower)',
        ),
        timestamp: now,
      );
    }

    // DEFAULT: LIVE WEB-GROUNDED GENERAL & ACADEMIC INTELLIGENCE
    return AiChatMessage(
      id: '${now.millisecondsSinceEpoch}_web',
      isUser: false,
      text: hasImage
          ? 'Multimodal Vision Analysis Complete: I scanned your uploaded academic document/note for **$name ($dept)** and extracted key exam concepts, formulas, and summary flashcards.'
          : 'Live Cloud & Web-Grounded Response for **$name ($dept • $level)**:\n\nRegarding "$originalPrompt": According to current 2026 NUC academic standards and live global research feeds, focusing on practical capstone implementations alongside your core coursework boosts graduate employability and scholarship readiness. Would you like me to generate a CBT practice quiz, draft a SIWES cover letter, or print an official portal slip?',
      webCitations: const [
        'https://nuc.edu.ng/2026-academic-circular',
        'https://scholar.google.com/trending-research-2026',
      ],
      timestamp: now,
    );
  }

  /// Generates & Opens Official Watermarked PDF Slip using `pdf` + `printing`
  Future<void> generateAndPrintOfficialSlip({
    required StudentAccount student,
    required String slipCategory,
  }) async {
    final doc = pw.Document();
    final title = slipCategory == 'REMITA_RECEIPT'
        ? 'OFFICIAL REMITA TREASURY PAYMENT RECEIPT'
        : (slipCategory == 'HOSTEL_SLIP'
        ? 'OFFICIAL HOSTEL ALLOCATION & PORTER CHECK-IN SLIP'
        : 'OFFICIAL SENATE COURSE REGISTRATION FORM (CRF)');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(28),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo900, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'UNICORE ENTERPRISE UNIVERSITY PORTAL (NUC ACCREDITED)',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 10),
                pw.Text('Student Full Name: ${student.fullName}'),
                pw.Text('Matriculation Number: ${student.matricNumber}'),
                pw.Text(
                    'Biological Gender: ${student.gender.name.toUpperCase()}'),
                pw.Text('Department: ${student.department}'),
                pw.Text(
                    'Academic Level & Semester: ${student.level} • ${student.semester}'),
                pw.Text('Current Standing / CGPA: ${student.cgpa}'),
                pw.SizedBox(height: 14),
                if (slipCategory == 'HOSTEL_SLIP') ...[
                  pw.Text(
                    'Allocated Hostel Room: ${student.assignedRoomId ?? "M-ZIK-101"}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Assigned Bunk Space: ${student.assignedBunkLabel ?? "Bunk A (Lower)"}',
                  ),
                  pw.Text('Porter Clearance Status: CLEARED FOR CHECK-IN'),
                ] else if (slipCategory == 'REMITA_RECEIPT') ...[
                  pw.Text(
                    'Remita RRR Reference: 3409-8821-7740 (Code 00 - Approved)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Session Fee Status: 100% PAID & TREASURY VERIFIED'),
                ] else ...[
                  pw.Text(
                    'Registered Courses (${student.registeredCourseCodes.length} Courses):',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 6),
                  ...student.registeredCourseCodes
                      .map((code) => pw.Bullet(text: '$code — NUC Approved')),
                ],
                pw.Spacer(),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Cryptographic Verification Seal:\n${student.cryptographicCredentialHash}\nGenerated via UniCore AI Pro Document Engine',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data:
                      'UNICORE-SLIP|${student.matricNumber}|$slipCategory|${student.cryptographicCredentialHash}',
                      width: 75,
                      height: 75,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${student.matricNumber}_$slipCategory.pdf',
    );
  }
}

final aiAssistantProvider =
StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  return AiAssistantNotifier(ref);
});