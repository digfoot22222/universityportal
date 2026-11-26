import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/models/remita_transaction.dart';
import '../../../core/theme/app_theme.dart';

class OfficialReceiptDialog extends StatelessWidget {
  final RemitaTransaction transaction;
  const OfficialReceiptDialog({super.key, required this.transaction});

  Future<void> _downloadOrPrintPdf() async {
    final doc = pw.Document();
    final formatter = NumberFormat('#,##0.00', 'en_NG');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'OFFICIAL UNIVERSITY BURSARY RECEIPT',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text('Remita Electronic Settlement Confirmed (Response Code: 00)'),
                pw.Divider(height: 24),
                pw.Text('Remita RRR: ${transaction.rrr}',
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Student Name: ${transaction.studentName}'),
                pw.Text('Matriculation No: ${transaction.studentMatric}'),
                pw.Text('Fee Category: ${transaction.feeCategory}'),
                pw.Text('Description: ${transaction.description}'),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Amount Paid: NGN ${formatter.format(transaction.amountNaira)}',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 24),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data:
                  'UNIV-RECEIPT|RRR:${transaction.rrr}|MATRIC:${transaction.studentMatric}|STATUS:VERIFIED',
                  width: 110,
                  height: 110,
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Remita_Receipt_${transaction.rrr}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'en_NG');
    final qrPayload =
        'UNIV-RECEIPT|RRR:${transaction.rrr}|MATRIC:${transaction.studentMatric}|AMT:NGN${transaction.amountNaira}|STATUS:VERIFIED';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified,
                  color: AppColors.emeraldPulse, size: 48),
              const SizedBox(height: 8),
              const Text(
                'OFFICIAL UNIVERSITY BURSARY RECEIPT',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Remita Electronic Settlement Confirmed (Response Code: 00)',
                style: TextStyle(
                    color: AppColors.emeraldPulse,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              const Divider(height: 26),
              _receiptRow('Remita RRR:', transaction.rrr, isBold: true),
              _receiptRow('Student Name:', transaction.studentName),
              _receiptRow('Matric Number:', transaction.studentMatric),
              _receiptRow('Fee Category:', transaction.feeCategory),
              _receiptRow('Description:', transaction.description),
              _receiptRow(
                'Amount Paid:',
                '₦${formatter.format(transaction.amountNaira)}',
                isBold: true,
              ),
              _receiptRow(
                'Settlement Date:',
                DateFormat('dd MMM yyyy, HH:mm')
                    .format(transaction.paidAt ?? DateTime.now()),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.electricIndigo.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 125,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hostel Clearance & Bursary Porter Check-In QR',
                      style:
                      TextStyle(fontSize: 11, color: AppColors.mutedSlate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _downloadOrPrintPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Save / Print PDF'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrismGradientButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check),
                      label: 'Done',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style:
                const TextStyle(color: AppColors.mutedSlate, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}