import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/hostel_model.dart';
import '../../../core/models/student_model.dart';
import '../../admin_console/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';

class CharacterMatchResult {
  final HostelRoom room;
  final int compatibilityScore;
  final String matchSummary;

  const CharacterMatchResult({
    required this.room,
    required this.compatibilityScore,
    required this.matchSummary,
  });
}

class HostelState {
  final List<HostelRoom> rooms;
  final String selectedZoneFilter;
  final List<CharacterMatchResult> characterMatches;
  final String? lockedRoomId;
  final String? lockedBunkLabel;
  final DateTime? lockExpiresAt;

  const HostelState({
    required this.rooms,
    this.selectedZoneFilter = 'ALL',
    this.characterMatches = const [],
    this.lockedRoomId,
    this.lockedBunkLabel,
    this.lockExpiresAt,
  });

  List<HostelRoom> visibleRoomsForUser(StudentAccount? user) {
    return rooms.where((r) {
      if (user != null &&
          user.role != UserRole.admin &&
          r.allowedGender != user.gender) {
        return false;
      }
      if (selectedZoneFilter != 'ALL' &&
          !r.zone.toLowerCase().contains(selectedZoneFilter.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  HostelState copyWith({
    List<HostelRoom>? rooms,
    String? selectedZoneFilter,
    List<CharacterMatchResult>? characterMatches,
    String? lockedRoomId,
    String? lockedBunkLabel,
    DateTime? lockExpiresAt,
  }) {
    return HostelState(
      rooms: rooms ?? this.rooms,
      selectedZoneFilter: selectedZoneFilter ?? this.selectedZoneFilter,
      characterMatches: characterMatches ?? this.characterMatches,
      lockedRoomId: lockedRoomId ?? this.lockedRoomId,
      lockedBunkLabel: lockedBunkLabel ?? this.lockedBunkLabel,
      lockExpiresAt: lockExpiresAt ?? this.lockExpiresAt,
    );
  }
}

class HostelNotifier extends StateNotifier<HostelState> {
  final Ref _ref;

  HostelNotifier(this._ref)
      : super(HostelState(rooms: _seed18GenderHostels()));

  void setZoneFilter(String zone) {
    state = state.copyWith(selectedZoneFilter: zone);
  }

  void runCharacterMatchmaker({
    required StudentAccount student,
    String sleepHabit = 'Early Riser',
    String studyHabit = 'Quiet Study',
    String cleanliness = 'Very Neat',
    String noiseTolerance = 'Low Noise',
  }) {
    final eligible = state.rooms
        .where((r) =>
    student.role == UserRole.admin || r.allowedGender == student.gender)
        .take(3)
        .toList();

    final results = eligible.asMap().entries.map((entry) {
      final idx = entry.key;
      final room = entry.value;
      return CharacterMatchResult(
        room: room,
        compatibilityScore: 97 - (idx * 3),
        matchSummary:
        'Matched with compatible ${student.gender.name.toUpperCase()} scholar sharing "$sleepHabit", "$studyHabit" & "$noiseTolerance" preferences.',
      );
    }).toList();

    state = state.copyWith(characterMatches: results);
  }

  void reserveBunkWith15MinLock({
    required String roomId,
    required String bunkLabel,
    required StudentAccount student,
  }) {
    final holdMinutes = student.isAiProSubscriber ? 30 : 15;
    final updatedRooms = state.rooms.map((room) {
      if (room.id != roomId) return room;
      final updatedBeds = room.beds.map((bed) {
        if (bed.label == bunkLabel) {
          return bed.copyWith(
            isOccupied: true,
            occupantName: '${student.fullName} (Hold${holdMinutes}m)',
          );
        }
        return bed;
      }).toList();
      return room.copyWith(beds: updatedBeds);
    }).toList();

    final updatedStudent = student.copyWith(
      assignedRoomId: roomId,
      assignedBunkLabel: bunkLabel,
    );

    _ref.read(adminProvider.notifier).updateStudentRecord(updatedStudent);
    _ref.read(authProvider.notifier).syncUpdatedUser(updatedStudent);

    state = state.copyWith(
      rooms: updatedRooms,
      lockedRoomId: roomId,
      lockedBunkLabel: bunkLabel,
      lockExpiresAt: DateTime.now().add(Duration(minutes: holdMinutes)),
    );
  }

  void confirmPaymentForLockedBunk(StudentAccount student) {
    final targetRoomId =
        state.lockedRoomId ?? student.assignedRoomId ?? 'M-ZIK-101';
    final targetBunk =
        state.lockedBunkLabel ?? student.assignedBunkLabel ?? 'Bunk A (Lower)';

    final updatedRooms = state.rooms.map((room) {
      if (room.id != targetRoomId) return room;
      final updatedBeds = room.beds.map((bed) {
        if (bed.label == targetBunk) {
          return bed.copyWith(
            isOccupied: true,
            occupantName: '${student.fullName} (CLEARED)',
          );
        }
        return bed;
      }).toList();
      return room.copyWith(beds: updatedBeds);
    }).toList();

    final updatedStudent = student.copyWith(
      assignedRoomId: targetRoomId,
      assignedBunkLabel: targetBunk,
    );

    _ref.read(adminProvider.notifier).updateStudentRecord(updatedStudent);
    _ref.read(authProvider.notifier).syncUpdatedUser(updatedStudent);

    state = state.copyWith(rooms: updatedRooms);
  }

  static List<HostelRoom> _seed18GenderHostels() {
    List<BedSlot> defaultBeds(String roommateName) => [
      const BedSlot(id: 'b1', label: 'Bunk A (Lower)', isOccupied: false),
      BedSlot(
        id: 'b2',
        label: 'Bunk A (Upper)',
        isOccupied: true,
        occupantName: roommateName,
      ),
      const BedSlot(id: 'b3', label: 'Bunk B (Lower)', isOccupied: false),
      const BedSlot(id: 'b4', label: 'Bunk B (Upper)', isOccupied: false),
    ];

    const defaultHotspots = [
      VirtualHotspot(
        id: 'hs_1',
        title: '24/7 Solar Inverter & Reading Desk',
        description:
        'Dedicated pure-sine solar backup socket + ergonomic study desk.',
        dx: 0.28,
        dy: 0.45,
      ),
      VirtualHotspot(
        id: 'hs_2',
        title: 'Starlink Campus Wi-Fi 6 Access Point',
        description: 'High-speed symmetrical academic & research bandwidth.',
        dx: 0.72,
        dy: 0.35,
      ),
    ];

    const maleHalls = [
      ('M-ZIK-101', 'Zik Heritage Hall', 'Room 101', 'North Campus', 'Faculty of Computing', 'Emeka Nwosu (300L CSC)'),
      ('M-TBW-102', 'Tafawa Balewa Executive Hostel', 'Room 102', 'Central Wing', 'Faculty of Engineering', 'Sadiq Abubakar (400L EEE)'),
      ('M-SBH-103', 'Sultan Bello Scholars Lodge', 'Room 103', 'Medical Village', 'College of Medicine', 'Musa Danjuma (300L MED)'),
      ('M-ABH-104', 'Ahmadu Bello Honors Wing', 'Room 104', 'North Campus', 'Faculty of Science', 'Tunde Bakare (200L CSC)'),
      ('M-AWO-105', 'Awolowo Innovation Hall', 'Room 105', 'Tech Park', 'Software Engineering', 'David Osei (300L SEN)'),
      ('M-AZK-106', 'Azikiwe Premier Annex', 'Room 106', 'South Campus', 'Management Sciences', 'Kelechi Eze (400L ACC)'),
      ('M-MMT-107', 'Murtala Mohammed Tech Hostel', 'Room 107', 'Tech Park', 'Cybersecurity Wing', 'Ibrahim Lawal (300L CYB)'),
      ('M-AMK-108', 'Aminu Kano Classic Hall', 'Room 108', 'Central Wing', 'Mechanical Engineering', 'Umar Farouk (200L MEE)'),
      ('M-HMG-109', 'Herbert Macaulay Graduate Suites', 'Suite 109', 'Medical Village', 'Pharmacy Faculty', 'Segun Adeyemi (500L PHM)'),
      ('M-NIC-110', 'Nnamdi Independence Courtyard', 'Room 110', 'South Campus', 'Civil Engineering', 'Chukwuma Obi (400L CVE)'),
    ];

    const femaleHalls = [
      ('F-AMINA-101', 'Queen Amina Royal Hall', 'Room 101', 'Medical Village', 'College of Health Sciences', 'Zainab Bello (200L NSC)'),
      ('F-MOR-102', 'Moremi Executive Suites', 'Suite 102', 'Medical Village', 'College of Medicine', 'Chioma Nnamdi (300L MED)'),
      ('F-FRK-103', 'Funmilayo Ransome-Kuti Lodge', 'Room 103', 'South Campus', 'Communication & Arts', 'Bisi Adewale (400L MAC)'),
      ('F-IDIA-104', 'Queen Idia Honors Pavilion', 'Room 104', 'Central Wing', 'Faculty of Pharmacy', 'Osasere Igbinosa (300L PHM)'),
      ('F-MEK-105', 'Margaret Ekpo Scholars Residence', 'Room 105', 'South Campus', 'Accounting & Finance', 'Ngozi Okonkwo (200L ACC)'),
      ('F-GAW-106', 'Grace Alele-Williams STEM Hall', 'Room 106', 'North Campus', 'Faculty of Computing', 'Fatima Garba (300L CSC)'),
      ('F-LDK-107', 'Ladi Kwali Creative Annex', 'Room 107', 'Central Wing', 'Business Admin', 'Hauwa Suleiman (200L BUS)'),
      ('F-FLN-108', 'Flora Nwapa Heritage Court', 'Room 108', 'Medical Village', 'Nursing Science', 'Adaeze Umeh (400L NSC)'),
    ];

    final list = <HostelRoom>[];

    for (final m in maleHalls) {
      list.add(
        HostelRoom(
          id: m.$1,
          blockName: m.$2,
          roomNumber: m.$3,
          allowedGender: StudentGender.male,
          zone: m.$4,
          proximityFaculty: m.$5,
          annualFeeNaira: 85000,
          panoramaImageUrl:
          'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=1200',
          noiseLevel: 'Quiet Study Zone',
          hasEnsuite: true,
          hasSolarInverter: true,
          hasHighSpeedWifi: true,
          wheelChairAccessible: true,
          hotspots: defaultHotspots,
          beds: defaultBeds(m.$6),
        ),
      );
    }

    for (final f in femaleHalls) {
      list.add(
        HostelRoom(
          id: f.$1,
          blockName: f.$2,
          roomNumber: f.$3,
          allowedGender: StudentGender.female,
          zone: f.$4,
          proximityFaculty: f.$5,
          annualFeeNaira: 85000,
          panoramaImageUrl:
          'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=1200',
          noiseLevel: 'Quiet Study Zone',
          hasEnsuite: true,
          hasSolarInverter: true,
          hasHighSpeedWifi: true,
          wheelChairAccessible: true,
          hotspots: defaultHotspots,
          beds: defaultBeds(f.$6),
        ),
      );
    }

    return list;
  }
}

final hostelProvider =
StateNotifierProvider<HostelNotifier, HostelState>((ref) {
  return HostelNotifier(ref);
});