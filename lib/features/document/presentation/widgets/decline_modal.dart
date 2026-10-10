import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';

class DocumentActionModal {
  static Future<String?> showDecline(BuildContext context) =>
      showDialog<String>(
          context: context, builder: (_) => const _DeclineDialog());

  static Future<bool?> showConfirmPayment(
    BuildContext context, {
    String message =
        'Approving this will verify the document and queue it for manual invoice payment.',
  }) =>
      showDialog<bool>(
          context: context,
          builder: (dialogContext) => _ModalFrame(children: [
                const _Heading('Are You Sure?'),
                const SizedBox(height: 10),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.grey700, fontSize: 15, height: 1.45)),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: _ActionButton(
                          label: 'Yes',
                          color: const Color(0xFFBFCEF0),
                          foreground: AppColors.blue700,
                          onPressed: () => Navigator.pop(dialogContext, true))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _ActionButton(
                          label: 'No',
                          color: AppColors.blue500,
                          onPressed: () =>
                              Navigator.pop(dialogContext, false))),
                ]),
              ]));
}

class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();
  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ModalFrame(children: [
        const _Heading('Reject This Request?'),
        const SizedBox(height: 10),
        const Text(
            'This request will be marked as declined and the requester will be notified.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.grey700, fontSize: 15, height: 1.45)),
        const SizedBox(height: 22),
        Form(
            key: _form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const AppInputLabel('Reason for Decline', requiredField: true),
              const SizedBox(height: 8),
              AppFormField(
                  controller: _controller,
                  decoration: const AppInputDecoration(
                      hintText: 'Type your reason here...'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please provide a reason.'
                      : value.trim().length > 1000
                          ? 'Keep your reason within 1,000 characters.'
                          : null),
            ])),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: _ActionButton(
                  label: 'Yes',
                  color: const Color(0xFFFF0000),
                  onPressed: () {
                    if (_form.currentState!.validate())
                      Navigator.pop(context, _controller.text.trim());
                  })),
          const SizedBox(width: 8),
          Expanded(
              child: _ActionButton(
                  label: 'No',
                  color: AppColors.orange100,
                  foreground: AppColors.orange700,
                  onPressed: () => Navigator.pop(context))),
        ]),
      ]);
}

class _ModalFrame extends StatelessWidget {
  const _ModalFrame({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 12, 30, 20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                        height: 142,
                        child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Image.asset(
                                  'assets/images/Regular Images/Mascot - Unsure.png',
                                  height: 128,
                                  fit: BoxFit.contain),
                              Positioned(
                                  right: -20,
                                  top: -6,
                                  child: IconButton(
                                      tooltip: 'Close',
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.close,
                                          color: AppColors.grey700))),
                            ])),
                    const SizedBox(height: 8),
                    ...children,
                  ])))));
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: TextAlign.center,
      style: const TextStyle(
          color: AppColors.blue500, fontSize: 27, fontWeight: FontWeight.w700));
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.label,
      required this.color,
      required this.onPressed,
      this.foreground = Colors.white});
  final String label;
  final Color color, foreground;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 36,
      child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: foreground,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: Text(label)));
}
