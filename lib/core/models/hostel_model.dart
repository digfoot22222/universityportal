import 'student_model.dart';

class BedSpaceSlot {
  final String bedId;
  final String label;
  final bool isOccupied;
  final String? occupantName;
  final int compatibilityWithUser;
  final String? lockedByMatric;
  final DateTime? lockExpiresAt;

  const BedSpaceSlot({
    String? bedId,
    String? id,
    required this.label,
    required this.isOccupied,
    this.occupantName,
    this.compatibilityWithUser = 94,
    this.lockedByMatric,
    this.lockExpiresAt,
  }) : bedId = bedId ?? id ?? 'bed_1';

  String get id => bedId;

  String? get occupantSummary =>
      occupantName != null ? 'Occupied by $occupantName' : null;

  BedSpaceSlot copyWith({
    bool? isOccupied,
    String? occupantName,
    int? compatibilityWithUser,
    String? lockedByMatric,
    DateTime? lockExpiresAt,
  }) {
    return BedSpaceSlot(
      bedId: bedId,
      label: label,
      isOccupied: isOccupied ?? this.isOccupied,
      occupantName: occupantName ?? this.occupantName,
      compatibilityWithUser:
      compatibilityWithUser ?? this.compatibilityWithUser,
      lockedByMatric: lockedByMatric ?? this.lockedByMatric,
      lockExpiresAt: lockExpiresAt ?? this.lockExpiresAt,
    );
  }
}

typedef BedSlot = BedSpaceSlot;

class HotspotPin {
  final String id;
  final String title;
  final String description;
  final double dx;
  final double dy;

  const HotspotPin({
    required this.id,
    required this.title,
    String? description,
    String? detail,
    required this.dx,
    required this.dy,
  }) : description = description ?? detail ?? '';

  String get detail => description;
}

typedef VirtualHotspot = HotspotPin;

class HostelRoom {
  final String id;
  final String blockName;
  final String roomNumber;
  final StudentGender allowedGender;
  final String zone;
  final String proximityFaculty;
  final double annualFeeNaira;
  final String panoramaImageUrl;
  final String noiseLevel;
  final bool hasEnsuite;
  final bool hasSolarInverter;
  final bool hasHighSpeedWifi;
  final bool wheelChairAccessible;
  final List<HotspotPin> hotspots;
  final List<BedSpaceSlot> beds;

  const HostelRoom({
    required this.id,
    required this.blockName,
    required this.roomNumber,
    required this.allowedGender,
    required this.zone,
    required this.proximityFaculty,
    required this.annualFeeNaira,
    required this.panoramaImageUrl,
    required this.noiseLevel,
    required this.hasEnsuite,
    required this.hasSolarInverter,
    required this.hasHighSpeedWifi,
    required this.wheelChairAccessible,
    required this.hotspots,
    required this.beds,
  });

  int get totalBeds => beds.length;
  int get availableBeds => beds.where((b) => !b.isOccupied).length;

  HostelRoom copyWith({
    List<BedSpaceSlot>? beds,
  }) {
    return HostelRoom(
      id: id,
      blockName: blockName,
      roomNumber: roomNumber,
      allowedGender: allowedGender,
      zone: zone,
      proximityFaculty: proximityFaculty,
      annualFeeNaira: annualFeeNaira,
      panoramaImageUrl: panoramaImageUrl,
      noiseLevel: noiseLevel,
      hasEnsuite: hasEnsuite,
      hasSolarInverter: hasSolarInverter,
      hasHighSpeedWifi: hasHighSpeedWifi,
      wheelChairAccessible: wheelChairAccessible,
      hotspots: hotspots,
      beds: beds ?? this.beds,
    );
  }
}

class RoomMatchResult {
  final HostelRoom room;
  final int compatibilityScore;
  final String matchReasons;

  const RoomMatchResult({
    required this.room,
    required this.compatibilityScore,
    String? matchReasons,
    String? reasoning,
    String? reason,
  }) : matchReasons = matchReasons ??
      reasoning ??
      reason ??
      'High roommate lifestyle and study schedule alignment.';

  String get reason => matchReasons;
  String get reasoning => matchReasons;
}