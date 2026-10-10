import 'package:flutter/material.dart';
import '../request_document_list.dart';

class EmployeeDocumentListScreen extends StatelessWidget {
  const EmployeeDocumentListScreen({super.key});
  @override
  Widget build(BuildContext context) => const RequestDocumentList(owner: false);
}
