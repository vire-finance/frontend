import 'dart:async';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';

class UploadedRequestDocument {
  const UploadedRequestDocument({required this.id, required this.status, this.fileName});
  final String id;
  final String status;
  final String? fileName;
}

class OcrRepository {
  OcrRepository._();
  static final instance = OcrRepository._();
  final _api = ApiClient.instance;

  Future<UploadedRequestDocument> upload(XFile file) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/ocr/documents',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.name,
        ),
      }),
      options: Options(contentType: 'multipart/form-data'),
    );
    return UploadedRequestDocument(id: '${response.data!['document_id']}', status: '${response.data!['status']}', fileName: file.name);
  }

  Future<UploadedRequestDocument> waitForResult(UploadedRequestDocument uploaded, {Duration timeout = const Duration(seconds: 45)}) async {
    final deadline = DateTime.now().add(timeout);
    var current = uploaded;
    while (DateTime.now().isBefore(deadline)) {
      if (current.status == 'COMPLETED' || current.status == 'FAILED') return current;
      await Future<void>.delayed(const Duration(seconds: 2));
      final response = await _api.dio.get<Map<String, dynamic>>('/ocr/documents/${current.id}');
      current = UploadedRequestDocument(id: current.id, status: '${response.data!['status']}', fileName: current.fileName);
    }
    return current;
  }

  Future<Map<String, dynamic>> prefill(String documentId) async {
    final response = await _api.dio.get<Map<String, dynamic>>('/documents/$documentId/prefill');
    return response.data ?? const {};
  }
}
