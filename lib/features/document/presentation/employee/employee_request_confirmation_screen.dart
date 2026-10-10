import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/employee_request_model.dart';

class EmployeeRequestConfirmationScreen extends StatelessWidget {
  const EmployeeRequestConfirmationScreen({required this.request, super.key});
  final EmployeePaymentRequest request;

  String get _date =>
      DateFormat('dd MMM yyyy h:mm a').format(request.createdAt);
  String get _money =>
      'IDR ${NumberFormat('#,##0', 'en_US').format(request.amount)}';

  Future<void> _export(BuildContext context, {required bool download}) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
          build: (_) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Your Request Has Been Sent',
                        style: pw.TextStyle(fontSize: 22)),
                    pw.SizedBox(height: 20),
                    pw.Text('Request ID: ${request.reference}'),
                    pw.Text('Request Type: Invoice'),
                    pw.Text("Other Party's Name: ${request.partyName}"),
                    pw.Text('Date & Time: $_date'),
                    pw.Text('Purpose: ${request.explanation}'),
                    pw.Text('Amount: $_money'),
                    pw.SizedBox(height: 20),
                    pw.Text(
                        'Waiting for owner approval and payment. This is a request confirmation, not proof of payment.'),
                  ])));
      final Uint8List bytes = await pdf.save();
      final name = 'vire-request-${request.reference}.pdf';
      if (download) {
        await FilePicker.platform.saveFile(
            dialogTitle: 'Save request confirmation',
            fileName: name,
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            bytes: bytes);
      } else {
        await Share.shareXFiles(
            [XFile.fromData(bytes, name: name, mimeType: 'application/pdf')],
            subject: 'Vire request ${request.reference}');
      }
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.basicWhite,
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(children: [
                    Expanded(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Image.asset(
                                      'assets/images/Regular Images/Waiting For Approval.png',
                                      height: 230,
                                      fit: BoxFit.contain),
                                  const SizedBox(height: 20),
                                  const Text('Your Request Has Been Sent',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.blue500,
                                          fontSize: 27,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 18),
                                  const Text(
                                      'Your request is now in the approval queue. The funds will be processed once your request has been verified.',
                                      style: TextStyle(
                                          color: AppColors.grey700,
                                          fontSize: 15,
                                          height: 1.5)),
                                  const SizedBox(height: 32),
                                  Row(children: [
                                    Expanded(
                                        child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.blue700,
                                                side: const BorderSide(
                                                    color: AppColors.blue700),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6))),
                                            onPressed: () => _export(context,
                                                download: false),
                                            icon: const Icon(
                                                Icons.share_outlined,
                                                size: 18),
                                            label: const Text('Share'))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.blue700,
                                                side: const BorderSide(
                                                    color: AppColors.blue700),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6))),
                                            onPressed: () => _export(context,
                                                download: true),
                                            icon: const Icon(
                                                Icons.download_outlined,
                                                size: 18),
                                            label: const Text('Download'))),
                                  ]),
                                  const SizedBox(height: 12),
                                  Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                          color: AppColors.white,
                                          border: Border.all(
                                              color: AppColors.grey50),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Column(children: [
                                        const _Line(
                                            label: 'Request Type',
                                            value: 'Invoice'),
                                        _Line(
                                            label: "Other Party’s Name",
                                            value: request.partyName),
                                        _Line(
                                            label: 'Date & Time', value: _date),
                                        const SizedBox(height: 22),
                                        Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(_money,
                                                style: const TextStyle(
                                                    color: AppColors.orange500,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 28))),
                                      ])),
                                ]))),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                                onPressed: () => Navigator.pop(context),
                                style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.blue500,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                child: const Text('Back')))),
                  ])))));
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: AppColors.grey600, fontSize: 14))),
        Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: AppColors.blue700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14))),
      ]));
}
