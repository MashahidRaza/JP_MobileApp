import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? selectedProvince;
  String? selectedCity;

  // New variables for series dropdown
  List<Map<String, dynamic>> _allSeries = [];
  List<String> _selectedSeriesNames = [];
  List<int> _selectedSeriesIds = [];
  bool _isLoadingSeries = false;

  /// Pakistan Provinces/Regions → Cities
  final Map<String, List<String>> pkData = {
    'Punjab': [
      'Lahore','Faisalabad','Rawalpindi','Gujranwala','Multan','Sialkot','Bahawalpur','Sargodha',
      'Sheikhupura','Rahim Yar Khan','Jhang','Kasur','Okara','Mandi Bahauddin','Bhakkar','Chiniot',
      'Jhelum','Gujrat','Hafizabad','Mianwali','Pakpattan','Vehari','Dera Ghazi Khan','Khanewal',
      'Layyah','Burewala','Sadiqabad','Arifwala','Jaranwala','Pattoki','Chakwal','Toba Tek Singh'
    ],
    'Sindh': [
      'Karachi','Hyderabad','Sukkur','Larkana','Nawabshah','Mirpur Khas','Dadu','Shikarpur','Ghotki',
      'Thatta','Tando Adam','Tando Allahyar','Jacobabad','Khairpur'
    ],
    'Khyber Pakhtunkhwa': [
      'Peshawar','Mardan','Swabi','Kohat','Charsadda','Nowshera','Dera Ismail Khan','Bannu','Karak',
      'Abbottabad','Mansehra','Mingora','Timergara','Parachinar'
    ],
    'Balochistan': [
      'Quetta','Khuzdar','Turbat','Gwadar','Chaman','Zhob','Qila Saifullah','Kalat','Pishin','Loralai',
      'Usta Muhammad','Mastung','Barkhan'
    ],
    'Islamabad Capital Territory': ['Islamabad'],
    'Gilgit-Baltistan': ['Gilgit','Skardu'],
    'Azad Jammu & Kashmir': ['Muzaffarabad','Mirpur','Kotli']
  };

  @override
  void initState() {
    super.initState();
    _fetchAllSeries();
  }

  Future<void> _fetchAllSeries() async {
    setState(() => _isLoadingSeries = true);

    try {
      final series = await _authService.getAllSeries();
      setState(() {
        _allSeries = series;
        // Pre-select series names after series list is loaded
        if (_selectedSeriesIds.isNotEmpty) {
          _selectedSeriesNames = _allSeries
              .where((s) => _selectedSeriesIds.contains(s['Id']) && s['Name'] != null)
              .map((s) => s['Name'].toString().trim())
              .toList();
        }
      });
    } catch (e) {
      debugPrint('Series fetch error: $e');
    } finally {
      setState(() => _isLoadingSeries = false);
    }
  }
  // Get series IDs from selected series names
  List<int> _getSelectedSeriesIds() {
    return _selectedSeriesNames.map((seriesName) {
      final series = _allSeries.firstWhere(
            (s) => s['Name']?.toString().trim() == seriesName,
        orElse: () => {'Id': 0},
      );
      final id = series['Id'];
      return id is int ? id : 0;
    }).where((id) => id != 0).toList();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Get series IDs from selected series names
    _selectedSeriesIds = _getSelectedSeriesIds();

    setState(() => _isLoading = true);

    final response = await _authService.register(
      fullName: _fullNameController.text.trim(),
      mobileNumber: _mobileNumberController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      cityName: selectedCity ?? '',
      schoolName: _schoolController.text.trim(),
      regionName: selectedProvince ?? '',
      seriesIds: _selectedSeriesIds,
    );

    setState(() => _isLoading = false);

    if (response != null && (response['status']?.toString().toLowerCase() == 'success')) {
      _showSuccessDialog(response['message'] ?? 'Registration successful.');
    } else {
      _showErrorDialog(response?['message'] ?? 'Registration failed. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success', style: TextStyle(color: Colors.green)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _requiredValidator(String? v, {String field = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  String? _emailValidator(String? v) {
    final basic = _requiredValidator(v, field: 'Email');
    if (basic != null) return basic;
    final emailReg = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailReg.hasMatch(v!.trim())) return 'Enter a valid email';
    return null;
  }

  String? _mobileNumberValidator(String? v) {
    final basic = _requiredValidator(v, field: 'Mobile Number');
    if (basic != null) return basic;

    final trimmed = v!.trim();
    final cleaned = trimmed.replaceAll(RegExp(r'\s+'), '');

    if (cleaned.startsWith('+')) {
      if (cleaned.startsWith('+92')) {
        if (cleaned.length != 13) {
          return 'Must be 13 characters: +92***********';
        }
        if (!RegExp(r'^\+92[0-9]{10}$').hasMatch(cleaned)) {
          return 'Invalid format: +92**********';
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
        return 'Must be 11 digits: 03*********';
      }
      if (!RegExp(r'^03[0-9]{9}$').hasMatch(cleaned)) {
        return 'Invalid format: 03**********';
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

  String? _confirmPassValidator(String? v) {
    final basic = _requiredValidator(v, field: 'Confirm Password');
    if (basic != null) return basic;
    if (v!.trim() != _passwordController.text.trim()) return 'Passwords do not match';
    return null;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildSelectedSeriesChips() {
    if (_selectedSeriesNames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final citiesForProvince = selectedProvince == null ? <String>[] : (pkData[selectedProvince] ?? <String>[]);

    return Scaffold(
      body: Stack(
        children: [
          // Main content container (your original UI)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFED3237),
                  Colors.white,
                ],
                stops: [0.0, 0.8414],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Bee image at top
                    ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        widthFactor: 0.6,
                        heightFactor: 0.6,
                        child: Image.asset(
                          'assets/images/image 6.png',
                          width: 170,
                          height: 170,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Title
                    Text(
                      'Create New Account',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF871C1F),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // White form container
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Full Name Field
                          TextFormField(
                            controller: _fullNameController,
                            validator: (v) => _requiredValidator(v, field: 'Full Name'),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Mobile Number Field
                          TextFormField(
                            controller: _mobileNumberController,
                            keyboardType: TextInputType.phone,
                            validator: _mobileNumberValidator,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9\+]')),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Mobile Number',
                              hintText: '03XXXXXXXXX or +92XXXXXXXXXXX',
                              helperText: 'Pakistani: 03XXXXXXXXX • International: +92XXXXXXXXXXX',
                              helperStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.phone_android_outlined, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: _emailValidator,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.mail_outline, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Province (Region) dropdown
                          DropdownSearch<String>(
                            items: pkData.keys.toList(),
                            selectedItem: selectedProvince,
                            onChanged: (val) {
                              setState(() {
                                selectedProvince = val;
                                selectedCity = null;
                              });
                            },
                            validator: (value) => value == null ? 'Province is required' : null,
                            popupProps: const PopupProps.menu(showSearchBox: true),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Province (Region)',
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // City dropdown
                          DropdownSearch<String>(
                            items: citiesForProvince,
                            selectedItem: selectedCity,
                            onChanged: (val) => setState(() => selectedCity = val),
                            enabled: selectedProvince != null,
                            validator: (_) {
                              if (selectedProvince == null) return 'Select a province first';
                              return selectedCity == null ? 'City is required' : null;
                            },
                            popupProps: const PopupProps.menu(showSearchBox: true),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: selectedProvince == null ? 'City (select province first)' : 'City',
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Business Name Field
                          TextFormField(
                            controller: _schoolController,
                            validator: (v) => _requiredValidator(v, field: 'Business Name'),
                            decoration: InputDecoration(
                              labelText: 'Business Name',
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.school_outlined, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Series Multi-Select Dropdown with maximum 5 selections (changed from 2)
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
                                      });
                                    } else if (value == false) {
                                      setState(() {
                                        _selectedSeriesNames.remove(item);
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
                                labelText: 'Select Series',
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
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFED3237)),
                                  ),
                                )
                                    : const Icon(Icons.library_books_outlined, color: Colors.grey),
                              ),
                            ),
                            onChanged: (selectedItems) {
                              if (selectedItems.length <= 5) { // Changed from 2 to 5
                                setState(() {
                                  _selectedSeriesNames = selectedItems;
                                });
                              }
                            },
                            validator: (selectedItems) {
                              if (selectedItems != null && selectedItems.length > 5) { // Changed from 2 to 5
                                return 'Maximum 5 series allowed'; // Changed from 2 to 5
                              }
                              return null;
                            },
                          ),

                          // Show selected series as chips
                          _buildSelectedSeriesChips(),

                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            validator: (v) {
                              final basic = _requiredValidator(v, field: 'Password');
                              if (basic != null) return basic;
                              if (v!.trim().length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            validator: _confirmPassValidator,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Sign Up Button
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading ? null : _register,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                  'Sign Up',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Already have an account? Sign in
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: "Already have an account? ",
                            style: GoogleFonts.inter(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE53935),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Bottom logos
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/insp.png',
                            width: 105,
                            height: 45,
                            fit: BoxFit.contain,
                          ),
                          Image.asset(
                            'assets/images/stem.png',
                            width: 70,
                            height: 52,
                            fit: BoxFit.contain,
                          ),
                          Image.asset(
                            'assets/images/javed.png',
                            width: 82,
                            height: 47,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= BACK BUTTON =================
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 16,
            child: GestureDetector(
              onTap: () {
                // This will properly navigate back to LoginScreen
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFFED3237),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}