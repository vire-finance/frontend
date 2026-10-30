import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReceiptExportService {
  static Future<Uint8List> buildPng(GlobalKey boundaryKey) async {
    await WidgetsBinding.instance.endOfFrame;
    final object = boundaryKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      throw StateError('Receipt is not ready to share.');
    }
    final image = await object.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not create the receipt image.');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  }

  static Future<void> sharePng(GlobalKey boundaryKey) async {
    final bytes = await buildPng(boundaryKey);
    await Share.shareXFiles([
      XFile.fromData(bytes, name: 'vire-receipt.png', mimeType: 'image/png'),
    ], subject: 'Vire transaction receipt');
  }

  static Future<Uint8List> buildPdf({
    required String account,
    required String id,
    required String date,
    required String amount,
    required bool isTopUp,
    String? recipient,
  }) async {
    final assets = [
      await rootBundle.load(
        'assets/images/Regular Images/Transaction Success.png',
      ),
      await rootBundle.load('assets/images/Regular Images/Logo - VIRE.png'),
      await rootBundle.load('assets/fonts/InterTight-Regular.ttf'),
      await rootBundle.load('assets/fonts/InterTight-Bold.ttf'),
    ];
    final success = pw.MemoryImage(assets[0].buffer.asUint8List());
    final logo = pw.MemoryImage(assets[1].buffer.asUint8List());
    final document = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(assets[2]),
        bold: pw.Font.ttf(assets[3]),
      ),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(320, 560),
        margin: const pw.EdgeInsets.all(20),
        build: (_) => [
          pw.Center(child: pw.Image(logo, height: 24)),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              border: pw.Border.all(color: PdfColors.green300),
            ),
            child: pw.Text(
              isTopUp ? 'Top up successful' : 'Transaction successful',
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Center(child: pw.Image(success, height: 72)),
          pw.SizedBox(height: 12),
          pw.Text(
            'Transaction Receipt',
            style: const pw.TextStyle(
                fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Your transaction has been completed successfully.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 12),
          if (recipient != null && recipient.isNotEmpty) ...[
            _section('Recipient', recipient),
            pw.SizedBox(height: 12),
          ],
          _section('Source Account/Card', account),
          pw.SizedBox(height: 12),
          _section('Transaction date & time', date),
          pw.SizedBox(height: 12),
          _section('Transaction amount', '${isTopUp ? '+' : '-'}$amount'),
          _row('Total', amount),
          pw.SizedBox(height: 12),
          _section('Transaction ID', id),
        ],
      ),
    );
    return document.save();
  }

  static Future<void> sharePdf({
    required String account,
    required String id,
    required String date,
    required String amount,
    required bool isTopUp,
    String? recipient,
  }) async {
    final bytes = await buildPdf(
      account: account,
      id: id,
      date: date,
      amount: amount,
      isTopUp: isTopUp,
      recipient: recipient,
    );
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: 'vire-receipt.pdf',
        mimeType: 'application/pdf',
      ),
    ], subject: 'Vire transaction receipt');
  }

  static pw.Widget _section(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            label,
            style:
                const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(color: PdfColors.grey300, height: 8),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      );

  static pw.Widget _row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );
}
