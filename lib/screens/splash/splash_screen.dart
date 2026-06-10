import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.receipt_long,
                  color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'SplitMate',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Split bills, keep friends.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const Spacer(),
          const Text(
            'FINANCIALLY SOCIAL',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}