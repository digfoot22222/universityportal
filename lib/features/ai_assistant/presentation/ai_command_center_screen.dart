import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:super_clipboard/super_clipboard.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../academics_courses/providers/academics_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../hostel_virtual/providers/hostel_provider.dart';
import '../../payments_remita/providers/payment_provider.dart';
import '../providers/ai_assistant_provider.dart';

class AiCommandCenterScreen extends ConsumerStatefulWidget {
  const AiCommandCenterScreen({super.key});

  @override
  ConsumerState<AiCommandCenterScreen> createState() =>
      _AiCommandCenterScreenState();
}

class _AiCommandCenterScreenState extends ConsumerState<AiCommandCenterScreen> {
  final _promptController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;
    final reader = await clipboard.read();

    if (reader.canProvide(Formats.png)) {
      reader.getFile(Formats.png, (file) async {
        final bytes = await file.readAll();
        ref.read(aiAssistantProvider.notifier).attachImageBytes(bytes);
      });
      return;
    }

    if (reader.canProvide(Formats.jpeg)) {
      reader.getFile(Formats.jpeg, (file) async {
        final bytes = await file.readAll();
        ref.read(aiAssistantProvider.notifier).attachImageBytes(bytes);
      });
      return;
    }

    if (reader.canProvide(Formats.plainText)) {
      final text = await reader.readValue(Formats.plainText);
      if (text != null && text.isNotEmpty) {
        _promptController.text = '${_promptController.text} $text'.trim();
      }
    }
  }

  Future<void> _pickImageFile() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      ref.read(aiAssistantProvider.notifier).attachImageBytes(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiAssistantProvider);
    final student = ref.watch(authProvider).currentUser;
    final isPro = student?.isAiProSubscriber ?? false;
    final remaining = aiState.remainingFreePrompts(student);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card with Gold Crown Pro Badge or Free Tier Counter
          PrismGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: isPro
                                ? const LinearGradient(colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFF3CAC)
                            ])
                                : AppColors.primaryCtaGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPro
                                ? Icons.workspace_premium_rounded
                                : Icons.auto_awesome,
                            color: isPro ? AppColors.deepObsidian : Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Autonomous Agentic AI University Copilot',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Executes Fees, Course Reg, Hostels & Official PDF Slips',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.mutedSlate),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AiTierCrownBadge(
                      isPro: isPro,
                      freePromptsRemaining: remaining,
                      onTapUpgrade: () {
                        ref
                            .read(aiAssistantProvider.notifier)
                            .sendPrompt('Upgrade my account to AI Pro');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Quick Agentic Tool Prompts
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _quickChip('Help me pay my school fees'),
                      _quickChip('Register my 300L courses & explain CSC 305'),
                      _quickChip('Find me a quiet lower bunk in my hostel'),
                      _quickChip('Print my Course Registration Form'),
                      _quickChip('Print my Remita payment slip'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Chat Stream with Interactive Tool-Execution Cards
          Expanded(
            child: PrismGlassCard(
              padding: const EdgeInsets.all(14),
              child: ListView.builder(
                itemCount:
                aiState.messages.length + (aiState.isThinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == aiState.messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Executing cloud tool-call & live web grounding...',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    );
                  }

                  final msg = aiState.messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      constraints: const BoxConstraints(maxWidth: 640),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? AppColors.electricIndigo
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: msg.isUser
                            ? null
                            : Border.all(
                          color: AppColors.electricIndigo
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.attachedImage != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(msg.attachedImage!,
                                  height: 140, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isUser
                                  ? Colors.white
                                  : AppColors.deepObsidian,
                              height: 1.45,
                            ),
                          ),

                          // Interactive Tool-Calling Execution Card
                          if (msg.toolAction != null && student != null) ...[
                            const SizedBox(height: 12),
                            _buildToolActionCard(msg.toolAction!, student),
                          ],

                          if (msg.webCitations.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Live Web Citations:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cyberBlue,
                              ),
                            ),
                            ...msg.webCitations.map(
                                  (url) => Text(
                                '• $url',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.cyberBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Multimodal Input Bar with Ctrl+V Clipboard Support
          PrismGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                if (aiState.pendingClipboardOrPickedImage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.aquaMint.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Image.memory(aiState.pendingClipboardOrPickedImage!,
                            width: 44, height: 44, fit: BoxFit.cover),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Image / Clipboard Scan attached for AI analysis',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => ref
                              .read(aiAssistantProvider.notifier)
                              .clearAttachedImage(),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Upload Image or Document Scan',
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      onPressed: _pickImageFile,
                    ),
                    IconButton(
                      tooltip: 'Paste Image or Notes from Clipboard (Ctrl+V)',
                      icon: const Icon(Icons.content_paste_go),
                      onPressed: _pasteFromClipboard,
                    ),
                    IconButton(
                      tooltip: 'Voice Prompt',
                      icon: Icon(
                        aiState.isRecordingVoice ? Icons.stop_circle : Icons.mic,
                        color: aiState.isRecordingVoice
                            ? AppColors.crimsonAlert
                            : AppColors.electricIndigo,
                      ),
                      onPressed: () => ref
                          .read(aiAssistantProvider.notifier)
                          .toggleVoiceRecording(),
                    ),
                    Expanded(
                      child: CallbackShortcuts(
                        bindings: {
                          const SingleActivator(LogicalKeyboardKey.keyV,
                              control: true): _pasteFromClipboard,
                          const SingleActivator(LogicalKeyboardKey.keyV,
                              meta: true): _pasteFromClipboard,
                        },
                        child: TextField(
                          controller: _promptController,
                          onSubmitted: (val) {
                            ref
                                .read(aiAssistantProvider.notifier)
                                .sendPrompt(val);
                            _promptController.clear();
                          },
                          decoration: const InputDecoration(
                            hintText:
                            'Ask anything, pay fees, register courses, book hostel, or print slips...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    PrismGradientButton(
                      onPressed: () {
                        ref
                            .read(aiAssistantProvider.notifier)
                            .sendPrompt(_promptController.text);
                        _promptController.clear();
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: 'Execute',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String promptText) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: Colors.white,
        avatar: const Icon(Icons.bolt, size: 15, color: AppColors.electricMagenta),
        label: Text(promptText, style: const TextStyle(fontSize: 12)),
        onPressed: () =>
            ref.read(aiAssistantProvider.notifier).sendPrompt(promptText),
      ),
    );
  }

  Widget _buildToolActionCard(
      AgentToolActionPayload action,
      StudentAccount student,
      ) {
    final isGold = action.type == AgentToolActionType.upgradeToProPaywall ||
        action.type == AgentToolActionType.printOfficialSlipCard;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGold
              ? [const Color(0xFFFFF8DC), const Color(0xFFFFE4E1)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGold ? const Color(0xFFFFB703) : AppColors.electricIndigo,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            action.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            action.subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedSlate),
          ),
          const SizedBox(height: 10),
          PrismGradientButton(
            onPressed: () async {
              switch (action.type) {
                case AgentToolActionType.upgradeToProPaywall:
                case AgentToolActionType.remitaPaymentCard:
                  final tx = ref.read(paymentProvider.notifier).generateRrr(
                    student: student,
                    feeType: action.feeType ?? 'University Fee',
                    amountNaira: action.amountNaira ?? 1500,
                  );
                  await ref
                      .read(paymentProvider.notifier)
                      .confirmRemitaPayment(tx.rrr, student);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.emeraldPulse,
                        content: Text(
                          'Remita Payment Confirmed (RRR ${tx.rrr})! Account & Privileges Updated.',
                        ),
                      ),
                    );
                  }
                  break;

                case AgentToolActionType.courseRegistrationCard:
                  ref
                      .read(academicsProvider.notifier)
                      .submitCourseRegistration(student);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.emeraldPulse,
                        content: Text(
                          'Courses Registered & Senate QR Form Approved!',
                        ),
                      ),
                    );
                  }
                  break;

                case AgentToolActionType.hostelMatchCard:
                  if (action.roomId != null && action.bunkLabel != null) {
                    ref.read(hostelProvider.notifier).reserveBunkWith15MinLock(
                      roomId: action.roomId!,
                      bunkLabel: action.bunkLabel!,
                      student: student,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.emeraldPulse,
                          content: Text(
                            'Locked ${action.roomId} (${action.bunkLabel})! Complete payment in Remita tab.',
                          ),
                        ),
                      );
                    }
                  }
                  break;

                case AgentToolActionType.printOfficialSlipCard:
                  await ref
                      .read(aiAssistantProvider.notifier)
                      .generateAndPrintOfficialSlip(
                    student: student,
                    slipCategory: action.slipCategory ?? 'COURSE_FORM',
                  );
                  break;

                case AgentToolActionType.none:
                  break;
              }
            },
            icon: Icon(
              action.type == AgentToolActionType.printOfficialSlipCard
                  ? Icons.print_rounded
                  : Icons.bolt_rounded,
            ),
            label: action.actionButtonLabel,
          ),
        ],
      ),
    );
  }
}