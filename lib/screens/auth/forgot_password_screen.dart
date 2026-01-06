import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/Forget.dart';
import '../../services/auth_service.dart';
import 'Verify_opt_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _submit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Enter a valid email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiConstants.forgotPassword(email);

      if (!mounted) return;

      _showSnack('OTP sent successfully to $email', success: true);

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOtpScreen(email: email),
          ),
        );
      });
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final double scale = width / 430;
    double responsive(double size) => size * scale;
    final bool isVerySmall = width < 350;

    return Scaffold(
      body: Stack(
        children: [
          // Top Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: responsive(100),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFED3237), Color(0x00FFFFFF)],
                  stops: [0.0, 0.84],
                ),
              ),
            ),
          ),

          // Logo Banners
          Positioned(
            top: media.padding.top + responsive(10),
            left: responsive(16),
            right: responsive(16),
            child: Visibility(
              visible: !isVerySmall,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/insp.png',
                      width: responsive(90), height: responsive(35), fit: BoxFit.contain),
                  Image.asset('assets/images/stem.png',
                      width: responsive(60), height: responsive(44), fit: BoxFit.contain),
                  Image.asset('assets/images/javed.png',
                      width: responsive(70), height: responsive(38), fit: BoxFit.contain),
                ],
              ),
            ),
          ),

          // Vector 7
          Positioned(
            top: responsive(-60),
            right: responsive(-220),
            child: Opacity(
              opacity: 0.99,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(-1.0, 1.0)
                  ..rotateZ(27.37 * math.pi / 180),
                child: SizedBox(
                  width: responsive(847.9),
                  height: responsive(347.6),
                  child: Image.asset('assets/images/Vector7.png', fit: BoxFit.fill),
                ),
              ),
            ),
          ),

          // Vector 8
          Positioned(
            top: responsive(520),
            left: responsive(-200),
            child: Opacity(
              opacity: 0.99,
              child: Transform.rotate(
                angle: -12.24 * math.pi / 180,
                child: SizedBox(
                  width: responsive(847.9),
                  height: responsive(347.6),
                  child: Image.asset('assets/images/vector8.png', fit: BoxFit.fill),
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: responsive(89),
            left: responsive(32),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: responsive(11.422),
                height: responsive(19),
                child: Image.asset('assets/images/Group.png', fit: BoxFit.contain),
              ),
            ),
          ),

          // Centered Main Content
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Forgot Password',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: responsive(24),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF871C1F),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Send OTP Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED3237),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Send OTP'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}