import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';
import '../../features/document/presentation/purchase_requests_screen.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Android may already have initialized the native Firebase app.
  }
}

bool shouldDisplayRequestNotification(String title, String? role) {
  final normalizedTitle = title.toLowerCase();
  final rejected = normalizedTitle.contains('rejected') ||
      normalizedTitle.contains('ditolak');
  return !rejected || role == 'EMPLOYEE';
}

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();
  bool _enabled = false, _polling = false;
  String? _deviceToken;
  String? _pendingRequest;
  Timer? _timer;
  Timer? _bannerTimer;
  OverlayEntry? _banner;
  final Set<String> _seen = {};
  bool _baseline = false;
  int _epoch = 0;
  Future<void> initialize() async {
    const appId = String.fromEnvironment('FIREBASE_APP_ID'),
        apiKey = String.fromEnvironment('FIREBASE_API_KEY'),
        senderId = String.fromEnvironment('FIREBASE_SENDER_ID'),
        projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    try {
      if (appId.isNotEmpty &&
          apiKey.isNotEmpty &&
          senderId.isNotEmpty &&
          projectId.isNotEmpty) {
        await Firebase.initializeApp(
            options: const FirebaseOptions(
                apiKey: apiKey,
                appId: appId,
                messagingSenderId: senderId,
                projectId: projectId));
      } else {
        // Android/iOS can load Firebase options generated from their native
        // google-services/GoogleService-Info configuration at build time.
        await Firebase.initializeApp();
      }
      _enabled = true;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen((message) {
        final id = message.data['notification_id'];
        if (id != null) _seen.add(id);
        _show(message.notification?.title ?? 'Purchase Request',
            message.notification?.body ?? '', message.data['request_id']);
      });
      FirebaseMessaging.onMessageOpenedApp
          .listen((message) => _open(message.data['request_id']));
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        _deviceToken = token;
        try {
          if (await ApiClient.instance.hasSession)
            await ApiClient.instance.dio
                .post('/notifications/devices', data: {'token': token});
        } catch (_) {}
      });
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      _pendingRequest = initial?.data['request_id'];
    } catch (_) {
      _enabled = false;
    }
    // In-app inbox updates also work before Firebase is configured.
    _timer ??= Timer.periodic(const Duration(seconds: 10), (_) => _poll());
    await sync();
  }

  void dashboardReady() {
    final id = _pendingRequest;
    _pendingRequest = null;
    if (id != null)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _open(id);
      });
    sync();
  }

  Future<void> sync() async {
    if (!_enabled || !await ApiClient.instance.hasSession) return;
    _epoch++;
    try {
      await FirebaseMessaging.instance.requestPermission();
      _deviceToken = await FirebaseMessaging.instance.getToken();
      if (_deviceToken != null)
        await ApiClient.instance.dio
            .post('/notifications/devices', data: {'token': _deviceToken});
    } catch (_) {}
  }

  Future<void> logout() async {
    _epoch++;
    _dismissBanner();
    try {
      if (_deviceToken != null)
        await ApiClient.instance.dio
            .delete('/notifications/devices', data: {'token': _deviceToken});
      if (_enabled) await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _deviceToken = null;
    _seen.clear();
    _baseline = false;
  }

  Future<void> _poll() async {
    if (_polling ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
      return;
    _polling = true;
    try {
      if (!await ApiClient.instance.hasSession) {
        _seen.clear();
        _baseline = false;
        return;
      }
      final epochGuard = _epoch;
      final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
          '/notifications',
          queryParameters: {'limit': 30});
      if (epochGuard != _epoch) {
        return;
      }
      for (final row in (response.data?['items'] as List? ?? []).reversed) {
        final id = '${row['id']}';
        if (_seen.add(id) && _baseline && row['is_read'] != true)
          _show('${row['title']}', '${row['message']}',
              row['request_id'] as String?);
      }
      _baseline = true;
    } catch (_) {
    } finally {
      _polling = false;
    }
  }

  Future<void> _show(String title, String body, String? requestId) async {
    if (!shouldDisplayRequestNotification(
        title, await ApiClient.instance.role)) {
      return;
    }
    final overlay = appNavigatorKey.currentState?.overlay;
    if (overlay == null ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _dismissBanner();
    final approved = title.toLowerCase().contains('approved');
    final rejected = title.toLowerCase().contains('rejected') ||
        title.toLowerCase().contains('ditolak');
    final incoming = title.startsWith('Request Payment from ');
    _banner = OverlayEntry(
      builder: (_) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -20 * (1 - value)),
                  child: child,
                ),
              ),
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.horizontal,
                onDismissed: (_) => _dismissBanner(),
                child: Material(
                  color: const Color(0xFFF8F8FF),
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Color(0xFFE9EAF2)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      _dismissBanner();
                      if (requestId != null) _open(requestId);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          if (rejected)
                            const SizedBox(
                                width: 48,
                                height: 48,
                                child: Stack(children: [
                                  Icon(Icons.file_copy_rounded,
                                      size: 48, color: Color(0xFFCC0000)),
                                  Positioned(
                                      right: 7,
                                      top: 9,
                                      child: Icon(Icons.close_rounded,
                                          size: 23, color: Colors.white)),
                                ]))
                          else
                            Icon(
                              approved
                                  ? Icons.verified
                                  : rejected
                                      ? Icons.cancel
                                      : incoming
                                          ? Icons.credit_card_rounded
                                          : Icons.notifications_active,
                              size: 40,
                              color: approved
                                  ? const Color(0xFF35B440)
                                  : rejected
                                      ? const Color(0xFFE34E58)
                                      : incoming
                                          ? const Color(0xFFFF9629)
                                          : const Color(0xFF315DCE),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  approved
                                      ? 'Your Request Has Been Approved!'
                                      : rejected
                                          ? 'Your Request Was Rejected'
                                          : title,
                                  style: TextStyle(
                                    fontSize: rejected ? 18 : 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF192F62),
                                  ),
                                ),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    rejected
                                        ? 'Please check the comment given to your request.'
                                        : approved &&
                                                body.contains(
                                                    'melakukan pembayaran')
                                            ? 'Proceed to payment on the pending transaction.'
                                            : body,
                                    textAlign: rejected
                                        ? TextAlign.justify
                                        : TextAlign.start,
                                    style: TextStyle(
                                      fontSize: rejected ? 16 : 13,
                                      height: 1.35,
                                      color: Color(0xFF536BB1),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_banner!);
    _bannerTimer = Timer(const Duration(seconds: 7), _dismissBanner);
  }

  void _dismissBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
    _banner?.remove();
    _banner = null;
  }

  Future<void> _open(String? id) async {
    if (id == null || id.isEmpty || !await ApiClient.instance.hasSession)
      return;
    final owner = await ApiClient.instance.role == 'OWNER';
    final nav = appNavigatorKey.currentState;
    if (nav != null)
      nav.push(MaterialPageRoute<void>(
          builder: (_) => PurchaseRequestDetailScreen(id: id, owner: owner)));
  }
}
