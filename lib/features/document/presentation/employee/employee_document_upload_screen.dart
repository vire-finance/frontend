import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pocket/data/employee_pocket_repository.dart';
import '../../data/employee_request_model.dart';
import '../../data/ocr_repository.dart';

class EmployeeDocumentUploadScreen extends StatefulWidget {
  const EmployeeDocumentUploadScreen({super.key});

  @override
  State<EmployeeDocumentUploadScreen> createState() =>
      _EmployeeDocumentUploadScreenState();
}

class _EmployeeDocumentUploadScreenState
    extends State<EmployeeDocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _explanation = TextEditingController();
  String? _requestCategory;
  static const _requestCategories = [
    'Operational',
    'Production',
    'Marketing',
    'Emergency',
    'Administration & Tax',
    'Others'
  ];
  final _party = TextEditingController();
  final _amount = TextEditingController();
  DateTime? _neededAt;
  String? _selectedPocketId;
  UploadedRequestDocument? _uploadedDocument;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final pockets = EmployeePocketRepository.instance.accessiblePockets;
    if (pockets.isNotEmpty) _selectedPocketId = pockets.first.id;
  }

  @override
  void dispose() {
    _explanation.dispose();
    _party.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
            title: const Text('New Request',
                style: TextStyle(
                    color: AppColors.blue900,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            centerTitle: true,
            backgroundColor: AppColors.basicWhite,
            foregroundColor: AppColors.blue900,
            elevation: 0),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  Expanded(
                      child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          children: [
                        const Text('Input From Document',
                            style: TextStyle(
                                color: AppColors.blue500,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _isScanning ? null : _scanDocument,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.blue700,
                              foregroundColor: AppColors.basicWhite,
                            ),
                            icon: _isScanning
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.document_scanner_outlined),
                            label: Text(
                                _isScanning
                                    ? 'Scanning…'
                                    : _uploadedDocument == null
                                        ? 'Scan & Attach Document'
                                        : 'Scan Again · ${_uploadedDocument!.fileName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Request Details',
                            style: TextStyle(
                                color: AppColors.blue500,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const SizedBox(height: 16),
                        _Field(
                            label: 'Request Explanation',
                            required: true,
                            controller: _explanation,
                            hint: 'Type here',
                            validator: _required,
                            maxLines: 2),
                        const _FieldHeading('Request Type', required: true),
                        const SizedBox(height: 7),
                        AppDropdownField<String>(
                            value: _requestCategory,
                            decoration: _decoration('Choose expense category'),
                            items: [
                              for (final category in _requestCategories)
                                DropdownMenuItem(
                                    value: category, child: Text(category)),
                            ],
                            onChanged: (value) =>
                                setState(() => _requestCategory = value),
                            validator: (value) => value == null
                                ? 'Choose expense category'
                                : null),
                        const SizedBox(height: 16),
                        const _FieldHeading('Pocket for owner review',
                            required: true),
                        const SizedBox(height: 7),
                        AppDropdownField<String>(
                            value: _selectedPocketId,
                            decoration:
                                _decoration('Choose an accessible pocket'),
                            items: [
                              for (final pocket in EmployeePocketRepository
                                  .instance.accessiblePockets)
                                DropdownMenuItem(
                                    value: pocket.id, child: Text(pocket.name)),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedPocketId = value),
                            validator: (value) => value == null
                                ? 'No accessible pocket is available'
                                : null),
                        const SizedBox(height: 16),
                        _Field(
                            label: "Other Party’s Name",
                            required: true,
                            controller: _party,
                            hint: 'Type here',
                            validator: _required),
                        _Field(
                            label: 'Total Amount (IDR)',
                            required: true,
                            controller: _amount,
                            hint: 'Type here',
                            keyboardType: TextInputType.number,
                            inputFormatters: const [IdrInputFormatter()],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final amount = parseIdrInput(value);
                              return amount == null || amount <= 0
                                  ? 'Enter an amount greater than zero'
                                  : null;
                            }),
                        const SizedBox(height: 3),
                        const _FieldHeading('When do you need it by?',
                            required: true),
                        const SizedBox(height: 7),
                        TextFormField(
                            key: ValueKey(_neededAt),
                            readOnly: true,
                            onTap: _selectDate,
                            initialValue: _neededAt == null
                                ? ''
                                : _formatDate(_neededAt!),
                            style: AppInputStyles.value,
                            decoration: const AppInputDecoration(
                                hintText: 'Choose a date',
                                suffixIcon: Icon(Icons.calendar_today_outlined,
                                    size: 18)),
                            validator: (_) =>
                                _neededAt == null ? 'Choose a date' : null),
                      ])),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                      child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                              onPressed: _isScanning ||
                                      _uploadedDocument?.status == 'PENDING' ||
                                      _uploadedDocument?.status == 'PROCESSING'
                                  ? null
                                  : _save,
                              child: const Text('Save Document')))),
                ]),
              ),
            ),
          ),
        ),
      );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: _neededAt ?? now,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 5));
    if (date == null || !mounted) return;
    setState(() =>
        _neededAt = DateTime(date.year, date.month, date.day, 23, 59, 59));
  }

  Future<void> _scanDocument() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera)),
        ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery)),
      ])),
    );
    if (source == null || !mounted) return;
    final file =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _isScanning = true);
    try {
      final uploaded = await OcrRepository.instance.upload(file);
      final result = await OcrRepository.instance.waitForResult(uploaded);
      if (!mounted) return;
      setState(() => _uploadedDocument = result);
      if (result.status == 'COMPLETED') {
        final data = await OcrRepository.instance.prefill(result.id);
        if (!mounted) return;
        if (_party.text.trim().isEmpty && data['party_name'] != null) {
          _party.text = '${data['party_name']}';
        }
        if (_amount.text.trim().isEmpty && data['total_amount'] != null) {
          _amount.text = formatIdrInput((data['total_amount'] is num
              ? (data['total_amount'] as num).round()
              : num.tryParse('${data['total_amount']}')?.round() ?? 0));
        }
        AppToast.show(context,
            'Document scanned. Review the extracted details before submitting.',
            type: AppToastType.success);
      } else if (result.status == 'FAILED') {
        AppToast.show(context,
            'OCR could not read this document. Enter the details manually; the attachment will be marked for manual review.',
            type: AppToastType.warning);
      } else {
        AppToast.show(context,
            'Scanning is still processing. Wait here and try again shortly.',
            type: AppToastType.info);
      }
    } catch (error) {
      if (mounted) {
        AppToast.show(context, apiErrorMessage(error),
            type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _selectedPocketId == null) return;
    if (_neededAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose when you need the payment.')));
      return;
    }
    if (!_neededAt!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a future date and time.')));
      return;
    }
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final request = EmployeePaymentRequest(
      id: id,
      reference: 'REQ-${id.substring(id.length - 6)}',
      pocketId: _selectedPocketId!,
      explanation: _explanation.text.trim(),
      requestType: _requestCategory!,
      partyName: _party.text.trim(),
      amount: parseIdrInput(_amount.text)!,
      neededAt: _neededAt!,
      createdAt: now,
      ocrDocumentId: _uploadedDocument?.id,
      allowFailedOcr: _uploadedDocument?.status == 'FAILED',
    );
    Navigator.pop(context, request);
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static InputDecoration _decoration(String hint) =>
      AppInputDecoration(hintText: hint);
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.label,
      required this.controller,
      required this.hint,
      this.required = false,
      this.validator,
      this.maxLines = 1,
      this.keyboardType,
      this.inputFormatters});
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool required;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _FieldHeading(label, required: required),
        const SizedBox(height: 7),
        AppFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration:
                EmployeeDocumentUploadScreenStateDecoration.decoration(hint)),
      ]));
}

class _FieldHeading extends StatelessWidget {
  const _FieldHeading(this.label, {this.required = false});
  final String label;
  final bool required;
  @override
  Widget build(BuildContext context) =>
      AppInputLabel(label, requiredField: required);
}

abstract final class EmployeeDocumentUploadScreenStateDecoration {
  static InputDecoration decoration(String hint) =>
      AppInputDecoration(hintText: hint);
}
