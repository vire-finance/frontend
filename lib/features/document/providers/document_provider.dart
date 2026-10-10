import 'package:flutter/foundation.dart';

import '../data/document_model.dart';
import '../data/document_repository.dart';

class DocumentProvider extends ChangeNotifier {
  DocumentProvider(this._repository) {
    _repository.addListener(_onRepositoryChanged);
    _documents = _repository.documents;
  }

  final DocumentRepository _repository;
  List<DocumentData> _documents = const [];
  bool _isLoading = false;
  Object? _error;

  List<DocumentData> get documents => _documents;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _documents = await _repository.loadDocuments();
    } catch (error) {
      _error = error;
      _documents = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateStatus(String id, DocumentStatus status, {String? reason}) {
    _repository.updateStatus(id, status, declineReason: reason);
  }

  Future<void> rejectRequest(String id, String reason, String actionToken) =>
      _repository.rejectRequest(id, reason, actionToken);

  Future<DocumentData> loadDetail(String id) => _repository.loadDetail(id);

  Future<void> approveRequest(String id, String cardId, String actionToken) =>
      _repository.approveRequest(id, cardId, actionToken);

  void _onRepositoryChanged() {
    _documents = _repository.documents;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
