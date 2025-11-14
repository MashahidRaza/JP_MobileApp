import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/setting_item.dart';
import 'auth/change_password_screen.dart';
import '../../widgets/app_drawer.dart'; // Import the AppDrawer

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  String _fullName = 'Loading...';
  String _email = 'Loading...';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_picture.png';

      final savedImage = await File(image.path).copy(imagePath);

      setState(() {
        _profileImage = savedImage;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadUserData();
  }

  Future<void> _loadProfileImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/profile_picture.png';

    if (File(imagePath).existsSync()) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('fullName') ?? 'Unknown';
      _email = prefs.getString('email') ?? 'Unknown';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        // backgroundColor: const Color(0xFFD32F2F), // Set a solid color for the AppBar
      ),
      drawer: const AppDrawer(), // Add the AppDrawer here
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height, // Full screen height
        decoration: BoxDecoration(
          color: Colors.brown, // Set background color (brown)
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpeg'),
            fit: BoxFit.cover, // Ensure the image covers the full screen
          ),
        ),
        child: Center( // Center the content vertically
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Take minimum space
              children: [
                const SizedBox(height: 32),

                // Profile Image
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : const AssetImage('assets/images/profile.png')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  _fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _email,
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 32),

                // Card with settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        SettingItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          onTap: () {
                            // TODO: Navigate to edit profile screen
                          },
                        ),
                        const Divider(height: 1),
                        SettingItem(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        SettingItem(
                          icon: Icons.email_outlined,
                          title: 'Change Email',
                          onTap: () {
                            // TODO: Navigate to change email screen
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}