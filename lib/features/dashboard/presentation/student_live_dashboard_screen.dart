import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/remita_transaction.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../academics_courses/providers/academics_provider.dart';
import '../../ai_assistant/providers/ai_assistant_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payments_remita/providers/payment_provider.dart';

class StudentLiveDashboardScreen extends ConsumerStatefulWidget {
  final ValueChanged<int> onSwitchTab;

  const StudentLiveDashboardScreen({
    super.key,
    required this.onSwitchTab,
  });

  @override
  ConsumerState<StudentLiveDashboardScreen> createState() =>
      _StudentLiveDashboardScreenState();
}

class _StudentLiveDashboardScreenState
    extends ConsumerState<StudentLiveDashboardScreen> {
  final _quickAiController = TextEditingController();

  @override
  void dispose() {
    _quickAiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(authProvider).currentUser;
    final academics = ref.watch(academicsProvider);
    final payments = ref.watch(paymentProvider);
    final aiState = ref.watch(aiAssistantProvider);

    if (student == null) return const SizedBox.shrink();

    final isPro = student.isAiProSubscriber;
    final liveGpa = student.computedLiveGpa;
    final registeredCourses = academics.catalog
        .where((c) => student.registeredCourseCodes.contains(c.code))
        .toList();
    final totalUnits =
    registeredCourses.fold<int>(0, (sum, c) => sum + c.creditUnits);

    final studentTx = payments.transactions
        .where((t) => t.studentMatric == student.matricNumber)
        .toList();
    final totalPaid = studentTx
        .where((t) => t.status == RemitaPaymentStatus.paid)
        .fold<double>(0, (sum, t) => sum + t.amountNaira);
    final pendingCount = studentTx
        .where((t) => t.status == RemitaPaymentStatus.pending)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Live Student Identity & Academic Snapshot Header
          PrismGlassCard(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 14,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: isPro
                          ? const Color(0xFFFFD700)
                          : AppColors.electricIndigo,
                      backgroundImage: student.profilePhotoBytes != null
                          ? MemoryImage(student.profilePhotoBytes!)
                          : null,
                      child: student.profilePhotoBytes == null
                          ? Text(
                        student.fullName[0],
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isPro
                              ? AppColors.deepObsidian
                              : Colors.white,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Welcome back, ${student.fullName}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (isPro) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.workspace_premium_rounded,
                                  color: Color(0xFFD97706), size: 22),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${student.matricNumber} •${student.department} • ${student.level} (${student.semester})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedSlate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _statusPill(
                              'Gender: ${student.gender.name.toUpperCase()}',
                              AppColors.cyberBlue,
                            ),
                            _statusPill(
                              totalPaid > 0
                                  ? 'Bursary: Cleared'
                                  : 'Bursary: Pending',
                              totalPaid > 0
                                  ? AppColors.emeraldPulse
                                  : AppColors.amberFlare,
                            ),
                            _statusPill(
                              student.courseFormApproved
                                  ? 'Course Form: Senate Approved'
                                  : 'Course Form: Draft',
                              student.courseFormApproved
                                  ? AppColors.emeraldPulse
                                  : AppColors.electricIndigo,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Live CGPA Gauge Box
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LIVE COMPUTED CGPA',
                        style: TextStyle(
                          color: AppColors.aquaMint,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${liveGpa.toStringAsFixed(2)} / 5.00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        liveGpa >= 4.5
                            ? 'First Class Honours Standing'
                            : (liveGpa >= 3.5
                            ? 'Second Class Upper (2:1)'
                            : 'Good Academic Standing'),
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. AI Copilot Live Command Strip
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: AppColors.electricMagenta),
                        SizedBox(width: 8),
                        Text(
                          'AI Campus Copilot — Instant Command Strip',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    AiTierCrownBadge(
                      isPro: isPro,
                      freePromptsRemaining: aiState.remainingFreePrompts(student),
                      onTapUpgrade: () {
                        ref
                            .read(aiAssistantProvider.notifier)
                            .sendPrompt('Upgrade my account to AI Pro');
                        widget.onSwitchTab(1);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quickAiController,
                        onSubmitted: (val) {
                          if (val.trim().isEmpty) return;
                          ref
                              .read(aiAssistantProvider.notifier)
                              .sendPrompt(val);
                          _quickAiController.clear();
                          widget.onSwitchTab(1);
                        },
                        decoration: const InputDecoration(
                          hintText:
                          'Type a command (e.g. "Print my Course Form", "Pay fees", "Explain CSC 305")...',
                          prefixIcon: Icon(Icons.bolt),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PrismGradientButton(
                      onPressed: () {
                        final text = _quickAiController.text.trim();
                        if (text.isNotEmpty) {
                          ref
                              .read(aiAssistantProvider.notifier)
                              .sendPrompt(text);
                          _quickAiController.clear();
                        }
                        widget.onSwitchTab(1);
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: 'Open AI Copilot',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Three Live Campus Cards (Courses, Hostel, Remita)
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 360,
                child: PrismGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.menu_book_rounded,
                              color: AppColors.electricIndigo),
                          SizedBox(width: 8),
                          Text(
                            'Courses & Today\'s Timetable',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${registeredCourses.length} Registered Courses • $totalUnits / 24 NUC Units',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldPulse,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• 09:00 AM — Core Departmental Lecture (Main Auditorium)\n• 02:00 PM — Practical Lab / Clinical Seminar',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedSlate,
                            height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => widget.onSwitchTab(2),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Manage Courses & Print CRF'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 360,
                child: PrismGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.apartment_rounded,
                              color: AppColors.electricMagenta),
                          SizedBox(width: 8),
                          Text(
                            'Smart Hostel & Bunk Allocation',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        student.assignedRoomId != null
                            ? 'Room ${student.assignedRoomId} •${student.assignedBunkLabel ?? "Bunk A"}'
                            : 'No Bunk Allocated Yet (${student.gender == StudentGender.female ? "8 Female Halls" : "10 Male Halls"} Open)',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: student.assignedRoomId != null
                              ? AppColors.emeraldPulse
                              : AppColors.amberFlare,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• 96% AI Roommate Lifestyle Compatibility\n• 24/7 Solar Inverter + Starlink Campus Wi-Fi',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedSlate,
                            height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => widget.onSwitchTab(4),
                        icon: const Icon(Icons.vrpano_outlined, size: 16),
                        label: const Text('Inspect 360° Rooms & Match'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 360,
                child: PrismGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              color: AppColors.emeraldPulse),
                          SizedBox(width: 8),
                          Text(
                            'Remita Treasury Wallet',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Total Verified Paid: ₦${NumberFormat('#,##0').format(totalPaid)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.emeraldPulse,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pendingCount > 0
                            ? '• $pendingCount Pending RRR Invoice awaiting checkout\n• Instant Code 00 Treasury Receipt Verification'
                            : '• Zero Outstanding RRR Invoices\n• Instant QR Receipt & PDF Slip Ready',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedSlate,
                            height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => widget.onSwitchTab(5),
                        icon: const Icon(Icons.payments_outlined, size: 16),
                        label: const Text('Open Remita Billing & Slips'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4. Campus Announcements & Live Academic Calendar Feed
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Senate Academic Calendar & Campus Bulletins (2026/2027)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                _bulletinRow(
                  'NUC Course Registration Portal Closing Soon',
                  'Ensure your Course Form is stamped & printed before Friday 11:59 PM WAT.',
                  AppColors.electricIndigo,
                ),
                const Divider(),
                _bulletinRow(
                  '24/7 Guidance, Counseling & Carryover Clinic Open',
                  'Book confidential video or in-person advising sessions anytime from the Counseling tab.',
                  AppColors.electricMagenta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _bulletinRow(String title, String subtitle, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.campaign_rounded, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.mutedSlate)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}