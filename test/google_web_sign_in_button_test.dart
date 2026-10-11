import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vire/features/auth/presentation/widgets/google_web_sign_in_button.dart';

class _GoogleAccount implements GoogleSignInAccount {
  _GoogleAccount(this.idToken);

  final String? idToken;

  @override
  GoogleSignInAuthentication get authentication =>
      GoogleSignInAuthentication(idToken: idToken);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoogleSignInAuthenticationEvent _signIn([
  String? token = 'synthetic-id-token',
]) => GoogleSignInAuthenticationEventSignIn(user: _GoogleAccount(token));

Widget _host({
  required Stream<GoogleSignInAuthenticationEvent> events,
  required Future<void> Function(String?) onCredential,
  Future<void> Function()? initialize,
  void Function(Object)? onError,
  Widget Function(bool)? buttonBuilder,
  bool enabled = true,
  bool isRegister = false,
}) => MaterialApp(
  home: Scaffold(
    body: GoogleWebSignInButton(
      initialize: initialize ?? () async {},
      onCredential: onCredential,
      onError: onError ?? (_) {},
      enabled: enabled,
      isRegister: isRegister,
      authenticationEvents: events,
      buttonBuilder:
          buttonBuilder ??
          (register) => Text(register ? 'Google register' : 'Google login'),
    ),
  ),
);

void main() {
  late StreamController<GoogleSignInAuthenticationEvent> events;

  setUp(() {
    events = StreamController<GoogleSignInAuthenticationEvent>.broadcast();
  });

  tearDown(() async {
    await events.close();
  });

  testWidgets('initializes and subscribes before rendering the Google button', (
    tester,
  ) async {
    final initialized = Completer<void>();
    var initializeCalls = 0;
    var renderCalls = 0;
    await tester.pumpWidget(
      _host(
        events: events.stream,
        initialize: () {
          initializeCalls++;
          return initialized.future;
        },
        onCredential: (_) async {},
        buttonBuilder: (_) {
          expect(events.hasListener, isTrue);
          renderCalls++;
          return const Text('Google button');
        },
      ),
    );

    expect(initializeCalls, 1);
    expect(events.hasListener, isFalse);
    expect(find.text('Preparing Google sign-in…'), findsOneWidget);
    expect(renderCalls, 0);
    initialized.complete();
    await tester.pump();
    expect(events.hasListener, isTrue);
    expect(renderCalls, 1);
    expect(find.text('Google button'), findsOneWidget);
    expect(find.text('Please wait…'), findsNothing);
  });

  testWidgets('passes the ID token to the existing VIRE credential exchange', (
    tester,
  ) async {
    final received = <String?>[];
    await tester.pumpWidget(
      _host(
        events: events.stream,
        onCredential: (token) async => received.add(token),
      ),
    );
    await tester.pump();
    events.add(_signIn());
    await tester.pump();
    expect(received, ['synthetic-id-token']);
  });

  testWidgets(
    'exchange failure is reported and allows another Google attempt',
    (tester) async {
      final errors = <Object>[];
      var attempts = 0;
      await tester.pumpWidget(
        _host(
          events: events.stream,
          onError: errors.add,
          onCredential: (_) async {
            attempts++;
            throw StateError('Synthetic backend failure');
          },
        ),
      );
      await tester.pump();
      events.add(_signIn());
      await tester.pump();
      expect(attempts, 1);
      expect(errors.single, isA<StateError>());
      expect(find.text('Google login'), findsOneWidget);
      events.add(_signIn());
      await tester.pump();
      expect(attempts, 2);
    },
  );

  testWidgets(
    'missing token reaches shared validation without being submitted',
    (tester) async {
      final errors = <Object>[];
      var submissions = 0;
      await tester.pumpWidget(
        _host(
          events: events.stream,
          onError: errors.add,
          onCredential: (token) async {
            if (token == null || token.isEmpty) {
              throw StateError('Google token unavailable');
            }
            submissions++;
          },
        ),
      );
      await tester.pump();
      events.add(_signIn(null));
      await tester.pump();
      expect(submissions, 0);
      expect(errors.single, isA<StateError>());
    },
  );

  testWidgets(
    'duplicate events are ignored while credential exchange is busy',
    (tester) async {
      final exchange = Completer<void>();
      var exchanges = 0;
      await tester.pumpWidget(
        _host(
          events: events.stream,
          onCredential: (_) {
            exchanges++;
            return exchange.future;
          },
        ),
      );
      await tester.pump();
      events.add(_signIn());
      events.add(_signIn());
      await tester.pump();
      expect(exchanges, 1);
      expect(find.text('Please wait…'), findsOneWidget);
      expect(find.text('Google login'), findsNothing);
      events.add(_signIn());
      await tester.pump();
      expect(exchanges, 1);
      exchange.complete();
      await tester.pump();
      expect(find.text('Google login'), findsOneWidget);
    },
  );

  testWidgets('ignores credentials while another VIRE form action is busy', (
    tester,
  ) async {
    var exchanges = 0;
    await tester.pumpWidget(
      _host(
        events: events.stream,
        enabled: false,
        onCredential: (_) async => exchanges++,
      ),
    );
    await tester.pump();
    events.add(_signIn());
    await tester.pump();
    expect(exchanges, 0);
    expect(find.text('Google login'), findsNothing);
  });

  testWidgets('cancellation and sign-out leave the form available', (
    tester,
  ) async {
    final errors = <Object>[];
    var exchanges = 0;
    await tester.pumpWidget(
      _host(
        events: events.stream,
        onError: errors.add,
        onCredential: (_) async => exchanges++,
      ),
    );
    await tester.pump();
    events.addError(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );
    events.add(GoogleSignInAuthenticationEventSignOut());
    await tester.pump();
    expect(errors, isEmpty);
    expect(exchanges, 0);
    expect(find.text('Google login'), findsOneWidget);
    expect(find.text('Please wait…'), findsNothing);
  });

  testWidgets('reports other authentication stream errors', (tester) async {
    final errors = <Object>[];
    await tester.pumpWidget(
      _host(
        events: events.stream,
        onError: errors.add,
        onCredential: (_) async {},
      ),
    );
    await tester.pump();
    final error = StateError('Synthetic Google error');
    events.addError(error);
    await tester.pump();
    expect(errors, [error]);
    expect(find.text('Google login'), findsOneWidget);
  });

  testWidgets(
    'initialization failure has a retry without duplicate listeners',
    (tester) async {
      final errors = <Object>[];
      var attempts = 0;
      await tester.pumpWidget(
        _host(
          events: events.stream,
          onError: errors.add,
          initialize: () async {
            attempts++;
            if (attempts == 1) {
              throw StateError('Synthetic configuration failure');
            }
          },
          onCredential: (_) async {},
        ),
      );
      await tester.pump();
      expect(errors, hasLength(1));
      expect(find.text('Google sign-in is unavailable.'), findsOneWidget);
      expect(events.hasListener, isFalse);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(attempts, 2);
      expect(events.hasListener, isTrue);
      expect(find.text('Google login'), findsOneWidget);
    },
  );

  testWidgets('cancels its event subscription on dispose', (tester) async {
    var exchanges = 0;
    await tester.pumpWidget(
      _host(events: events.stream, onCredential: (_) async => exchanges++),
    );
    await tester.pump();
    expect(events.hasListener, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(events.hasListener, isFalse);
    events.add(_signIn());
    await tester.pump();
    expect(exchanges, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late initialization completion does not subscribe after dispose',
    (tester) async {
      final initialized = Completer<void>();
      var renderCalls = 0;
      await tester.pumpWidget(
        _host(
          events: events.stream,
          initialize: () => initialized.future,
          onCredential: (_) async {},
          buttonBuilder: (_) {
            renderCalls++;
            return const Text('Google button');
          },
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      initialized.complete();
      await tester.pump();
      expect(events.hasListener, isFalse);
      expect(renderCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('late credential failure does not report to a disposed screen', (
    tester,
  ) async {
    final exchange = Completer<void>();
    final errors = <Object>[];
    await tester.pumpWidget(
      _host(
        events: events.stream,
        onError: errors.add,
        onCredential: (_) => exchange.future,
      ),
    );
    await tester.pump();
    events.add(_signIn());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    exchange.completeError(StateError('Synthetic delayed failure'));
    await tester.pump();
    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'caches rendering on ordinary rebuilds and changes register label',
    (tester) async {
      var renders = 0;
      var initializations = 0;
      Future<void> initialize() async => initializations++;
      Widget render(bool register) {
        renders++;
        return Text(register ? 'Google register' : 'Google login');
      }

      Future<void> credential(String? _) async {}
      await tester.pumpWidget(
        _host(
          events: events.stream,
          initialize: initialize,
          onCredential: credential,
          buttonBuilder: render,
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        _host(
          events: events.stream,
          initialize: initialize,
          onCredential: credential,
          buttonBuilder: render,
        ),
      );
      expect(renders, 1);
      expect(initializations, 1);
      await tester.pumpWidget(
        _host(
          events: events.stream,
          initialize: initialize,
          onCredential: credential,
          buttonBuilder: render,
          isRegister: true,
        ),
      );
      expect(renders, 2);
      expect(initializations, 1);
      expect(find.text('Google register'), findsOneWidget);
    },
  );
}
