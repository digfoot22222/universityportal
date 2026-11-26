enum RemitaPaymentStatus { pending, paid, failed }

class RemitaTransaction {
  final String id;
  final String rrr;
  final String studentMatric;
  final String studentName;
  final String feeCategory;
  final String description;
  final double amountNaira;
  final double platformConvenienceFee;
  final RemitaPaymentStatus status;
  final DateTime generatedAt;
  final DateTime? paidAt;
  final String bankChannel;
  final String? linkedRoomId;

  const RemitaTransaction({
    this.id = '',
    required this.rrr,
    required this.studentMatric,
    required this.studentName,
    required this.feeCategory,
    required this.description,
    required this.amountNaira,
    this.platformConvenienceFee = 500.0,
    required this.status,
    required this.generatedAt,
    this.paidAt,
    this.bankChannel = 'Remita Inline Gateway',
    this.linkedRoomId,
  });

  String get payerName => studentName;
  String get payerMatric => studentMatric;
  String get feeType => description.isNotEmpty ? description : feeCategory;
  DateTime get createdAt => generatedAt;

  RemitaTransaction copyWith({
    RemitaPaymentStatus? status,
    DateTime? paidAt,
    String? bankChannel,
    String? linkedRoomId,
  }) {
    return RemitaTransaction(
      id: id,
      rrr: rrr,
      studentMatric: studentMatric,
      studentName: studentName,
      feeCategory: feeCategory,
      description: description,
      amountNaira: amountNaira,
      platformConvenienceFee: platformConvenienceFee,
      status: status ?? this.status,
      generatedAt: generatedAt,
      paidAt: paidAt ?? this.paidAt,
      bankChannel: bankChannel ?? this.bankChannel,
      linkedRoomId: linkedRoomId ?? this.linkedRoomId,
    );
  }
}