import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  // Mulai listen notifikasi untuk user ini
  void listenNotifications(String userId) {
    _firestoreService.getNotifications(userId).listen((notifs) {
      _notifications = notifs;
      _unreadCount = notifs.where((n) => !n.isRead).length;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notifId) async {
    await _firestoreService.markNotificationRead(notifId);
  }
}