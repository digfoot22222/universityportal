import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../../../core/models/hostel_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payments_remita/providers/payment_provider.dart';

class PanoramaViewerModal extends ConsumerStatefulWidget {
  final HostelRoom room;
  final VoidCallback? onProceedToRemita;

  const PanoramaViewerModal({
    super.key,
    required this.room,
    this.onProceedToRemita,
  });

  @override
  ConsumerState<PanoramaViewerModal> createState() =>
      _PanoramaViewerModalState();
}

class _PanoramaViewerModalState extends ConsumerState<PanoramaViewerModal> {
  HotspotPin? _activeHotspot;
  BedSpaceSlot? _selectedBunk;
  int _secondsRemaining = 900; // 15-minute bed lock countdown
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _selectBunk(BedSpaceSlot bed) {
    if (bed.isOccupied) return;
    setState(() {
      _selectedBunk = bed;
      _secondsRemaining = 900;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _selectedBunk = null);
      }
    });
  }

  String get _formattedTimer {
    final mins = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1020, maxHeight: 740),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.threesixty,
                      color: AppColors.electricMagenta),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '360° Tour & Bunk Seat Map • ${room.blockName} (${room.roomNumber})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  if (_selectedBunk != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.amberFlare.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.amberFlare),
                      ),
                      child: Text(
                        'Bunk Locked: $_formattedTimer',
                        style: const TextStyle(
                          color: AppColors.deepObsidian,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Split View: 360 Panorama + Interactive Bunk-Bed Floor Map
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 760;
                  final panoramaSection = Stack(
                    children: [
                      PanoramaViewer(
                        animSpeed: 0.35,
                        sensorControl: SensorControl.orientation,
                        child: Image.network(
                          room.panoramaImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.deepObsidian,
                            alignment: Alignment.center,
                            child: const Text(
                              '360° Interactive Room View',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      ...room.hotspots.map(
                            (pin) => Positioned(
                          left: 20 + (pin.dx * 260),
                          top: 30 + (pin.dy * 180),
                          child: ActionChip(
                            backgroundColor: AppColors.electricIndigo,
                            avatar: const Icon(Icons.info_outline,
                                color: Colors.white, size: 15),
                            label: Text(
                              pin.title,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                            onPressed: () =>
                                setState(() => _activeHotspot = pin),
                          ),
                        ),
                      ),
                      if (_activeHotspot != null)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Card(
                            child: ListTile(
                              title: Text(_activeHotspot!.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              subtitle: Text(_activeHotspot!.detail),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setState(() => _activeHotspot = null),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );

                  final seatPickerSection = Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INTERACTIVE BUNK-BED FLOOR MAP',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: AppColors.electricIndigo,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap an available bunk to reserve & inspect occupant compatibility:',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.mutedSlate),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: room.beds.length,
                            itemBuilder: (context, idx) {
                              final bed = room.beds[idx];
                              final isSelected =
                                  _selectedBunk?.bedId == bed.bedId;
                              return GestureDetector(
                                onTap: () => _selectBunk(bed),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: bed.isOccupied
                                        ? Colors.grey.shade200
                                        : (isSelected
                                        ? AppColors.electricIndigo
                                        .withValues(alpha: 0.12)
                                        : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: bed.isOccupied
                                          ? Colors.grey.shade400
                                          : (isSelected
                                          ? AppColors.electricMagenta
                                          : AppColors.emeraldPulse),
                                      width: isSelected ? 2.2 : 1.4,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                bed.isOccupied
                                                    ? Icons.lock
                                                    : Icons.bed,
                                                size: 18,
                                                color: bed.isOccupied
                                                    ? Colors.grey
                                                    : AppColors.emeraldPulse,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                bed.label,
                                                style: const TextStyle(
                                                    fontWeight:
                                                    FontWeight.w800),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: bed.isOccupied
                                                  ? Colors.grey.shade600
                                                  : AppColors.emeraldPulse,
                                              borderRadius:
                                              BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              bed.isOccupied
                                                  ? 'OCCUPIED'
                                                  : (isSelected
                                                  ? 'SELECTED'
                                                  : 'AVAILABLE'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (bed.occupantSummary != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Occupant: ${bed.occupantSummary} (${bed.compatibilityWithUser ?? 90}% Match)',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.mutedSlate),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(flex: 6, child: panoramaSection),
                        Expanded(flex: 5, child: seatPickerSection),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(flex: 4, child: panoramaSection),
                      Expanded(flex: 5, child: seatPickerSection),
                    ],
                  );
                },
              ),
            ),

            // Bottom Booking Bar -> Proceed to Remita
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedBunk == null
                            ? 'Select an available bunk above to lock reservation'
                            : 'Selected: ${_selectedBunk!.label} • ₦${room.annualFeeNaira.toStringAsFixed(0)}/yr',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        '${room.availableBeds} of ${room.totalBeds} bunks available in Room ${room.roomNumber}',
                        style: const TextStyle(
                            color: AppColors.emeraldPulse, fontSize: 12),
                      ),
                    ],
                  ),
                  PrismGradientButton(
                    onPressed: _selectedBunk == null
                        ? null
                        : () {
                      final student = ref.read(authProvider).currentUser;
                      if (student != null) {
                        ref
                            .read(paymentProvider.notifier)
                            .generateRemitaInvoice(
                          student: student,
                          feeCategory: 'Hostel Accommodation Fee',
                          description:
                          '${room.blockName} • Room ${room.roomNumber} (${_selectedBunk!.label})',
                          amountNaira: room.annualFeeNaira,
                          linkedRoomId: room.id,
                        );
                      }
                      Navigator.of(context).pop();
                      widget.onProceedToRemita?.call();
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: 'Proceed to Remita Payment',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}