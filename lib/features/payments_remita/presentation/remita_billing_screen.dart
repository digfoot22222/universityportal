import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/remita_transaction.dart';
import '../../../core/theme/app_theme.dart';
import '../../ai_assistant/providers/ai_assistant_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import 'official_receipt_dialog.dart';

class RemitaBillingScreen extends ConsumerStatefulWidget {
  const RemitaBillingScreen({super.key});

  @override
  ConsumerState<RemitaBillingScreen> createState() =>
      _RemitaBillingScreenState();
}

class _RemitaBillingScreenState extends ConsumerState<RemitaBillingScreen> {
  String _selectedFeeType = '2026/2027 Undergraduate Tuition & ICT Levy';
  double _selectedAmount = 145000;

  static const Map<String, double> _universityFeeSchedule = {
    'AI Pro Semester Unlimited Subscription': 1500,
    '2026/2027 Undergraduate Tuition & ICT Levy': 145000,
    'Smart Hostel Accommodation Fee (2026/2027)': 85000,
    'NUC Course Registration & Departmental Dues': 12500,
    'Freshman Acceptance & Biometric ID Fee': 35000,
    'Official Senate Transcript & QR Verification': 15000,
  };

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final student = ref.watch(authProvider).currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + SaaS Revenue Split Banner
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remita Treasury Gateway & SaaS Monetization Engine',
                          style: TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Generate official 12-digit Remita RRRs, pay inline, and print QR-verified treasury receipts.',
                          style: TextStyle(
                              color: AppColors.mutedSlate, fontSize: 13),
                        ),
                      ],
                    ),
                    if (student != null && !student.isAiProSubscriber)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: AppColors.deepObsidian,
                        ),
                        onPressed: () {
                          final tx = ref
                              .read(paymentProvider.notifier)
                              .generateRrr(
                            student: student,
                            feeType:
                            'AI Pro Semester Unlimited Subscription',
                            amountNaira: 1500,
                          );
                          ref
                              .read(paymentProvider.notifier)
                              .confirmRemitaPayment(tx.rrr, student);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.emeraldPulse,
                              content: Text(
                                'Gold Crown AI Pro Activated! Unlimited AI & PDF Slip Printing Unlocked.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: const Text(
                          '1-Click Upgrade to AI Pro (₦1,500)',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Fee Schedule Dropdown & RRR Generator
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 390,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedFeeType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select University Fee / SaaS Tariff',
                          prefixIcon: Icon(Icons.receipt_long),
                        ),
                        items: _universityFeeSchedule.keys
                            .map(
                              (fee) => DropdownMenuItem(
                            value: fee,
                            child: Text(
                              '$fee (₦${NumberFormat('#,##0').format(_universityFeeSchedule[fee])})',
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedFeeType = val;
                              _selectedAmount =
                                  _universityFeeSchedule[val] ?? 145000;
                            });
                          }
                        },
                      ),
                    ),
                    PrismGradientButton(
                      onPressed: student == null
                          ? null
                          : () {
                        final tx = ref
                            .read(paymentProvider.notifier)
                            .generateRrr(
                          student: student,
                          feeType: _selectedFeeType,
                          amountNaira: _selectedAmount,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Generated Remita RRR: ${tx.rrr} (₦${NumberFormat('#,##0').format(tx.amountNaira)})',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bolt),
                      label:
                      'Generate RRR (₦${NumberFormat('#,##0').format(_selectedAmount)})',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // RRR Transaction Ledger & Inline Checkout
          PrismGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Remita RRR Invoices, Split Settlements & Official Receipts',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...paymentState.transactions.map((tx) {
                  final isPaid = tx.status == RemitaPaymentStatus.paid;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPaid
                            ? AppColors.emeraldPulse.withValues(alpha: 0.45)
                            : AppColors.amberFlare.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: 400,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RRR: ${tx.rrr} • ${tx.feeType}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                              Text(
                                'Payer: ${tx.payerName} (${tx.payerMatric}) • Base: ₦${NumberFormat('#,##0').format(tx.amountNaira)} + Platform Split: ₦${NumberFormat('#,##0').format(tx.platformConvenienceFee)}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.mutedSlate),
                              ),
                              Text(
                                isPaid
                                    ? 'STATUS: PAID (Code 00) • ${tx.bankChannel}'
                                    : 'STATUS: PENDING REMITA CHECKOUT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isPaid
                                      ? AppColors.emeraldPulse
                                      : AppColors.amberFlare,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isPaid)
                          PrismGradientButton(
                            onPressed: (student == null ||
                                paymentState.isProcessingCheckout)
                                ? null
                                : () async {
                              await ref
                                  .read(paymentProvider.notifier)
                                  .confirmRemitaPayment(tx.rrr, student);
                            },
                            icon: const Icon(Icons.lock_open),
                            label: 'Pay Now via Remita',
                          )
                        else
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        OfficialReceiptDialog(transaction: tx),
                                  );
                                },
                                icon: const Icon(Icons.qr_code_2, size: 18),
                                label: const Text('View QR Receipt'),
                              ),
                              if (student != null && student.isAiProSubscriber)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.electricIndigo,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(aiAssistantProvider.notifier)
                                        .generateAndPrintOfficialSlip(
                                      student: student,
                                      slipCategory: 'REMITA_RECEIPT',
                                    );
                                  },
                                  icon: const Icon(Icons.print, size: 18),
                                  label: const Text('Print PDF Slip'),
                                ),
                            ],
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}