import 'package:book_series_app/main_navigation_screen.dart';
import 'package:book_series_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final AuthService _authService = AuthService();

  // Load saved mobile number and password (always)
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMobile = prefs.getString('last_mobile_number');
    final savedPassword = await _secureStorage.read(key: 'user_password');

    if (!mounted) return;

    setState(() {
      if (savedMobile != null) {
        _mobileNumberController.text = savedMobile;
      }
      if (savedPassword != null) {
        _passwordController.text = savedPassword;
      }
    });
  }

  // Always save both mobile number and password after successful login
  final _secureStorage = const FlutterSecureStorage();

  Future<void> _saveCredentials(String mobile, String password) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('last_mobile_number', mobile);
    await _secureStorage.write(
      key: 'user_password',
      value: password,
    );
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedCredentials();
    });
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  String? _validateMobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final trimmed = value.trim();
    final cleaned = trimmed.replaceAll(RegExp(r'\s+'), '');

    if (cleaned.startsWith('+')) {
      if (cleaned.startsWith('+92')) {
        if (cleaned.length != 13) {
          return 'Must be 13 characters: +923123456789';
        }
        if (!RegExp(r'^\+92[0-9]{10}$').hasMatch(cleaned)) {
          return 'Invalid format: +923123456789';
        }
      } else {
        if (cleaned.length < 10 || cleaned.length > 15) {
          return 'International number must be 10-15 digits';
        }
        if (!RegExp(r'^\+[0-9]{9,14}$').hasMatch(cleaned)) {
          return 'Invalid international number';
        }
      }
    } else if (cleaned.startsWith('03')) {
      if (cleaned.length != 11) {
        return 'Must be 11 digits: 03123456789';
      }
      if (!RegExp(r'^03[0-9]{9}$').hasMatch(cleaned)) {
        return 'Invalid format: 03123456789';
      }
    } else if (cleaned.startsWith('92')) {
      if (cleaned.length == 12) {
        return 'Did you mean +$cleaned?';
      }
      return 'Use 03 for local or +92 for international';
    } else {
      return 'Start with 03 (local) or +92 (international)';
    }
    return null;
  }

  void _handleLogin() async {
    final mobileNumber = _mobileNumberController.text.trim();
    final password = _passwordController.text.trim();

    final mobileError = _validateMobileNumber(mobileNumber);
    if (mobileError != null) {
      _showErrorSnackBar(mobileError);
      return;
    }
    if (password.isEmpty) {
      _showErrorSnackBar('Please enter password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authService.login(mobileNumber, password);
      if (success && mounted) {
        // Always save both mobile and password
        await _saveCredentials(mobileNumber, password);

        final token = await _authService.getToken();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainNavigationScreen(token: token)),
        );
      } else if (mounted) {
        _showErrorDialog('Invalid mobile number or password. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

 // make sure this path is correct

  void _handleForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }


  @override
  void dispose() {
    _mobileNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 380;
    final isTablet = screenWidth >= 600;
    final isLargeTablet = screenWidth >= 900;
    final isVerySmallScreen = screenWidth < 350;

    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final safeAreaTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bee image at top
            Positioned(
              top: safeAreaTop + (isLargeTablet ? 20 : isTablet ? 15 : isSmallScreen ? 10 : 15),
              left: (screenWidth - (isLargeTablet ? 140 : isTablet ? 120 : isSmallScreen ? 70 : 89)) / 2,
              child: Image.asset(
                'assets/images/image 3.png',
                width: isLargeTablet ? 140 : isTablet ? 120 : isSmallScreen ? 70 : 89,
                height: isLargeTablet ? 140 : isTablet ? 120 : isSmallScreen ? 70 : 89,
              ),
            ),

            // Red header
            Positioned(
              top: safeAreaTop + (isLargeTablet ? 20 : isTablet ? 15 : isSmallScreen ? 10 : 15) +
                  (isLargeTablet ? 140 : isTablet ? 120 : isSmallScreen ? 70 : 89) -
                  (isLargeTablet ? 10 : isTablet ? 8 : isSmallScreen ? 5 : 6),
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: InwardSidesClipper(curveDepth: isTablet ? 25 : 20),
                child: Container(
                  height: isLargeTablet ? 130 : isTablet ? 115 : isSmallScreen ? 85 : 95,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFED3237), Color(0xFF871C1F)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Align(
                    alignment: const Alignment(0, -0.7),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.poppins(
                        fontSize: isLargeTablet ? 45 : isTablet ? 42 : isSmallScreen ? 32 : 38,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Logos at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: safeAreaBottom + (isSmallScreen ? 8 : 15),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeTablet ? 60 : isTablet ? 50 : isSmallScreen ? 15 : 25,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/insp.png',
                        width: isVerySmallScreen ? 60 : isSmallScreen ? 75 : isLargeTablet ? 150 : isTablet ? 130 : 95,
                        height: isVerySmallScreen ? 22 : isSmallScreen ? 30 : isLargeTablet ? 50 : isTablet ? 45 : 40,
                        fit: BoxFit.contain),
                    Image.asset('assets/images/stem.png',
                        width: isVerySmallScreen ? 40 : isSmallScreen ? 50 : isLargeTablet ? 90 : isTablet ? 80 : 65,
                        height: isVerySmallScreen ? 25 : isSmallScreen ? 35 : isLargeTablet ? 60 : isTablet ? 55 : 48,
                        fit: BoxFit.contain),
                    Image.asset('assets/images/javed.png',
                        width: isVerySmallScreen ? 50 : isSmallScreen ? 60 : isLargeTablet ? 100 : isTablet ? 90 : 75,
                        height: isVerySmallScreen ? 22 : isSmallScreen ? 30 : isLargeTablet ? 55 : isTablet ? 48 : 42,
                        fit: BoxFit.contain),
                  ],
                ),
              ),
            ),

            // White form container
            Positioned(
              top: safeAreaTop +
                  (isLargeTablet ? 20 : isTablet ? 15 : isSmallScreen ? 10 : 15) +
                  (isLargeTablet ? 140 : isTablet ? 120 : isSmallScreen ? 70 : 89) -
                  (isLargeTablet ? 10 : isTablet ? 8 : isSmallScreen ? 5 : 6) +
                  (isLargeTablet ? 100 : isTablet ? 90 : isSmallScreen ? 60 : 70),
              left: 0,
              right: 0,
              bottom: (isLargeTablet ? 120 : isTablet ? 110 : isSmallScreen ? 80 : 90) + safeAreaBottom,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isLargeTablet ? 60 : isTablet ? 50 : 40),
                    topRight: Radius.circular(isLargeTablet ? 60 : isTablet ? 50 : 40),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isLargeTablet ? 40 : isTablet ? 35 : isSmallScreen ? 25 : 30,
                      left: 0,
                      right: 0,
                      bottom: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vector4.png
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(
                            bottom: isLargeTablet ? 15 : isTablet ? 12 : isSmallScreen ? 8 : 10,
                          ),
                          child: Image.asset('assets/images/Vector4.png', width: double.infinity, fit: BoxFit.fitWidth),
                        ),

                        // Mobile Number Field
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeTablet ? 60 : isTablet ? 50 : isSmallScreen ? 20 : 30,
                          ),
                          margin: EdgeInsets.only(
                            bottom: isLargeTablet ? 15 : isTablet ? 12 : isSmallScreen ? 8 : 10,
                          ),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: isLargeTablet ? 500 : isTablet ? 400 : 328,
                            ),
                            height: isLargeTablet ? 60 : isTablet ? 55 : isSmallScreen ? 42 : 48,
                            child: TextField(
                              controller: _mobileNumberController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9\+]')),
                                LengthLimitingTextInputFormatter(15),
                              ],
                              style: GoogleFonts.inter(
                                fontSize: isLargeTablet ? 20 : isTablet ? 18 : isSmallScreen ? 14 : 16,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.phone_android_outlined, color: Colors.grey, size: isLargeTablet ? 26 : isTablet ? 24 : 20),
                                hintText: 'Mobile Number',
                                hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: isLargeTablet ? 20 : isTablet ? 18 : isSmallScreen ? 14 : 16),
                                filled: true,
                                fillColor: Colors.grey[200],
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isLargeTablet ? 24 : isTablet ? 20 : 16,
                                  vertical: isLargeTablet ? 18 : isTablet ? 16 : 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(isLargeTablet ? 16 : isTablet ? 15 : 12),
                                  borderSide: const BorderSide(color: Color(0xACBAC980), width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(isLargeTablet ? 16 : isTablet ? 15 : 12),
                                  borderSide: const BorderSide(color: Color(0xACBAC980), width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(isLargeTablet ? 16 : isTablet ? 15 : 12),
                                  borderSide: const BorderSide(color: Color(0xFFED3237), width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Password Field
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeTablet ? 60 : isTablet ? 50 : isSmallScreen ? 20 : 30,
                          ),
                          margin: EdgeInsets.only(
                            bottom: isLargeTablet ? 15 : isTablet ? 12 : isSmallScreen ? 8 : 10,
                          ),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: isLargeTablet ? 500 : isTablet ? 400 : 328,
                            ),
                            height: isLargeTablet ? 60 : isTablet ? 55 : isSmallScreen ? 42 : 48,
                            child: TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: GoogleFonts.inter(
                                fontSize: isLargeTablet ? 20 : isTablet ? 18 : isSmallScreen ? 14 : 16,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey, size: isLargeTablet ? 26 : isTablet ? 24 : 20),
                                hintText: 'Password',
                                hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: isLargeTablet ? 20 : isTablet ? 18 : isSmallScreen ? 14 : 16),
                                filled: true,
                                fillColor: Colors.grey[200],
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isLargeTablet ? 24 : isTablet ? 20 : 16,
                                  vertical: isLargeTablet ? 18 : isTablet ? 16 : 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(isLargeTablet ? 16 : isTablet ? 15 : 12),
                                  borderSide: const BorderSide(color: Color(0xACBAC980), width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(isLargeTablet ? 16 : isTablet ? 15 : 12),
                                  borderSide: const BorderSide(color: Color(0xACBAC980), width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(isLargeTablet ? 16 : isTablet ? 15 : 12),
                                  borderSide: const BorderSide(color: Color(0xFFED3237), width: 1.5),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                    size: isLargeTablet ? 26 : isTablet ? 24 : 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        // "Remember me" Checkbox REMOVED completely

                        // Forgot Password
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeTablet ? 60 : isTablet ? 50 : isSmallScreen ? 20 : 30,
                          ),
                          margin: EdgeInsets.only(
                            bottom: isLargeTablet ? 15 : isTablet ? 12 : isSmallScreen ? 6 : 8,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.inter(
                                  fontSize: isLargeTablet ? 18 : isTablet ? 16 : isSmallScreen ? 12 : 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Sign In Button
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeTablet ? 60 : isTablet ? 50 : isSmallScreen ? 20 : 30,
                          ),
                          margin: EdgeInsets.only(
                            bottom: isLargeTablet ? 15 : isTablet ? 12 : isSmallScreen ? 8 : 10,
                          ),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: isLargeTablet ? 500 : isTablet ? 400 : 328,
                            ),
                            height: isLargeTablet ? 70 : isTablet ? 65 : isSmallScreen ? 48 : 55,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFED3237), Color(0xFF871C1F)],
                                  stops: [0.1181, 0.7688],
                                ),
                                borderRadius: BorderRadius.circular(isLargeTablet ? 35 : isTablet ? 35 : 30),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isLargeTablet ? 35 : isTablet ? 35 : 30),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? SizedBox(
                                  width: isLargeTablet ? 32 : isTablet ? 30 : 24,
                                  height: isLargeTablet ? 32 : isTablet ? 30 : 24,
                                  child: const CircularProgressIndicator(color: Colors.white),
                                )
                                    : Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: isLargeTablet ? 22 : isTablet ? 20 : isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Don't have an account? Sign Up
                        // In LoginScreen, find this part and change it:
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeTablet ? 60 : isTablet ? 50 : isSmallScreen ? 20 : 30,
                          ),
                          margin: EdgeInsets.only(
                            bottom: isLargeTablet ? 15 : isTablet ? 12 : isSmallScreen ? 8 : 10,
                          ),
                          child: Center(
                            child: TextButton(
                              onPressed: () {
                                // CHANGE THIS: from pushReplacement to push
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                                );
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: "Don't have an account? ",
                                  style: GoogleFonts.inter(
                                    color: Colors.grey[700],
                                    fontSize: isLargeTablet ? 18 : isTablet ? 16 : isSmallScreen ? 12 : 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Sign Up',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFE53935),
                                        fontSize: isLargeTablet ? 18 : isTablet ? 16 : isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Vector5.png
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(
                            bottom: isLargeTablet ? 5 : isTablet ? 5 : isSmallScreen ? 3 : 4,
                          ),
                          child: Image.asset('assets/images/Vector5.png', width: double.infinity, fit: BoxFit.fitWidth),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InwardSidesClipper extends CustomClipper<Path> {
  final double curveDepth;
  InwardSidesClipper({this.curveDepth = 20});

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, curveDepth);
    path.quadraticBezierTo(0, 0, curveDepth, 0);
    path.lineTo(size.width - curveDepth, 0);
    path.quadraticBezierTo(size.width, 0, size.width, curveDepth);
    path.lineTo(size.width, size.height - curveDepth);
    path.quadraticBezierTo(size.width, size.height, size.width - curveDepth, size.height);
    path.lineTo(curveDepth, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - curveDepth);
    path.lineTo(0, curveDepth);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
