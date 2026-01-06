import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/Forget.dart';
import 'ResetPasswordScreen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email; // receive email from previous page

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _secondsRemaining = 300; // 5 minutes timer
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 300;
    _canResend = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        _timer?.cancel();
      }
    });
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showSnack('Please enter OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token =
      await ApiConstants.verifyOtp(widget.email, otp);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            verificationToken: token, // ✅ PASS TOKEN
          ),
        ),
      );
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      await ApiConstants.resendOtp(widget.email); // call correct API
      _showSnack('OTP resent successfully', success: true);
      _startTimer(); // restart the timer
    } catch (e) {
      _showSnack('Failed to resend OTP');
    } finally {
      setState(() => _isLoading = false);
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
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
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

          // Logos
          Positioned(
            top: media.padding.top + responsive(10),
            left: responsive(16),
            right: responsive(16),
            child: Visibility(
              visible: !isVerySmall,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/insp.png', width: responsive(90), height: responsive(35), fit: BoxFit.contain),
                  Image.asset('assets/images/stem.png', width: responsive(60), height: responsive(44), fit: BoxFit.contain),
                  Image.asset('assets/images/javed.png', width: responsive(70), height: responsive(38), fit: BoxFit.contain),
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
                transform: Matrix4.identity()..scale(-1.0, 1.0)..rotateZ(27.37 * math.pi / 180),
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
                    'Verify OTP',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: responsive(24),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF871C1F),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Show Email
                  Text(
                    'OTP sent to ${widget.email}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // OTP Input
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Timer
                  Text(
                    'Time remaining: ${_formatTime(_secondsRemaining)}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Verify Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED3237),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify OTP'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Resend Button
                  TextButton(
                    onPressed: _canResend && !_isLoading ? _resendOtp : null,
                    child: const Text('Resend OTP'),
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