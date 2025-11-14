import 'dart:async';
import 'package:flutter/material.dart';
import 'package:book_series_app/screens/auth/login_screen.dart';
import 'package:book_series_app/services/auth_service.dart'; // Ensure you import AuthService
import '../main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check login status on init
  }

  void _checkLoginStatus() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    // Navigate based on login status
    if (isLoggedIn) {
      final token = await authService.getToken();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainNavigationScreen(token: token)),
      );
    } else {
      Timer(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/background.jpeg',
            fit: BoxFit.cover,
          ),

          // Centered Logo and Spinner
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 180,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}