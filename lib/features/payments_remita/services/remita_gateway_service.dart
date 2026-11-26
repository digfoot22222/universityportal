import 'dart:math';
import '../../../core/models/remita_transaction.dart';

class RemitaCheckoutResult {
  final String responseCode; // '00' indicates verified Remita settlement
  final String transactionId;
  final String message;

  const RemitaCheckoutResult({
    required this.responseCode,
    required this.transactionId,
    required this.message,
  });
}

class RemitaGatewayService {
  /// Generates an authentic 12-digit Remita Retrieval Reference (XXXX-XXXX-XXXX)
  String generateRrrNumber() {
    final rand = Random();
    String fourDigits() => (1000 + rand.nextInt(9000)).toString();
    return '${fourDigits()}-${fourDigits()}-${fourDigits()}';
  }

  /// Simulates Remita Inline SDK / REST Webhook verification callback ('00' = Approved)
  Future<RemitaCheckoutResult> processInlinePayment(
      RemitaTransaction invoice) async {
    await Future.delayed(const Duration(milliseconds: 1100));
    return RemitaCheckoutResult(
      responseCode: '00',
      transactionId: 'RMT-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Approved by Remita Payment Gateway (RRR: ${invoice.rrr})',
    );
  }
}