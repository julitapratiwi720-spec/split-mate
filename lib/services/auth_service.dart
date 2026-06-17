import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'preference_service.dart';
import 'api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PreferenceService _prefs = PreferenceService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> register(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _prefs.saveUserSession(
      uid: cred.user!.uid, email: email, name: name,
    );
    await ApiService.registerUser(cred.user!.uid, name, email);
    return cred;
  }

  Future<UserCredential> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    await _prefs.saveUserSession(
      uid: cred.user!.uid,
      email: cred.user!.email ?? '',
      name: cred.user!.displayName ?? '',
    );
    await ApiService.registerUser(
      cred.user!.uid,
      cred.user!.displayName ?? '',
      cred.user!.email ?? '',
    );
    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);

      await _prefs.saveUserSession(
        uid: cred.user!.uid,
        email: cred.user!.email ?? '',
        name: cred.user!.displayName ?? '',
      );
      await ApiService.registerUser(
        cred.user!.uid,
        cred.user!.displayName ?? '',
        cred.user!.email ?? '',
      );

      return cred;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _prefs.clearSession();
  }

  User? get currentUser => _auth.currentUser;
}