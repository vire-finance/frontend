import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/session/session_cache.dart';

class AuthRepository {
  AuthRepository._() {
    // Purge account caches whenever the local session is torn down,
    // including 401 recovery and invalid-session paths in [ApiClient].
    _api.onSessionInvalidated = SessionCaches.clearAll;
  }
  static final instance = AuthRepository._();
  final _api = ApiClient.instance;
  Future<void>? _googleInitialization;
  Future<void>? _googleWebSdkInitialization;

  Future<void> _initializeGoogle() async {
    final config = await _api.dio.get<Map<String, dynamic>>(
        '/auth/google/config',
        options: Options(extra: {'skipAuth': true}));
    final clientId = config.data?['client_id'] as String?;
    if (config.data?['enabled'] != true ||
        clientId == null ||
        clientId.isEmpty) {
      throw StateError(
          'Login Google belum aktif. Isi GOOGLE_CLIENT_ID di backend terlebih dahulu.');
    }
    if (kIsWeb) {
      // The Web SDK permits initialization only once, including failed starts.
      await (_googleWebSdkInitialization ??=
          GoogleSignIn.instance.initialize(clientId: clientId));
    } else {
      await GoogleSignIn.instance.initialize(serverClientId: clientId);
    }
  }

  Future<void> initializeGoogle() async {
    try {
      await (_googleInitialization ??= _initializeGoogle());
    } catch (_) {
      // A failed config request may be retried; the Web SDK future stays cached.
      _googleInitialization = null;
      rethrow;
    }
  }

  // Android uses the interactive result; Web uses the rendered button's events.
  Future<Map<String, dynamic>?> loginWithGoogle() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw StateError('Login Google saat ini tersedia di aplikasi Android.');
    }
    await initializeGoogle();
    GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    return loginWithGoogleIdToken(account.authentication.idToken);
  }

  Future<Map<String, dynamic>> loginWithGoogleIdToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      throw StateError(kIsWeb
          ? 'Token Google tidak tersedia. Coba login Google kembali.'
          : 'Token Google tidak tersedia. Periksa OAuth Client ID dan SHA-1 Android.');
    }
    final response = await _api.dio.post<Map<String, dynamic>>('/auth/google',
        data: {'id_token': token}, options: Options(extra: {'skipAuth': true}));
    final data = response.data!;
    SessionCaches.clearAll();
    await _api.saveSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        role: data['role'] as String);
    await PushNotificationService.instance.sync();
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email.trim(),
        'username': username.trim(),
        'phone_number': phoneNumber.trim(),
        'password': password,
        'confirm_password': confirmPassword,
      },
      options: Options(extra: {'skipAuth': true}),
    );
    final data = response.data!;
    final user = Map<String, dynamic>.from(data['user'] as Map);
    SessionCaches.clearAll();
    await _api.saveSession(
      accessToken: data['setup_token'] as String,
      refreshToken: data['refresh_token'] as String,
      role: user['role'] as String? ?? 'PENDING',
    );
    return user;
  }

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
      options: Options(extra: {'skipAuth': true}),
    );
    final data = response.data!;
    SessionCaches.clearAll();
    await _api.saveSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      role: data['role'] as String,
    );
    await PushNotificationService.instance.sync();
    return data;
  }

  Future<String> setupOwner(
      {required String fundAccountType, required int employeesManaged}) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/auth/role/owner',
      data: {
        'fund_account_type': fundAccountType,
        'employees_managed': employeesManaged
      },
    );
    SessionCaches.clearAll();
    await _api.refreshSession();
    await _api.saveRole('OWNER');
    return response.data!['code'] as String;
  }

  Future<Map<String, dynamic>> invitationCode() async {
    final response =
        await _api.dio.get<Map<String, dynamic>>('/auth/invite-code');
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> regenerateInvitationCode() async {
    final response = await _api.dio
        .post<Map<String, dynamic>>('/auth/invite-code/regenerate');
    return response.data ?? const {};
  }

  Future<void> setupEmployee(String invitationCode) async {
    await _api.dio.post<void>(
      '/auth/role/employee',
      data: {'invitation_code': invitationCode.trim()},
    );
    SessionCaches.clearAll();
    await _api.refreshSession();
    await _api.saveRole('EMPLOYEE');
  }

  Future<void> setSecurityPin(String pin) async {
    await _api.dio.post<void>(
      '/api/v1/security/change-pin',
      data: {'new_pin': pin},
    );
  }

  Future<void> changePassword(
      {required String currentPassword,
      required String newPassword,
      required String confirmPassword}) async {
    await _api.dio.post<void>('/api/v1/security/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
    await _api.clearSession();
  }

  Future<void> changeSecurityPin(
      {String? oldPin, required String newPin}) async {
    await _api.dio.post<void>('/api/v1/security/change-pin', data: {
      if (oldPin != null && oldPin.isNotEmpty) 'old_pin': oldPin,
      'new_pin': newPin,
    });
  }

  Future<Map<String, dynamic>> securitySettings() async {
    final response =
        await _api.dio.get<Map<String, dynamic>>('/api/v1/security/settings');
    return response.data ?? const {};
  }

  Future<void> updateBiometric(bool enabled) async {
    await _api.dio.patch<void>('/api/v1/security/biometric-toggle',
        data: {'enabled': enabled});
  }

  Future<void> updateNotificationPreferences(
      Map<String, bool> preferences) async {
    await _api.dio
        .patch<void>('/api/v1/security/notifications', data: preferences);
  }

  Future<String> verifyPin(String pin, {required String actionType}) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/api/v1/security/verify-pin',
      data: {'pin': pin, 'action_type': actionType},
    );
    return response.data!['action_token'] as String;
  }

  Future<Map<String, dynamic>> profile() async {
    final response =
        await _api.dio.get<Map<String, dynamic>>('/api/v1/profile');
    return response.data!;
  }

  Future<String?> restoreRole() async {
    if (!await _api.hasSession) {
      SessionCaches.clearAll();
      return null;
    }
    final savedRole = await _api.role;
    if (savedRole == 'PENDING') return 'PENDING';
    try {
      final user = await profile();
      final rawRole = '${user['role']}';
      final role = rawRole == 'BUSINESS_OWNER' || rawRole == 'OWNER'
          ? 'OWNER'
          : 'EMPLOYEE';
      if (savedRole != null && savedRole != role) SessionCaches.clearAll();
      await _api.saveRole(role);
      final settings =
          await _api.dio.get<Map<String, dynamic>>('/api/v1/security/settings');
      if (settings.data?['pin_is_set'] != true) return 'PIN_$role';
      return role;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'OFFLINE';
      }
      await _api.clearSession();
      return null;
    }
  }

  Future<void> logout() async {
    SessionCaches.clearAll();
    await PushNotificationService.instance.logout();
    try {
      await _api.dio.post<void>('/auth/logout');
    } on DioException {
      // Clear local credentials even if the server is temporarily unavailable.
    } finally {
      await _api.clearSession();
      if (_googleInitialization != null) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
    }
  }
}
