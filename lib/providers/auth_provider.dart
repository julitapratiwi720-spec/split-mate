import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        await _notificationService.initialize(user.uid);
        _notificationService.onNotificationReceived = (title, body) {
          debugPrint('Notif diterima: $title - $body');
        };
      }
      notifyListeners();
    });
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final cred = await _authService.register(email, password, name);
      _user = cred.user;
      await _firestoreService.saveUser(UserModel(
        uid: cred.user!.uid,
        email: email,
        name: name,
      ));
      await _notificationService.initialize(cred.user!.uid);
      _notificationService.onNotificationReceived = (title, body) {
        debugPrint('Notif diterima: $title - $body');
      };
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final cred = await _authService.login(email, password);
      _user = cred.user;
      await _notificationService.initialize(cred.user!.uid);
      _notificationService.onNotificationReceived = (title, body) {
        debugPrint('Notif diterima: $title - $body');
      };
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}