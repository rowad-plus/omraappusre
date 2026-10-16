import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'live_updates.dart';

/// لازم تكون top-level عشان Firebase يقدر يشغّلها والتطبيق مقفول.
/// الإشعار نفسه بيعرضه النظام تلقائيًا (رسالة FCM فيها notification)،
/// فمش محتاجين نعمل حاجة هنا غير تهيئة Firebase.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// إشعارات الهاتف (FCM): تسجيل توكن الجهاز على السيرفر، عرض الإشعار لما
/// التطبيق مفتوح، وتبليغ التطبيق لما المستخدم يدوس على إشعار.
///
/// لو Firebase مش متظبط (google-services.json ناقص مثلًا) كل الدوال بتبقى
/// no-op والتطبيق بيشتغل عادي من غير push.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'bookings', // نفس channel_id اللي السيرفر بيبعته (FcmClient)
    'الحجوزات والتحديثات',
    description: 'إشعارات الحجوزات الجديدة والتسكين والدفع',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final StreamController<Map<String, dynamic>> _taps = StreamController.broadcast();
  final StreamController<RemoteMessage> _foreground = StreamController.broadcast();
  StreamSubscription<String>? _tokenRefreshSub;
  bool _ready = false;
  String? _registeredToken;

  /// بيانات الإشعار اللي المستخدم داس عليه (type, booking_id, trip_id ...).
  Stream<Map<String, dynamic>> get onTap => _taps.stream;

  /// إشعار وصل والتطبيق مفتوح — بيتعرض كبوب أب داخل التطبيق.
  Stream<RemoteMessage> get onForeground => _foreground.stream;

  /// إشعار فتح التطبيق وهو مقفول خالص — بيتقرا مرة واحدة بعد ما الواجهة تجهز.
  Map<String, dynamic>? pendingLaunchTap;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Push disabled: Firebase init failed: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _taps.add(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        } catch (_) {}
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // والتطبيق مفتوح النظام مش بيعرض الإشعار لوحده — بنعرضه بوب أب جوه
    // التطبيق (4 ثواني، والضغط عليه يفتح صفحة العمرة).
    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) _foreground.add(message);
      // Any server-side event -> open screens refresh instantly.
      LiveUpdates.instance.ping();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      _taps.add(m.data);
      LiveUpdates.instance.ping();
    });
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) pendingLaunchTap = initial.data;

    _ready = true;
  }

  /// بعد تسجيل الدخول (أو استرجاع الجلسة): يطلب إذن الإشعارات ويبعت
  /// توكن الجهاز للسيرفر عن طريق [send]، ويعيد إرساله لو اتغيّر.
  Future<void> register(Future<void> Function(String token) send) async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      // On iPhone getToken() throws until Apple's APNs token has arrived,
      // which is usually a moment after launch — the token then never
      // reached the server and iOS got no push at all. Wait for it first.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var i = 0;
            i < 20 && await FirebaseMessaging.instance.getAPNSToken() == null;
            i++) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await send(token);
        _registeredToken = token;
        LiveUpdates.instance.pushActive = true;
      }
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        try {
          await send(t);
          _registeredToken = t;
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Push register failed: $e');
    }
  }

  /// قبل تسجيل الخروج: يشيل توكن الجهاز من السيرفر عشان الإشعارات
  /// متوصلش لحساب خرج من الجهاز.
  Future<void> unregister(Future<void> Function(String token) remove) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    LiveUpdates.instance.pushActive = false;
    final token = _registeredToken ?? (_ready ? await FirebaseMessaging.instance.getToken() : null);
    _registeredToken = null;
    if (token == null) return;
    try {
      await remove(token);
    } catch (_) {}
  }
}
