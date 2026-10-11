import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:vire/core/network/api_client.dart';
import 'package:vire/features/auth/data/auth_repository.dart';

class GoogleAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  String role = 'OWNER';
  int status = 200;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final data = options.method == 'GET'
        ? {'enabled': true, 'client_id': 'synthetic.apps.googleusercontent.com'}
        : status == 200
            ? {
                'access_token': 'synthetic-access',
                'refresh_token': 'synthetic-refresh',
                'role': role,
                'token_type': 'bearer',
                'expires_in': 1800,
              }
            : {'detail': 'Synthetic invalid Google credential'};
    return ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

class FakeGooglePlatform extends GoogleSignInPlatform {
  final events = StreamController<AuthenticationEvent>.broadcast();
  InitParameters? initialization;
  int initCalls = 0;
  int authenticateCalls = 0;
  bool cancel = false;

  @override
  Future<void> init(InitParameters params) async {
    initCalls++;
    initialization = params;
  }

  @override
  Stream<AuthenticationEvent> get authenticationEvents => events.stream;

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<AuthenticationResults> authenticate(
      AuthenticateParameters params) async {
    authenticateCalls++;
    if (cancel) {
      throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled);
    }
    return const AuthenticationResults(
      user: GoogleSignInUserData(
          email: 'user@example.test', id: 'synthetic-user'),
      authenticationTokens:
          AuthenticationTokenData(idToken: 'synthetic-id-token'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GoogleAdapter adapter;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    final dio = ApiClient.instance.dio;
    final previousAdapter = dio.httpClientAdapter;
    final previousInterceptors = dio.interceptors.toList();
    adapter = GoogleAdapter();
    dio.interceptors.clear();
    dio.httpClientAdapter = adapter;
    addTearDown(() {
      dio.httpClientAdapter = previousAdapter;
      dio.interceptors
        ..clear()
        ..addAll(previousInterceptors);
      FlutterSecureStorage.setMockInitialValues({});
    });
  });

  for (final role in ['OWNER', 'EMPLOYEE', 'PENDING']) {
    test('Google ID-token exchange preserves $role VIRE session', () async {
      adapter.role = role;
      final result = await AuthRepository.instance
          .loginWithGoogleIdToken('synthetic-id-token');
      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/auth/google');
      expect(request.data, {'id_token': 'synthetic-id-token'});
      expect(request.extra['skipAuth'], isTrue);
      expect(result['role'], role);
      expect(await ApiClient.storage.readAll(), {
        'vire.access_token': 'synthetic-access',
        'vire.refresh_token': 'synthetic-refresh',
        'vire.role': role,
      });
    });
  }

  for (final token in <String?>[null, '', '   ']) {
    test(
        'missing Google ID token never calls backend or saves a session: $token',
        () async {
      await expectLater(AuthRepository.instance.loginWithGoogleIdToken(token),
          throwsStateError);
      expect(adapter.requests, isEmpty);
      expect(await ApiClient.storage.readAll(), isEmpty);
    });
  }

  test('rejected Google token leaves stored session unchanged', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'existing': 'synthetic-existing'});
    adapter.status = 401;
    await expectLater(
        AuthRepository.instance.loginWithGoogleIdToken('synthetic-invalid'),
        throwsA(isA<DioException>()));
    expect(
        await ApiClient.storage.readAll(), {'existing': 'synthetic-existing'});
    expect(adapter.requests, hasLength(1));
  });

  test('SDK initializes once with the matching platform client parameter',
      () async {
    final previousPlatform = GoogleSignInPlatform.instance;
    final platform = FakeGooglePlatform();
    GoogleSignInPlatform.instance = platform;
    if (!kIsWeb) debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() async {
      debugDefaultTargetPlatformOverride = null;
      GoogleSignInPlatform.instance = previousPlatform;
      await platform.events.close();
    });
    if (kIsWeb) {
      await AuthRepository.instance.initializeGoogle();
      expect(platform.initialization!.clientId,
          'synthetic.apps.googleusercontent.com');
      expect(platform.initialization!.serverClientId, isNull);
      expect(platform.authenticateCalls, 0);
    } else {
      platform.cancel = true;
      expect(await AuthRepository.instance.loginWithGoogle(), isNull);
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
      platform.cancel = false;
      final result = await AuthRepository.instance.loginWithGoogle();
      expect(result!['role'], 'OWNER');
      expect(platform.initialization!.clientId, isNull);
      expect(platform.initialization!.serverClientId,
          'synthetic.apps.googleusercontent.com');
      expect(platform.authenticateCalls, 2);
      expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
    }
    await AuthRepository.instance.initializeGoogle();
    expect(platform.initCalls, 1);
    expect(adapter.requests.where((r) => r.method == 'GET'), hasLength(1));
  });
}
