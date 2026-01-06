import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:book_series_app/screens/auth/login_screen.dart';
import 'package:book_series_app/services/auth_service.dart';
import '../main_navigation_screen.dart';

// ✅ Add this import
import 'package:in_app_update/in_app_update.dart';
import 'dart:io' show Platform;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoReady = false;
  bool _isVideoInitializing = true;

  @override
  void initState() {
    super.initState();

    // ✅ Call update check first (Android only)
    if (Platform.isAndroid) {
      _checkForInAppUpdate();
    }

    _initializeVideo();
  }

  // ✅ New function: Check and trigger in-app update
  Future<void> _checkForInAppUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Prefer Immediate (full-screen forced update like OKX)
        if (updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          // Google Play takes over: shows full-screen dialog on top of splash
          // App restarts automatically after update → no further code runs
          return;
        }
        // Fallback to Flexible if Immediate not allowed
        else if (updateInfo.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          // Optional: You can show a small message "Update downloading..."
          // For now, just continue (download happens in background)
        }
      }
    } catch (e) {
      // If any error, ignore and continue (don't block the user)
      print('In-app update error: $e');
    }

    // If no update or flexible started → continue normal flow
    // (Video and navigation proceed as usual)
  }

  void _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/images/video2.mp4');

    try {
      await _controller.initialize();
      _controller.setLooping(false);

      setState(() {
        _isVideoReady = true;
        _isVideoInitializing = false;
      });

      await _controller.play();

      _controller.addListener(() async {
        if (_controller.value.position >= _controller.value.duration) {
          await _navigateNext();
        }
      });
    } catch (e) {
      setState(() {
        _isVideoInitializing = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      await _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final isExpired = await authService.isTokenExpired();
    if (isExpired) {
      await authService.forceLogout();
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(token: token),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isLargeScreen = screenWidth > 600;

          final videoSize = isLargeScreen
              ? Size(screenWidth * 0.3, screenHeight * 0.3)
              : const Size(190, 190);

          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFED3237),
                      Colors.white,
                      Colors.white,
                      Color(0xFFED3237),
                    ],
                    stops: [0.0, 0.12, 0.88, 1.0],
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/Vector3.png',
                  fit: BoxFit.fitWidth,
                  width: screenWidth,
                  height: screenHeight * 0.3,
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/Vector2.png',
                  fit: BoxFit.fitWidth,
                  width: screenWidth,
                  height: screenHeight * 0.3,
                ),
              ),

              Center(
                child: Container(
                  width: videoSize.width * 2.5,
                  height: videoSize.height * 2.5,
                  alignment: Alignment.center,
                  child: _isVideoInitializing
                      ? Container()
                      : _isVideoReady
                      ? SizedBox(
                    width: videoSize.width * 2.5,
                    height: videoSize.height * 2.5,
                    child: VideoPlayer(_controller),
                  )
                      : GestureDetector(
                    onTap: () async {
                      await _navigateNext();
                    },
                    child: Container(
                      width: videoSize.width * 2.2,
                      height: videoSize.height * 2.2,
                      color: Colors.white.withOpacity(0.1),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}