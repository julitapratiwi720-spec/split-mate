import 'package:firebase_auth/firebase_auth.dart';
import 'preference_service.dart';
import 'api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PreferenceService _prefs = PreferenceService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> register(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _prefs.saveUserSession(
      uid: cred.user!.uid, email: email, name: name,
    );

    // Simpan user ke MySQL
    await ApiService.registerUser(
      cred.user!.uid,
      name,
      email,
    );

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

    // Simpan/update user ke MySQL saat login
    await ApiService.registerUser(
      cred.user!.uid,
      cred.user!.displayName ?? '',
      cred.user!.email ?? '',
    );

    return cred;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _prefs.clearSession();
  }

  User? get currentUser => _auth.currentUser;
}