import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/remita_transaction.dart';
import '../../../core/models/student_model.dart';
import '../../admin_console/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../hostel_virtual/providers/hostel_provider.dart';

class PaymentState {
  final List<RemitaTransaction> transactions;
  final bool isProcessingCheckout;
  final double vendorPlatformSplitRevenue;
  final int employerVerificationCreditsSold;

  const PaymentState({
    required this.transactions,
    this.isProcessingCheckout = false,
    this.vendorPlatformSplitRevenue = 425000.0,
    this.employerVerificationCreditsSold = 38,
  });

  PaymentState copyWith({
    List<RemitaTransaction>? transactions,
    bool? isProcessingCheckout,
    double? vendorPlatformSplitRevenue,
    int? employerVerificationCreditsSold,
  }) {
    return PaymentState(
      transactions: transactions ?? this.transactions,
      isProcessingCheckout: isProcessingCheckout ?? this.isProcessingCheckout,
      vendorPlatformSplitRevenue:
      vendorPlatformSplitRevenue ?? this.vendorPlatformSplitRevenue,
      employerVerificationCreditsSold: employerVerificationCreditsSold ??
          this.employerVerificationCreditsSold,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final Ref _ref;

  PaymentNotifier(this._ref)
      : super(
    PaymentState(
      transactions: [
        RemitaTransaction(
          id: 'tx_pro_seed_01',
          rrr: '3409-8821-7740',
          studentName: 'Chinedu Okafor',
          studentMatric: 'CSC/2023/0419',
          feeCategory: 'Tuition & AI Pro Bundle',
          description: '2026/2027 Tuition + AI Pro Unlimited Bundle',
          amountNaira: 146500,
          platformConvenienceFee: 2500,
          status: RemitaPaymentStatus.paid,
          generatedAt: DateTime.now().subtract(const Duration(days: 3)),
          paidAt: DateTime.now().subtract(const Duration(days: 3)),
          bankChannel: 'Remita Instant USSD / Card Gateway (Code 00)',
        ),
      ],
    ),
  );

  String _generate12DigitRrr() {
    final rnd = Random();
    final p1 = 1000 + rnd.nextInt(8999);
    final p2 = 1000 + rnd.nextInt(8999);
    final p3 = 1000 + rnd.nextInt(8999);
    return '$p1-$p2-$p3';
  }

  RemitaTransaction generateRrr({
    required StudentAccount student,
    required String feeType,
    required double amountNaira,
    String? linkedRoomId,
  }) {
    final convenienceSplit =
    (amountNaira * 0.015).clamp(250.0, 2500.0).roundToDouble();

    final tx = RemitaTransaction(
      id: const Uuid().v4(),
      rrr: _generate12DigitRrr(),
      studentName: student.fullName,
      studentMatric: student.matricNumber,
      feeCategory: feeType,
      description: feeType,
      amountNaira: amountNaira,
      platformConvenienceFee: convenienceSplit,
      status: RemitaPaymentStatus.pending,
      generatedAt: DateTime.now(),
      linkedRoomId: linkedRoomId,
    );

    state = state.copyWith(transactions: [tx, ...state.transactions]);

    _ref.read(adminProvider.notifier).logSecurityEvent(
      actor: student.matricNumber,
      action: 'REMITA_RRR_GENERATED',
      target:
      'RRR=${tx.rrr} • $feeType (₦${amountNaira.toStringAsFixed(0)} + ₦${convenienceSplit.toStringAsFixed(0)} Split)',
    );

    return tx;
  }

  RemitaTransaction generateRemitaInvoice({
    required StudentAccount student,
    required String feeCategory,
    required String description,
    required double amountNaira,
    String? linkedRoomId,
  }) {
    return generateRrr(
      student: student,
      feeType: description.isNotEmpty ? description : feeCategory,
      amountNaira: amountNaira,
      linkedRoomId: linkedRoomId,
    );
  }

  Future<RemitaTransaction?> confirmRemitaPayment(
      String rrr,
      StudentAccount student, {
        String channel = 'Remita Inline Card / Instant Transfer (Code 00)',
      }) async {
    state = state.copyWith(isProcessingCheckout: true);
    await Future.delayed(const Duration(milliseconds: 550));

    RemitaTransaction? confirmedTx;
    double addedSplit = 0;

    final updatedList = state.transactions.map((tx) {
      if (tx.rrr == rrr) {
        confirmedTx = tx.copyWith(
          status: RemitaPaymentStatus.paid,
          paidAt: DateTime.now(),
          bankChannel: channel,
        );
        addedSplit = tx.platformConvenienceFee;
        return confirmedTx!;
      }
      return tx;
    }).toList();

    state = state.copyWith(
      transactions: updatedList,
      isProcessingCheckout: false,
      vendorPlatformSplitRevenue:
      state.vendorPlatformSplitRevenue + addedSplit,
    );

    if (confirmedTx != null) {
      final lowerFee = confirmedTx!.feeType.toLowerCase();

      if (lowerFee.contains('ai pro')) {
        final upgradedStudent = student.copyWith(isAiProSubscriber: true);
        _ref.read(adminProvider.notifier).updateStudentRecord(upgradedStudent);
        _ref.read(authProvider.notifier).syncUpdatedUser(upgradedStudent);
        _ref.read(adminProvider.notifier).logSecurityEvent(
          actor: student.matricNumber,
          action: 'AI_PRO_GOLD_CROWN_ACTIVATED',
          target:
          'RRR=${confirmedTx!.rrr} • Unlimited AI & PDF Slips Unlocked',
        );
      }

      if (lowerFee.contains('hostel') || confirmedTx!.linkedRoomId != null) {
        _ref.read(hostelProvider.notifier).confirmPaymentForLockedBunk(student);
      }

      _ref.read(adminProvider.notifier).logSecurityEvent(
        actor: student.matricNumber,
        action: 'REMITA_PAYMENT_VERIFIED_00',
        target:
        'RRR=${confirmedTx!.rrr} • Split Revenue +₦${addedSplit.toStringAsFixed(0)}',
      );
    }

    return confirmedTx;
  }

  void recordEmployerVerificationCreditSale() {
    state = state.copyWith(
      employerVerificationCreditsSold:
      state.employerVerificationCreditsSold + 1,
      vendorPlatformSplitRevenue: state.vendorPlatformSplitRevenue + 2500.0,
    );
  }
}

final paymentProvider =
StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref);
});