import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient._() {
    const configuredBaseUrl = String.fromEnvironment('VIRE_API_BASE_URL');
    final defaultHost = kIsWeb
        ? 'localhost'
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => '10.0.2.2',
            TargetPlatform.iOS => '127.0.0.1',
            _ => 'localhost',
          };
    dio = Dio(BaseOptions(
      baseUrl: configuredBaseUrl.isNotEmpty
          ? configuredBaseUrl
          : kReleaseMode
              ? 'https://vire-backend-1e3o.onrender.com'
              : 'http://$defaultHost:8000',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['skipAuth'] != true) {
          final token = await storage.read(key: _accessTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            options.extra['sessionGeneration'] = _sessionGeneration;
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        if (error.response?.statusCode != 401 ||
            request.extra['retried'] == true ||
            request.extra['skipAuth'] == true) {
          handler.next(error);
          return;
        }
        final requestGeneration = request.extra['sessionGeneration'];
        if (requestGeneration is! int) {
          handler.next(error);
          return;
        }
        if (requestGeneration is int &&
            requestGeneration != _sessionGeneration) {
          handler.next(error);
          return;
        }
        final refreshed = await _refresh();
        if (requestGeneration is int &&
            requestGeneration != _sessionGeneration) {
          handler.next(error);
          return;
        }
        if (!refreshed) {
          await clearSession(
              expectedGeneration:
                  requestGeneration is int ? requestGeneration : null);
          handler.next(error);
          return;
        }
        try {
          request.extra['retried'] = true;
          request.headers['Authorization'] =
              'Bearer ${await storage.read(key: _accessTokenKey)}';
          handler.resolve(await dio.fetch<dynamic>(request));
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      },
    ));
  }

  static final instance = ApiClient._();
  static const _accessTokenKey = 'vire.access_token';
  static const _refreshTokenKey = 'vire.refresh_token';
  static const _roleKey = 'vire.role';
  static const storage = FlutterSecureStorage();
  late final Dio dio;
  Future<bool>? _refreshing;
  Future<void> _sessionMutation = Future<void>.value();
  int _sessionGeneration = 0;

  /// Invoked whenever the local session is torn down (logout, failed refresh
  /// recovery, invalid session). Used to purge account-specific in-memory
  /// caches without creating an import cycle with repositories.
  /// Never invoked on successful token refresh.
  VoidCallback? onSessionInvalidated;

  Future<void> saveSession(
      {required String accessToken,
      required String refreshToken,
      String? role}) {
    final generation = ++_sessionGeneration;
    return _mutateSession(() async {
      if (generation != _sessionGeneration) return;
      await _writeSession(accessToken, refreshToken, role);
    });
  }

  void beginSessionSwitch() {
    _sessionGeneration++;
  }

  Future<String?> get role => storage.read(key: _roleKey);
  Future<String?> get accessToken => storage.read(key: _accessTokenKey);
  Future<bool> get hasSession async => (await accessToken)?.isNotEmpty == true;

  Future<void> clearSession({int? expectedGeneration}) async {
    if (expectedGeneration != null && expectedGeneration != _sessionGeneration)
      return;
    final generation = ++_sessionGeneration;
    await _mutateSession(() async {
      if (generation != _sessionGeneration) return;
      await storage.delete(key: _accessTokenKey);
      await storage.delete(key: _refreshTokenKey);
      await storage.delete(key: _roleKey);
    });
    if (generation == _sessionGeneration) {
      try {
        onSessionInvalidated?.call();
      } catch (_) {}
    }
  }

  Future<void> saveRole(String role) =>
      storage.write(key: _roleKey, value: role);

  Future<void> refreshSession() async {
    if (!await _refresh())
      throw StateError('Sesi tidak dapat diperbarui. Silakan login kembali.');
  }

  Future<bool> _refresh() {
    final activeRefresh = _refreshing;
    if (activeRefresh != null) return activeRefresh;

    late final Future<bool> refreshFuture;
    refreshFuture = _performRefresh().whenComplete(() {
      if (identical(_refreshing, refreshFuture)) _refreshing = null;
    });
    _refreshing = refreshFuture;
    return refreshFuture;
  }

  Future<bool> _performRefresh() async {
    final generation = _sessionGeneration;
    final refreshToken = await storage.read(key: _refreshTokenKey);
    if (refreshToken == null ||
        refreshToken.isEmpty ||
        generation != _sessionGeneration) return false;
    try {
      final response = await Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      )).post<Map<String, dynamic>>(
        '/auth/refresh',
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final data = response.data;
      final accessToken = data?['access_token'];
      final newRefreshToken = data?['refresh_token'];
      // Never persist a partial rotation: both tokens must be present.
      if (accessToken is! String ||
          accessToken.isEmpty ||
          newRefreshToken is! String ||
          newRefreshToken.isEmpty) {
        return false;
      }
      var persisted = false;
      await _mutateSession(() async {
        if (generation != _sessionGeneration) return;
        await _writeSession(
            accessToken, newRefreshToken, data?['role'] as String?);
        persisted = true;
      });
      return persisted;
      // ignore: avoid_catching_errors
    } on DioException {
      return false;
    } catch (_) {
      // Any unexpected error (e.g. malformed response) must not leave a
      // half-written session or a stuck refresh future; callers treat
      // false as "re-authenticate".
      return false;
    }
  }

  Future<void> _writeSession(
      String accessToken, String refreshToken, String? role) async {
    await storage.write(key: _accessTokenKey, value: accessToken);
    await storage.write(key: _refreshTokenKey, value: refreshToken);
    if (role != null) await storage.write(key: _roleKey, value: role);
  }

  Future<void> _mutateSession(Future<void> Function() mutation) {
    final next = _sessionMutation.then((_) => mutation());
    _sessionMutation = next.catchError((Object _) {});
    return next;
  }

  static String newIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List) {
        return detail
            .map((item) => item is Map
                ? '${item['loc']?.join('.') ?? ''}: ${item['msg'] ?? ''}'
                : '$item')
            .join('\n');
      }
      if (detail is Map && detail['message'] is String)
        return detail['message'] as String;
    }
    if (data is Map && data['failure_reason'] is String)
      return data['failure_reason'] as String;
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Tidak dapat terhubung ke server. Periksa internet dan URL API.';
    }
    return _shortError(error.message ?? 'Permintaan tidak dapat diproses.');
  }
  return _shortError(error.toString().replaceFirst('Exception: ', ''));
}

String _shortError(String message) {
  final compact = message.replaceAll(RegExp(r'\s+'), ' ').trim();
  return compact.length <= 180 ? compact : '${compact.substring(0, 177)}…';
}
