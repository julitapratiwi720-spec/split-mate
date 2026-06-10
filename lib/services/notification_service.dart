import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Function(String title, String body)? onNotificationReceived;

  Future<void> initialize(String userId) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Status izin: ${settings.authorizationStatus}');

    await _saveToken(userId);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground: ${message.notification?.title}');
      if (message.notification != null) {
        onNotificationReceived?.call(
          message.notification!.title ?? 'Notifikasi',
          message.notification!.body ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App dibuka dari notifikasi: ${message.notification?.title}');
    });

    _fcm.onTokenRefresh.listen((newToken) async {
      // Simpan ke Firestore DAN MySQL
      await _firestoreService.updateFcmToken(userId, newToken);
      await ApiService.registerToken(userId, newToken);
    });
  }

  Future<void> _saveToken(String userId) async {
    try {
      if (kIsWeb) {
        final token = await _fcm.getToken(
          vapidKey: 'YOUR_VAPID_KEY_HERE',
        );
        if (token != null) {
          debugPrint('FCM Web Token: $token');
          // Simpan ke Firestore DAN MySQL
          await _firestoreService.updateFcmToken(userId, token);
          await ApiService.registerToken(userId, token);
        }
      } else {
        final token = await _fcm.getToken();
        if (token != null) {
          debugPrint('FCM Android Token: $token');
          // Simpan ke Firestore DAN MySQL
          await _firestoreService.updateFcmToken(userId, token);
          await ApiService.registerToken(userId, token);
        }
      }
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }
}