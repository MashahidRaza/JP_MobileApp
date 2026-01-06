import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../main_navigation_screen.dart';
import '../services/Forget.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _profileImage;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();

  String? selectedProvince;
  String? selectedCity;

  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _allSeries = [];
  List<String> _selectedSeriesNames = [];
  List<int> _selectedSeriesIds = [];
  bool _isLoadingSeries = false;
  bool _isLoading = false;

  // Form validation errors
  String? _fullNameError;
  String? _emailError;
  String? _provinceError;
  String? _cityError;
  String? _schoolError;
  String? _seriesError;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Pakistan Provinces/Regions → Cities
  final Map<String, List<String>> pkData = {
    'Punjab': [
      'Lahore','Faisalabad','Rawalpindi','Gujranwala','Multan','Sialkot','Bahawalpur','Sargodha',
      'Sheikhupura','Rahim Yar Khan','Jhang','Kasur','Okara','Mandi Bahauddin','Bhakkar','Chiniot',
      'Jhelum','Gujrat','Hafizabad','Mianwali','Pakpattan','Vehari','Dera Ghazi Khan','Khanewal',
      'Layyah','Burewala','Sadiqabad','Arifwala','Jaranwala','Pattoki','Chakwal','Toba Tek Singh'
    ],
    'Sindh': ['Karachi','Hyderabad','Sukkur','Larkana','Nawabshah','Mirpur Khas','Dadu','Shikarpur','Ghotki','Thatta','Tando Adam','Tando Allahyar','Jacobabad','Khairpur'],
    'Khyber Pakhtunkhwa': ['Peshawar','Mardan','Swabi','Kohat','Charsadda','Nowshera','Dera Ismail Khan','Bannu','Karak','Abbottabad','Mansehra','Mingora','Timergara','Parachinar'],
    'Balochistan': ['Quetta','Khuzdar','Turbat','Gwadar','Chaman','Zhob','Qila Saifullah','Kalat','Pishin','Loralai','Usta Muhammad','Mastung','Barkhan'],
    'Islamabad Capital Territory': ['Islamabad'],
    'Gilgit-Baltistan': ['Gilgit','Skardu'],
    'Azad Jammu & Kashmir': ['Muzaffarabad','Mirpur','Kotli']
  };

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadUserData();
    _fetchAllSeries();
  }

  Future<void> _loadProfileImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/profile_picture.png';
    if (File(imagePath).existsSync()) {
      setState(() => _profileImage = File(imagePath));
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load ALL values first
    final loadedFullName = prefs.getString('fullName') ?? '';
    final loadedEmail = prefs.getString('email') ?? '';
    final loadedSchool = prefs.getString('schoolName') ?? '';

    // FIX: Handle string "null" values
    String? loadedProvince = prefs.getString('regionName');
    String? loadedCity = prefs.getString('cityName');

    // Convert string "null" to actual null
    if (loadedProvince == 'null' || loadedProvince?.isEmpty == true) {
      loadedProvince = null;
    }
    if (loadedCity == 'null' || loadedCity?.isEmpty == true) {
      loadedCity = null;
    }

    debugPrint('=== LOADING FROM PREFS ===');
    debugPrint('schoolName from prefs: "$loadedSchool"');
    debugPrint('regionName from prefs: "$loadedProvince"');
    debugPrint('cityName from prefs: "$loadedCity"');

    // Set all controllers and values
    _fullNameController.text = loadedFullName;
    _emailController.text = loadedEmail;
    _schoolController.text = loadedSchool;

    setState(() {
      selectedProvince = loadedProvince;
      selectedCity = loadedCity;

      final seriesIdsStr = prefs.getString('seriesIds') ?? '';
      if (seriesIdsStr.isNotEmpty) {
        _selectedSeriesIds = seriesIdsStr.split(',').map((e) => int.tryParse(e) ?? 0).toList();
        debugPrint('Loaded Series IDs: $_selectedSeriesIds');
      }
    });
  }

  Future<void> _loadSeriesNamesFromIds() async {
    if (_allSeries.isNotEmpty && _selectedSeriesIds.isNotEmpty) {
      final seriesNames = <String>[];
      for (final id in _selectedSeriesIds) {
        final series = _allSeries.firstWhere(
              (s) => (s['Id'] is int && s['Id'] == id) ||
              (s['Id'] is String && int.tryParse(s['Id']) == id),
          orElse: () => {},
        );
        if (series.isNotEmpty && series['Name'] != null) {
          seriesNames.add(series['Name'].toString());
        }
      }
      setState(() {
        _selectedSeriesNames = seriesNames;
      });
    }
  }

  Future<void> _fetchAllSeries() async {
    setState(() {
      _isLoadingSeries = true;
    });

    try {
      final series = await _authService.getAllSeries();
      setState(() {
        _allSeries = series;
      });
      // After loading series, load series names if we have IDs
      if (_selectedSeriesIds.isNotEmpty) {
        _loadSeriesNamesFromIds();
      }
    } catch (e) {
      debugPrint('Series fetch error: $e');
    } finally {
      setState(() {
        _isLoadingSeries = false;
      });
    }
  }

  List<int> _getSelectedSeriesIds() {
    return _selectedSeriesNames.map((seriesName) {
      final series = _allSeries.firstWhere(
            (s) => s['Name']?.toString().trim() == seriesName,
        orElse: () => {'Id': 0},
      );
      final id = series['Id'];
      return id is int ? id : (id is String ? int.tryParse(id) ?? 0 : 0);
    }).where((id) => id != 0).toList();
  }

  // Validation methods
  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full Name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateProvince(String? value) {
    if (value == null || value.isEmpty) {
      return 'Province is required';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (selectedProvince == null) {
      return 'Please select a province first';
    }
    if (value == null || value.isEmpty) {
      return 'City is required';
    }
    return null;
  }

  String? _validateSchool(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business/School Name is required';
    }
    return null;
  }

  String? _validateSeries() {
    if (_selectedSeriesNames.isEmpty) {
      return 'Please select at least one series';
    }
    if (_selectedSeriesNames.length > 5) { // Changed from 2 to 5
      return 'Maximum 5 series allowed'; // Changed from 2 to 5
    }
    return null;
  }

  // Validate all fields
  bool _validateForm() {
    setState(() {
      _fullNameError = _validateFullName(_fullNameController.text);
      _emailError = _validateEmail(_emailController.text);
      _provinceError = _validateProvince(selectedProvince);
      _cityError = _validateCity(selectedCity);
      _schoolError = _validateSchool(_schoolController.text);
      _seriesError = _validateSeries();
    });

    return _fullNameError == null &&
        _emailError == null &&
        _provinceError == null &&
        _cityError == null &&
        _schoolError == null &&
        _seriesError == null;
  }

  Future<void> _saveProfile() async {
    // Clear previous errors
    setState(() {
      _fullNameError = null;
      _emailError = null;
      _provinceError = null;
      _cityError = null;
      _schoolError = null;
      _seriesError = null;
    });

    // Validate form
    if (!_validateForm()) {
      // Show error message
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final seriesIds = _getSelectedSeriesIds();
      if (seriesIds.isEmpty) {
        throw Exception('No valid series selected');
      }

      final data = await ApiConstants.editProfile(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        cityName: selectedCity ?? '',
        regionName: selectedProvince ?? '',
        schoolName: _schoolController.text.trim(),
        seriesIds: seriesIds.join(','),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fullName', _fullNameController.text.trim());
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('schoolName', _schoolController.text.trim());
      await prefs.setString('regionName', selectedProvince ?? '');
      await prefs.setString('cityName', selectedCity ?? '');
      await prefs.setString('seriesIds', seriesIds.join(','));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['Message'] ?? 'Profile updated successfully!'),
          backgroundColor: const Color(0xFF5DE35D),
          duration: const Duration(seconds: 2),
        ),
      );

      // 🔄 Notify MainNavigationScreen to refresh SeriesScreen
      MainNavigationScreen.of(context)?.refreshSeriesScreen();

      Navigator.of(context).pop(true); // reload ProfileScreen
    } catch (e, stack) {
      debugPrint('Error updating profile: $e');
      debugPrintStack(stackTrace: stack);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final savedImage = await File(image.path).copy('${directory.path}/profile_picture.png');
      setState(() => _profileImage = savedImage);
    }
  }

  Widget _buildSelectedSeriesChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedSeriesNames.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Selected Series',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFED3237).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_selectedSeriesNames.length}/5', // Changed from /2 to /5
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFED3237),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSeriesNames.map((seriesName) {
              return Chip(
                label: Text(
                  seriesName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: const Color(0xFFED3237).withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 16),
                deleteIconColor: const Color(0xFFED3237),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                onDeleted: () {
                  setState(() {
                    _selectedSeriesNames.remove(seriesName);
                    _seriesError = _validateSeries();
                  });
                },
              );
            }).toList(),
          ),
        ],
        if (_seriesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _seriesError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final double scale = width / 430;
    double responsive(double size) => size * scale;
    final bool isVerySmall = width < 350;
    final citiesForProvince = selectedProvince == null ? <String>[] : pkData[selectedProvince] ?? [];

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

          // ================= VECTOR 7 (TOP RIGHT → LEFT FLOW) =================
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
                  child: Image.asset(
                    'assets/images/Vector7.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),

          // ================= VECTOR 8 (BOTTOM LEFT SUPPORT) =================
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
                  child: Image.asset(
                    'assets/images/vector8.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),
          // ================= MAIN CONTENT =================
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsive(16),
              media.padding.top + responsive(115),
              responsive(16),
              0,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      fontSize: responsive(24),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF871C1F),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Profile Image
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: responsive(110),
                          height: responsive(110),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFED3237),
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : const AssetImage('assets/images/profile.png') as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFED3237),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Full Name with error
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _fullNameController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Full Name *',
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                                errorBorder: _fullNameError != null
                                    ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red),
                                )
                                    : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _fullNameError = _validateFullName(value);
                                });
                              },
                            ),
                            if (_fullNameError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 16),
                                child: Text(
                                  _fullNameError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Email with error
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Email *',
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.mail_outline, color: Colors.grey),
                                errorBorder: _emailError != null
                                    ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red),
                                )
                                    : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _emailError = _validateEmail(value);
                                });
                              },
                            ),
                            if (_emailError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 16),
                                child: Text(
                                  _emailError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Province (Region) dropdown with error
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownSearch<String>(
                              items: pkData.keys.toList(),
                              selectedItem: selectedProvince,
                              onChanged: (val) {
                                setState(() {
                                  selectedProvince = val;
                                  selectedCity = null;
                                  _provinceError = _validateProvince(val);
                                  _cityError = _validateCity(null);
                                });
                              },
                              popupProps: const PopupProps.menu(showSearchBox: true),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Province (Region) *',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                                  errorBorder: _provinceError != null
                                      ? OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red),
                                  )
                                      : null,
                                ),
                              ),
                            ),
                            if (_provinceError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 16),
                                child: Text(
                                  _provinceError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // City dropdown with error
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownSearch<String>(
                              items: citiesForProvince,
                              selectedItem: selectedCity,
                              onChanged: (val) {
                                setState(() {
                                  selectedCity = val;
                                  _cityError = _validateCity(val);
                                });
                              },
                              enabled: selectedProvince != null,
                              popupProps: const PopupProps.menu(showSearchBox: true),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: selectedProvince == null
                                      ? 'City (select province first) *'
                                      : 'City *',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.grey),
                                  errorBorder: _cityError != null
                                      ? OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red),
                                  )
                                      : null,
                                ),
                              ),
                            ),
                            if (_cityError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 16),
                                child: Text(
                                  _cityError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Business/School Name with error
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _schoolController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Business/School Name *',
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.school_outlined, color: Colors.grey),
                                errorBorder: _schoolError != null
                                    ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red),
                                )
                                    : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _schoolError = _validateSchool(value);
                                });
                              },
                            ),
                            if (_schoolError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 16),
                                child: Text(
                                  _schoolError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Series Multi-Select Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownSearch<String>.multiSelection(
                              items: _allSeries
                                  .where((series) =>
                              series['Name'] != null &&
                                  series['Name'].toString().trim().isNotEmpty)
                                  .map((series) => series['Name'].toString().trim())
                                  .toList(),
                              selectedItems: _selectedSeriesNames,
                              popupProps: PopupPropsMultiSelection.menu(
                                showSearchBox: true,
                                showSelectedItems: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    labelText: "Search series...",
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                listViewProps: const ListViewProps(
                                  padding: EdgeInsets.all(8),
                                ),
                                selectionWidget: (context, item, isSelected) {
                                  final maxReached = _selectedSeriesNames.length >= 5 && !isSelected; // Changed from 2 to 5
                                  return Checkbox(
                                    value: isSelected,
                                    onChanged: maxReached
                                        ? null
                                        : (value) {
                                      if (value == true && _selectedSeriesNames.length < 5) { // Changed from 2 to 5
                                        setState(() {
                                          _selectedSeriesNames.add(item);
                                          _seriesError = _validateSeries();
                                        });
                                      } else if (value == false) {
                                        setState(() {
                                          _selectedSeriesNames.remove(item);
                                          _seriesError = _validateSeries();
                                        });
                                      }
                                    },
                                    activeColor: const Color(0xFFED3237),
                                    fillColor: maxReached
                                        ? MaterialStateProperty.all(Colors.grey[300])
                                        : null,
                                  );
                                },
                              ),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Select Series *',
                                  hintText: _selectedSeriesNames.isEmpty
                                      ? 'Choose up to 5 series' // Changed from 2 to 5
                                      : '${_selectedSeriesNames.length} selected',
                                  helperText: 'Maximum 5 series allowed', // Changed from 2 to 5
                                  helperStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: _isLoadingSeries
                                      ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFED3237)),
                                    ),
                                  )
                                      : const Icon(Icons.library_books_outlined, color: Colors.grey),
                                  errorBorder: _seriesError != null
                                      ? OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red),
                                  )
                                      : null,
                                ),
                              ),
                              onChanged: (selectedItems) {
                                setState(() {
                                  _selectedSeriesNames = selectedItems;
                                  _seriesError = _validateSeries();
                                });
                              },
                            ),
                          ],
                        ),

                        // Show selected series as chips
                        _buildSelectedSeriesChips(),

                        const SizedBox(height: 20),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFED3237),
                                  Color(0xFF871C1F),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _saveProfile,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save Profile',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}