import 'package:flutter/material.dart';
import '../../widgets/auth_field.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_drawer.dart'; // Import the AppDrawer

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  bool _isLoading = false;

  void _showMessage(String message, {bool shouldRedirect = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notification'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                if (shouldRedirect) {
                  Navigator.pop(context); // Redirect back to the previous screen
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _changePassword() async {
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      _showMessage('New passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await _authService.changePassword(
      _currentPasswordController.text.trim(),
      _newPasswordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (response != null && response['status'] == 'Success') {
      _showMessage(response['message'], shouldRedirect: true); // Redirect after showing message
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
    return Scaffold(
      appBar: AppBar( // Add AppBar for drawer access
        title: const Text('Change Password'),
        leading: IconButton(
          icon: const Icon(Icons.menu), // Icon to open the drawer
          onPressed: () {
            Scaffold.of(context).openDrawer(); // Open the drawer
          },
        ),
      ),
      drawer: const AppDrawer(), // Add AppDrawer here
      body: Container(
        width: double.infinity, // Ensure full width
        height: MediaQuery.of(context).size.height, // Full screen height
        decoration: BoxDecoration(
          color: Colors.brown, // Set background color (brown)
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpeg'),
            fit: BoxFit.cover, // Ensure the image covers the full screen
          ),
        ),
        child: Center( // Center the content
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Take minimum space
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Text color changed to white for visibility
                  ),
                ),

                const SizedBox(height: 30),

                // Form Fields
                AuthField(
                  controller: _currentPasswordController,
                  hintText: 'Current Password',
                  isPassword: true,
                  fillColor: Colors.white,
                ),
                const SizedBox(height: 16),
                AuthField(
                  controller: _newPasswordController,
                  hintText: 'New Password',
                  isPassword: true,
                  fillColor: Colors.white,
                ),
                const SizedBox(height: 16),
                AuthField(
                  controller: _confirmNewPasswordController,
                  hintText: 'Confirm New Password',
                  isPassword: true,
                  fillColor: Colors.white,
                ),

                const SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F), // Red
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading ? null : _changePassword,
                    child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
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
      ),
    );
  }
}