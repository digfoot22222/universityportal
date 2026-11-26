import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/hostel_provider.dart';
import 'panorama_viewer_modal.dart';

class VirtualExplorerScreen extends ConsumerStatefulWidget {
  final bool isAdmin;
  final VoidCallback onNavigateToPayments;

  const VirtualExplorerScreen({
    super.key,
    this.isAdmin = false,
    required this.onNavigateToPayments,
  });

  @override
  ConsumerState<VirtualExplorerScreen> createState() =>
      _VirtualExplorerScreenState();
}

class _VirtualExplorerScreenState extends ConsumerState<VirtualExplorerScreen> {
  String _sleepHabit = 'Early Riser';
  String _studyHabit = 'Quiet Study';

  @override
  Widget build(BuildContext context) {
    final hostelState = ref.watch(hostelProvider);
    final student = ref.watch(authProvider).currentUser;
    final visibleRooms = hostelState.visibleRoomsForUser(student);
    final isFemale = student?.gender == StudentGender.female;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '360° Smart Campus Housing & AI Roommate Matchmaker',
                          style: TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          widget.isAdmin
                              ? 'Admin Oversight Mode: Viewing all 18 Halls (10 Male + 8 Female)'
                              : 'Strict Gender Routing Active: Showing ${isFemale ? "8 Female Halls" : "10 Male Halls"} for ${student?.fullName ?? ""}',
                          style: const TextStyle(
                            color: AppColors.electricIndigo,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (student?.assignedRoomId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldPulse.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.emeraldPulse),
                        ),
                        child: Text(
                          'Allocated: ${student!.assignedRoomId} • ${student.assignedBunkLabel ?? "Bunk A"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.emeraldPulse,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                        AppColors.electricMagenta.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Personality & Roommate Compatibility Matchmaker',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 190,
                            child: DropdownButtonFormField<String>(
                              initialValue: _sleepHabit,
                              decoration: const InputDecoration(
                                  labelText: 'Sleep Schedule'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Early Riser',
                                    child: Text('Early Riser')),
                                DropdownMenuItem(
                                    value: 'Night Owl',
                                    child: Text('Night Owl')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _sleepHabit = v);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 190,
                            child: DropdownButtonFormField<String>(
                              initialValue: _studyHabit,
                              decoration: const InputDecoration(
                                  labelText: 'Study Routine'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Quiet Study',
                                    child: Text('Quiet Study')),
                                DropdownMenuItem(
                                    value: 'Group Brainstorming',
                                    child: Text('Group Brainstorming')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _studyHabit = v);
                              },
                            ),
                          ),
                          PrismGradientButton(
                            onPressed: student == null
                                ? null
                                : () {
                              ref
                                  .read(hostelProvider.notifier)
                                  .runCharacterMatchmaker(
                                student: student,
                                sleepHabit: _sleepHabit,
                                studyHabit: _studyHabit,
                              );
                            },
                            icon: const Icon(Icons.psychology),
                            label: 'Find Compatible Roommates',
                          ),
                        ],
                      ),
                      if (hostelState.characterMatches.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...hostelState.characterMatches.map(
                              (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• ${m.compatibilityScore}% Match — ${m.room.blockName} (${m.room.roomNumber}): ${m.matchSummary}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emeraldPulse,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'ALL',
                    'North Campus',
                    'Medical Village',
                    'Tech Park',
                    'Central Wing',
                    'South Campus',
                  ].map((zone) {
                    return ChoiceChip(
                      label: Text(zone),
                      selected: hostelState.selectedZoneFilter == zone,
                      onSelected: (_) => ref
                          .read(hostelProvider.notifier)
                          .setZoneFilter(zone),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: visibleRooms.map((room) {
              final freeBunks = room.beds.where((b) => !b.isOccupied).length;
              return SizedBox(
                width: 360,
                child: PrismGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            backgroundColor:
                            room.allowedGender == StudentGender.female
                                ? Colors.pink.withValues(alpha: 0.14)
                                : AppColors.cyberBlue
                                .withValues(alpha: 0.14),
                            label: Text(
                              '${room.allowedGender.name.toUpperCase()} HALL • ${room.zone}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 11),
                            ),
                          ),
                          Text(
                            '$freeBunks / ${room.beds.length} Bunks Free',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.emeraldPulse,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${room.blockName} (${room.roomNumber})',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Near ${room.proximityFaculty} • ₦${NumberFormat('#,##0').format(room.annualFeeNaira)}/Session',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.mutedSlate),
                      ),
                      const SizedBox(height: 12),
                      PrismGradientButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => PanoramaViewerModal(
                              room: room,
                            ),
                          );
                        },
                        icon: const Icon(Icons.vrpano_outlined),
                        label: 'Inspect 360° Room & Pick Bunk',
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}