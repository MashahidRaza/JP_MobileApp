import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/setting_item.dart';
import '../../widgets/app_drawer.dart';
import '../services/auth_service.dart';
import 'EditProfileScreen.dart';
import 'auth/change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  String _fullName = 'Loading...';
  String _email = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadUserData();
  }

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

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout(); // This removes auth_token + user details

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/login', (route) => false);
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
              height: responsive(100),
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

          // ================= LOGO BANNERS =================
          Positioned(
            top: media.padding.top + responsive(10),
            left: responsive(16),
            right: responsive(16),
            child: Visibility(
              visible: !isVerySmall,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                child: Image.asset('assets/images/Vector7.png', fit: BoxFit.fill),
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
                child: Image.asset('assets/images/vector8.png', fit: BoxFit.fill),
              ),
            ),
          ),

          // ================= MAIN CONTENT =================
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsive(16),
              media.padding.top + responsive(85),
              responsive(16),
              responsive(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'My Profile',
                    style: GoogleFonts.poppins(
                      fontSize: responsive(24),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF871C1F),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Profile Image
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: responsive(55),
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage('assets/images/profile.png')
                        as ImageProvider,
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: responsive(16),
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF871C1F),
                    ),
                  ),
                  Text(
                    _email,
                    style: const TextStyle(color: Color(0xFF871C1F)),
                  ),

                  const SizedBox(height: 32),

                  // Settings Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                            onTap: () async {
                              // Navigate to EditProfileScreen and wait for it to finish
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              );

                              // If profile was updated, reload the data
                              if (result == true) {
                                _loadUserData();
                                _loadProfileImage();
                              }
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
                                  builder: (_) => const ChangePasswordScreen(email: '',),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () => _logout(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFED3237),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Log out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

