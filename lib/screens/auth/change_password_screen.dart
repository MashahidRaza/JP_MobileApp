import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main_navigation_screen.dart';
import '../../widgets/auth_field.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_drawer.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;
  const ChangePasswordScreen({super.key, required this.email});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _currentPasswordController =
  TextEditingController();
  final TextEditingController _newPasswordController =
  TextEditingController();
  final TextEditingController _confirmNewPasswordController =
  TextEditingController();

  bool _isLoading = false;

  void _showMessage(String message, {bool shouldRedirect = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Message'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop(); // close dialog

              if (shouldRedirect) {
                // SAFELY change tab instead of popping navigator
                MainNavigationScreen.of(context)?.changeTab(0);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  void _changePassword() async {
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      _showMessage('New passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    final response = await _authService.changePassword(
      _currentPasswordController.text.trim(),
      _newPasswordController.text.trim(),
    );



    setState(() => _isLoading = false);

    if (response != null && response['status'] == 'Success') {
      _showMessage(response['message'], shouldRedirect: true);
    } else {
      _showMessage(response?['message'] ?? 'Password change failed!');
    }
  }


  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
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
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // ================= TOP GRADIENT =================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: responsive(120),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFED3237),
                    Color(0x00FFFFFF),
                  ],
                  stops: [0.0, 0.84],
                ),
              ),
            ),
          ),

          // ================= VECTOR 7 =================
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
                child: Image.asset('assets/images/Vector7.png',
                    fit: BoxFit.fill),
              ),
            ),
          ),

          // ================= VECTOR 8 =================
          Positioned(
            top: responsive(520),
            left: responsive(-200),
            child: Transform.rotate(
              angle: -12.24 * math.pi / 180,
              child: SizedBox(
                width: responsive(847.9),
                height: responsive(347.6),
                child: Image.asset('assets/images/vector8.png',
                    fit: BoxFit.fill),
              ),
            ),
          ),

          // ================= LOGO ROW =================
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
                      width: responsive(90)),
                  Image.asset('assets/images/stem.png',
                      width: responsive(60)),
                  Image.asset('assets/images/javed.png',
                      width: responsive(70)),
                ],
              ),
            ),
          ),

          // ================= CONTENT =================
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsive(16),
              media.padding.top + responsive(120),
              responsive(16),
              responsive(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: GoogleFonts.poppins(
                      fontSize: responsive(24),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF871C1F),
                    ),
                  ),
                  const SizedBox(height: 30),

                  AuthField(
                    controller: _currentPasswordController,
                    hintText: 'Current Password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),

                  AuthField(
                    controller: _newPasswordController,
                    hintText: 'New Password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),

                  AuthField(
                    controller: _confirmNewPasswordController,
                    hintText: 'Confirm New Password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED3237),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading ? null : _changePassword,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                          color: Colors.white)
                          : const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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