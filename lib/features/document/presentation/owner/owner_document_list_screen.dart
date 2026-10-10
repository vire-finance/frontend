import 'package:flutter/material.dart';
import '../request_document_list.dart';

class OwnerDocumentListScreen extends StatelessWidget {
  const OwnerDocumentListScreen({super.key});
  @override
  Widget build(BuildContext context) => const RequestDocumentList(owner: true);
}
