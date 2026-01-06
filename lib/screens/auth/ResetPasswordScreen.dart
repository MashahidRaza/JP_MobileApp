import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/Forget.dart'; // ApiConstants

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String verificationToken; // ✅ TOKEN FROM VERIFY OTP

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.verificationToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController =
  TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _resetPassword() async {
    final newPassword =
    _newPasswordController.text.trim();
    final confirmPassword =
    _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Please fill all fields');
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiConstants.resetPasswordWithToken(
        email: widget.email,
        token: widget.verificationToken, // ✅ TOKEN USED
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      _showMessage(
        'Password reset successfully',
        success: true,
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.popUntil(
          context,
              (route) => route.isFirst,
        );
      });
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
    finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                  colors: [
                    Color(0xFFED3237),
                    Color(0x00FFFFFF)
                  ],
                  stops: [0.0, 0.84],
                ),
              ),
            ),
          ),

          // Logos
          Positioned(
            top: media.padding.top + responsive(10),
            left: responsive(16),
            right: responsive(16),
            child: Visibility(
              visible: !isVerySmall,
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/insp.png',
                    width: responsive(90),
                    height: responsive(35),
                    fit: BoxFit.contain,
                  ),
                  Image.asset(
                    'assets/images/stem.png',
                    width: responsive(60),
                    height: responsive(44),
                    fit: BoxFit.contain,
                  ),
                  Image.asset(
                    'assets/images/javed.png',
                    width: responsive(70),
                    height: responsive(38),
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),

          // Vector 7
          Positioned(
            top: responsive(-60),
            right: responsive(-220),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scale(-1.0, 1.0)
                ..rotateZ(27.37 * math.pi / 180),
              child: SizedBox(
                width: responsive(847.9),
                height: responsive(347.6),
                child: Image.asset(
                  'assets/images/Vector7.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),

          // Vector 8
          Positioned(
            top: responsive(520),
            left: responsive(-200),
            child: Transform.rotate(
              angle: -12.24 * math.pi / 180,
              child: SizedBox(
                width: responsive(847.9),
                height: responsive(347.6),
                child: Image.asset(
                  'assets/images/vector8.png',
                  fit: BoxFit.fill,
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
                width: responsive(11.4),
                height: responsive(19),
                child: Image.asset(
                  'assets/images/Group.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Main Content
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: responsive(24),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF871C1F),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // New Password
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border:
                      const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword =
                            !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextField(
                    controller:
                    _confirmPasswordController,
                    obscureText:
                    _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText:
                      'Confirm New Password',
                      border:
                      const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Reset Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                      _isLoading ? null : _resetPassword,
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFFED3237),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        'Reset Password',
                      ),
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