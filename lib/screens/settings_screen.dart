import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildSettingsItem(
              context,
              icon: Icons.person,
              title: 'Account Settings',
              onTap: () {
                // Navigate to account settings
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                // Navigate to notification settings
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.lock,
              title: 'Privacy & Security',
              onTap: () {
                // Navigate to privacy settings
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.language,
              title: 'Language',
              trailing: Text(
                'English',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                // Navigate to language selection
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.color_lens,
              title: 'Theme',
              trailing: Text(
                'Light',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                // Navigate to theme selection
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {
                // Navigate to help center
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.info,
              title: 'About',
              onTap: () {
                // Navigate to about page
              },
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _showLogoutDialog(context);
                },
                child: Text(
                  'Log Out',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF2C3E50),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log Out',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Handle logout logic
              Navigator.popUntil(context, (route) => route.isFirst);
              // Navigate to login screen
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}