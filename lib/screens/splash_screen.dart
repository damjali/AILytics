// lib/screens/splash_screen.dart
import 'package:ailytics/screens/landing_screen.dart';
import 'package:ailytics/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ailytics/pages/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 120,
              width: 120,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: 120,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.analytics,
                    size: 60,
                    color: Colors.black,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'AILytics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Empowering Everyone to Be a Data Scientist!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.black),
          ],
        ),
      ),
    );
  }
}