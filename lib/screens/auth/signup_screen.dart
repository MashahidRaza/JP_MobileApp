import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/social_login_button.dart';
import 'login_screen.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
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

  // ---- Material-like outlined decoration (floating label) ----
  InputDecoration _outlined(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5), // Material blue outline
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await _authService.register(
      _fullNameController.text.trim(),
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      selectedCity ?? '',
      _schoolController.text.trim(),
      selectedProvince ?? '', // send province here (instead of region text)
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
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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

  String? _confirmPassValidator(String? v) {
    final basic = _requiredValidator(v, field: 'Confirm Password');
    if (basic != null) return basic;
    if (v!.trim() != _passwordController.text.trim()) return 'Passwords do not match';
    return null;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final citiesForProvince = selectedProvince == null ? <String>[] : (pkData[selectedProvince] ?? <String>[]);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/background.jpeg'), fit: BoxFit.cover),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset('assets/images/logo.png', height: 100),
                const SizedBox(height: 40),

                const Text(
                  'Create New Account',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                ),
                const SizedBox(height: 24),

                // Outlined text fields (Material-like)
                TextFormField(
                  controller: _fullNameController,
                  validator: (v) => _requiredValidator(v, field: 'Full Name'),
                  decoration: _outlined('Full Name'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _usernameController,
                  validator: (v) => _requiredValidator(v, field: 'Username'),
                  decoration: _outlined('Username'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                  decoration: _outlined('Email'),
                ),
                const SizedBox(height: 16),

                // Province (Region) dropdown — replaces Region text field
                DropdownSearch<String>(
                  items: pkData.keys.toList(),
                  selectedItem: selectedProvince,
                  onChanged: (val) {
                    setState(() {
                      selectedProvince = val;
                      selectedCity = null; // reset city when province changes
                    });
                  },
                  validator: (value) => value == null ? 'Province is required' : null,
                  popupProps: const PopupProps.menu(showSearchBox: true),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: _outlined('Province (Region)'),
                  ),
                ),
                const SizedBox(height: 16),

                // City dropdown (filtered by province)
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
                    dropdownSearchDecoration: _outlined(
                      selectedProvince == null ? 'City (select province first)' : 'City',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _schoolController,
                  validator: (v) => _requiredValidator(v, field: 'School Name'),
                  decoration: _outlined('School Name'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  validator: (v) {
                    final basic = _requiredValidator(v, field: 'Password');
                    if (basic != null) return basic;
                    if (v!.trim().length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                  decoration: _outlined(
                    'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  validator: _confirmPassValidator,
                  decoration: _outlined(
                    'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.withOpacity(0.5))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Sign up with', style: TextStyle(fontSize: 14, color: Colors.red)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 16),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialLoginButton(imagePath: 'assets/images/google.png'),
                    SizedBox(width: 15),
                    SocialLoginButton(imagePath: 'assets/images/linkedin.png'),
                    SizedBox(width: 15),
                    SocialLoginButton(imagePath: 'assets/images/facebook.png'),
                  ],
                ),

                const SizedBox(height: 40),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: Colors.red),
                        children: [
                          TextSpan(text: 'Sign in', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
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
