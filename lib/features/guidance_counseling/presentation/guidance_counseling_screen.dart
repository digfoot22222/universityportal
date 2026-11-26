import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/counseling_provider.dart';

class GuidanceCounselingScreen extends ConsumerStatefulWidget {
  const GuidanceCounselingScreen({super.key});

  @override
  ConsumerState<GuidanceCounselingScreen> createState() =>
      _GuidanceCounselingScreenState();
}

class _GuidanceCounselingScreenState
    extends ConsumerState<GuidanceCounselingScreen> {
  final _chatCtrl = TextEditingController();
  String _selectedMode = 'Confidential Video Call';

  @override
  void dispose() {
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counselingState = ref.watch(counselingProvider);
    final student = ref.watch(authProvider).currentUser;

    final liveGpa = student?.computedLiveGpa ?? 4.50;
    final needsEarlyWarning = liveGpa < 2.50;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite_rounded,
                        color: AppColors.electricMagenta, size: 26),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '24/7 Guidance, Counseling & Student Wellness Sanctuary',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Confidential AI academic/wellness advising, carryover recovery plans, and private 1-on-1 appointments with licensed university counselors.',
                  style: TextStyle(color: AppColors.mutedSlate, fontSize: 13),
                ),
                if (needsEarlyWarning) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amberFlare.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.amberFlare),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.amberFlare),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Academic Early-Warning Support: Your current GPA (${liveGpa.toStringAsFixed(2)}) qualifies for priority advisor coaching and credit-load optimization.',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 24/7 Confidential AI Counselor Chat
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confidential AI Academic & Wellness Counselor',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _topicChip('Help me plan carryover & CGPA recovery', student),
                    _topicChip('I feel overwhelmed by exam stress', student),
                    _topicChip('Career & scholarship advice for my department', student),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.electricIndigo.withValues(alpha: 0.2)),
                  ),
                  child: ListView.builder(
                    itemCount: counselingState.confidentialChat.length,
                    itemBuilder: (context, index) {
                      final msg = counselingState.confidentialChat[index];
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 580),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? AppColors.electricIndigo
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: msg.isUser
                                ? null
                                : Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: msg.isUser
                                      ? Colors.white
                                      : AppColors.deepObsidian,
                                  height: 1.4,
                                ),
                              ),
                              if (msg.showCrisisSupportBanner) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.crimsonAlert
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.crimsonAlert),
                                  ),
                                  child: const Text(
                                    '24/7 Campus Health & Crisis Support Line: +234-800-UNICORE-HELP • Walk-In Wing B Open 24 Hours.',
                                    style: TextStyle(
                                      color: AppColors.crimsonAlert,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatCtrl,
                        onSubmitted: (v) {
                          ref
                              .read(counselingProvider.notifier)
                              .sendConfidentialMessage(v, student);
                          _chatCtrl.clear();
                        },
                        decoration: const InputDecoration(
                          hintText:
                          'Share privately with your 24/7 AI Counselor...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PrismGradientButton(
                      onPressed: () {
                        ref
                            .read(counselingProvider.notifier)
                            .sendConfidentialMessage(_chatCtrl.text, student);
                        _chatCtrl.clear();
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: 'Send',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Human University Counselors Directory & 1-Tap Appointment Booking
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    const Text(
                      'Book Confidential 1-on-1 Session with Human University Counselors',
                      style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'Confidential Video Call',
                            label: Text('Video Call')),
                        ButtonSegment(
                            value: 'In-Person Office',
                            label: Text('In-Person')),
                      ],
                      selected: {_selectedMode},
                      onSelectionChanged: (v) =>
                          setState(() => _selectedMode = v.first),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...counselingState.counselors.map(
                      (c) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                          AppColors.electricIndigo.withValues(alpha: 0.25)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: 440,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: c.isOnlineNow
                                        ? AppColors.emeraldPulse
                                        : AppColors.amberFlare,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      c.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                              Text(c.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.electricIndigo,
                                      fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(c.specialization,
                                  style: const TextStyle(fontSize: 12)),
                              Text(
                                'Next Slot: ${c.nextAvailableSlot} • ${c.officeLocation}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.mutedSlate),
                              ),
                            ],
                          ),
                        ),
                        PrismGradientButton(
                          onPressed: student == null
                              ? null
                              : () {
                            ref
                                .read(counselingProvider.notifier)
                                .bookCounselorSession(
                              student: student,
                              counselor: c,
                              mode: _selectedMode,
                              topic: 'Academic & Wellness Advising',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.emeraldPulse,
                                content: Text(
                                  'Booked $_selectedMode with ${c.fullName} (${c.nextAvailableSlot})!',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.event_available),
                          label: 'Book Session',
                        ),
                      ],
                    ),
                  ),
                ),

                if (counselingState.bookings.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Your Confirmed Confidential Appointments:',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  ...counselingState.bookings.map(
                        (b) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle,
                          color: AppColors.emeraldPulse),
                      title: Text('${b.counselorName} (${b.mode})'),
                      subtitle: Text('Slot: ${b.slot} • Topic: ${b.topic}'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicChip(String prompt, StudentAccount? student) {
    return ActionChip(
      backgroundColor: Colors.white,
      label: Text(prompt, style: const TextStyle(fontSize: 12)),
      onPressed: () => ref
          .read(counselingProvider.notifier)
          .sendConfidentialMessage(prompt, student),
    );
  }
}