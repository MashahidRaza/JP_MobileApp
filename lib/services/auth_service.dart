import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Result object for downloads
class DownloadResult {
  final String filename;
  final String? url; // if server returns a URL
  final List<int>? bytes; // if server returns bytes
  final String? contentType;

  DownloadResult({
    required this.filename,
    this.url,
    this.bytes,
    this.contentType,
  });

  bool get hasUrl => url != null && url!.isNotEmpty;
  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
}

class AuthService {
  // Your API base
  static const String baseUrl = 'https://jpapi.inspirertechnologies.com/api';

  // SharedPreferences keys
  static const String _kToken = 'auth_token';
  static const String _kFullName = 'fullName';
  static const String _kEmail = 'email';
  static const String _kMobileNumber = 'mobileNumber';
  static const String _kSeriesIds = 'seriesIds';
  static const String _kTokenExpiry = 'token_expiry';
  // Global navigator key for redirect on token expiry
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // ---------- Helpers ----------
  bool _looksLikeJson(String? contentType) {
    if (contentType == null) return false;
    final ct = contentType.toLowerCase();
    return ct.contains('application/json') || ct.contains('json');
  }

  Map<String, dynamic>? _decodeJsonSafe(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null; // not JSON
    }
  }

  bool _isSuccessStatus(int code) => code == 200 || code == 201 || code == 204;

  String? _filenameFromContentDisposition(String? cd) {
    if (cd == null) return null;
    final fnStar = RegExp(r"filename\*=([^']*)''([^;]+)").firstMatch(cd);
    if (fnStar != null) return Uri.decodeFull(fnStar.group(2)!);
    final fn = RegExp(r'filename="?([^"]+)"?').firstMatch(cd);
    if (fn != null) return fn.group(1);
    return null;
  }

  // ---------- Auth APIs ----------
  Future<bool> login(String mobileNumber, String password) async {
    try {
      final uri = Uri.parse('https://jpapi.inspirertechnologies.com/api/Auth/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'password': password,
        }),
      );

      print('✅ Debug: Login response status = ${response.statusCode}');
      print('🔍 Debug: Login response body = ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // 🔑 Save token
        final token = data['token'] as String?;
        if (token == null || token.isEmpty) return false;
        await prefs.setString(_kToken, token);

        // ⏱️ Save token expiration
        final expirationRaw = data['expiration'];
        if (expirationRaw != null) {
          final expiryDate = DateTime.parse(expirationRaw).toUtc();
          await prefs.setInt(_kTokenExpiry, expiryDate.millisecondsSinceEpoch);
          print('⏱️ Token expires at: $expiryDate');
        }

        // 👤 Save user details
        final user = data['user'];
        if (user is Map<String, dynamic>) {
          final fullName = user['fullName'] ?? 'User';
          final email = user['email'] ?? 'Not provided';
          final mobile = user['username'] ?? mobileNumber;
          final cityName = user['CityName'] ?? '';
          final regionName = user['RegionName'] ?? '';
          final schoolName = user['SchoolName'] ?? '';
          final seriesIdsRaw = user['seriesIds'] ?? '';

          await prefs.setString(_kFullName, fullName);
          await prefs.setString(_kEmail, email);
          await prefs.setString(_kMobileNumber, mobile);
          await prefs.setString('cityName', cityName);
          await prefs.setString('regionName', regionName);
          await prefs.setString('schoolName', schoolName);
          await prefs.setString(_kSeriesIds, seriesIdsRaw);

          print('✅ Debug: User saved');
          print('  - Name: $fullName');
          print('  - Email: $email');
          print('  - City: $cityName');
          print('  - Province: $regionName');
          print('  - School: $schoolName');
          print('  - SeriesIds: $seriesIdsRaw');
        }

        return true;
      }

      return false;
    } catch (e) {
      print('❌ Login error: $e');
      return false;
    }
  }



  Future<Map<String, dynamic>> register({
    required String fullName,
    required String mobileNumber,
    required String email,
    required String password,
    required String cityName,
    required String schoolName,
    required String regionName,
    required List<int> seriesIds,
  }) async {
    final uri = Uri.parse('$baseUrl/Auth/register');

    // 🔹 Backend expects seriesIds as STRING: "6,3"
    final payload = {
      'FullName': fullName,
      'mobileNumber': mobileNumber,
      'Email': email,
      'Password': password,
      'CityName': cityName,
      'SchoolName': schoolName,
      'RegionName': regionName,
      'seriesIds': seriesIds.join(','), // ✅ IMPORTANT FIX
    };

    try {
      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 30));

      print('🟢 Register status: ${response.statusCode}');
      print('🟢 Register body: ${response.body}');

      final isJson = _looksLikeJson(response.headers['content-type']);
      final data = isJson ? _decodeJsonSafe(response) : null;

      String readMessage() {
        final map = data as Map<String, dynamic>?;
        return map?['Message']?.toString() ??
            map?['message']?.toString() ??
            'Something went wrong';
      }

      String readStatus() {
        final map = data as Map<String, dynamic>?;
        return map?['Status']?.toString() ??
            map?['status']?.toString() ??
            'Error';
      }

      // ✅ SUCCESS (201 / 200)
      if (_isSuccessStatus(response.statusCode)) {
        return {
          'status': readStatus(),
          'message': readMessage(),
        };
      }

      // ❌ ERROR (400 / 409 / 500)
      return {
        'status': readStatus(),
        'message': readMessage(), // ✅ shows "User already exists!"
      };
    } catch (e) {
      print('❌ Register API exception: $e');
      return {
        'status': 'Error',
        'message': 'Could not contact server. Please try again.',
      };
    }
  }


  Future<String> getUserSeriesIds() async {
    final prefs = await SharedPreferences.getInstance();
    final seriesString = prefs.getString(_kSeriesIds) ?? '';
    print('🔍 Debug: getUserSeriesIds = $seriesString');
    return seriesString;
  }

  Future<bool> loginWithUsername(String username, String password) async {
    return login(username, password);
  }

  Future<Map<String, dynamic>> registerOld(
      String fullName,
      String userName,
      String email,
      String password,
      String cityName,
      String schoolName,
      String regionName,
      ) async {
    return register(
      fullName: fullName,
      mobileNumber: userName,
      email: email,
      password: password,
      cityName: cityName,
      schoolName: schoolName,
      regionName: regionName,
      seriesIds: [],
    );
  }

  Future<Map<String, dynamic>?> changePassword(
      String currentPassword,
      String newPassword,
      ) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/Auth/change-password');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;

      // ✅ Backend logical error (Status = Error)
      if (data != null && data['Status'] == 'Error') {
        return {
          'status': 'Error',
          'message': data['Message'] ?? 'Password change failed',
        };
      }

      // ✅ HTTP error but backend message exists
      if (response.statusCode != 200 && response.statusCode != 204) {
        return {
          'status': 'Error',
          'message': data?['Message'] ?? 'Password change failed',
        };
      }

      // ✅ Success
      return {
        'status': 'Success',
        'message': data?['Message'] ?? 'Password changed successfully.',
      };
    } catch (e) {
      debugPrint('❌ changePassword exception: $e');
      return {
        'status': 'Error',
        'message': 'Could not contact server. Please try again.',
      };
    }
  }
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = prefs.getInt(_kTokenExpiry);
    if (expiry == null) return true;
    return DateTime.now().millisecondsSinceEpoch > expiry;
  }

  Future<void> forceLogout() async {
    final prefs = await SharedPreferences.getInstance();

    // ❌ DO NOT clear everything
    // await prefs.clear();

    // ✅ Remove ONLY auth/session data
    await prefs.remove(_kToken);
    await prefs.remove(_kTokenExpiry);

    // Optional: user-related cached data

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );
  }


  // ---------- Files APIs ----------
  Future<List<Map<String, dynamic>>> getFiles() async {
    try {
      final token = await getToken();

      print('🔍 Debug: Token = $token');

      if (token == null || token.isEmpty) {
        print('⚠️ Debug: No token, logging out...');
        await logout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        return <Map<String, dynamic>>[];
      }

      final prefs = await SharedPreferences.getInstance();
      final seriesString = prefs.getString(_kSeriesIds) ?? '';

      print('🔍 Debug: Series IDs = $seriesString');

      if (seriesString.isEmpty) {
        print('⚠️ Debug: No series IDs found, returning empty list');
        return <Map<String, dynamic>>[];
      }

      // Use the correct endpoint with series ID
      final uri = Uri.parse('$baseUrl/FileDownloads/files/$seriesString');
      print('🔍 Debug: API URL = $uri');

      final response = await authenticatedRequest(() async {
        return await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      });

      print('✅ Debug: Response status = ${response.statusCode}');
      print('🔍 Debug: Response body = ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('⚠️ Debug: Response body empty');
          return <Map<String, dynamic>>[];
        }

        final decoded = jsonDecode(response.body);
        print('🔍 Debug: Decoded response type = ${decoded.runtimeType}');

        // Handle different response formats
        List<dynamic> fileList = [];

        if (decoded is List) {
          fileList = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          fileList = decoded['data'] as List;
        } else if (decoded is Map && decoded.containsKey('files')) {
          fileList = decoded['files'] as List;
        } else if (decoded is Map && decoded.containsKey('Children')) {
          fileList = [decoded]; // Single folder structure
        } else {
          fileList = [decoded];
        }

        print('✅ Debug: Number of items = ${fileList.length}');

        if (fileList.isNotEmpty) {
          print('🔍 Debug: First item keys = ${(fileList.first as Map).keys}');
          print('🔍 Debug: First item = ${fileList.first}');
        }

        return fileList.cast<Map<String, dynamic>>();
      } else {
        print('❌ Debug: Non-200 response: ${response.statusCode}');
        throw Exception('Failed to load files: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Debug: Error fetching files: $e');
      rethrow;
    }
  }

  Future<DownloadResult> downloadFile(String fileName) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        await logout();
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        throw Exception('No token available');
      }

      // Remove leading slash if present
      final cleanFileName = fileName.startsWith('/') ? fileName.substring(1) : fileName;
      final uri = Uri.parse('$baseUrl/filedownloads/download');

      print('🔍 Debug: Downloading file: $cleanFileName');

      final response = await authenticatedRequest(() async {
        return await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept': 'application/octet-stream, application/pdf, */*',
          },
          body: jsonEncode({'fileName': cleanFileName}),
        );
      });

      print('✅ Debug: Download response status = ${response.statusCode}');
      print('🔍 Debug: Download content-type = ${response.headers['content-type']}');
      print('🔍 Debug: Download content-length = ${response.headers['content-length']}');

      final ct = response.headers['content-type']?.toLowerCase();

      if (_isSuccessStatus(response.statusCode)) {
        // Check if response is JSON (might contain URL)
        if (_looksLikeJson(ct) && response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.body);
            final url = (data['url'] ?? data['downloadUrl'] ?? '').toString();
            if (url.isNotEmpty) {
              print('✅ Debug: Got download URL: $url');
              return DownloadResult(
                filename: fileName.split('/').last,
                url: url,
                contentType: ct,
              );
            }
          } catch (e) {
            print('⚠️ Debug: Could not parse JSON response: $e');
          }
        }

        // Otherwise, it's the actual file bytes
        final suggested = _filenameFromContentDisposition(response.headers['content-disposition'])
            ?? fileName.split('/').last
            ?? 'file.pdf';

        print('✅ Debug: Returning file bytes, size = ${response.bodyBytes.length}');

        return DownloadResult(
          filename: suggested,
          bytes: response.bodyBytes,
          contentType: ct,
        );
      } else {
        final errorMsg = response.body.isNotEmpty ? response.body : 'Download failed (${response.statusCode})';
        print('❌ Debug: Download error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Debug: Error downloading file: $e');
      rethrow;
    }
  }

  // ---------- Dropdown APIs ----------
  Future<List<Map<String, dynamic>>> getAllSeries() async {
    try {
      final uri = Uri.parse('$baseUrl/Dropdown/getall-series');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
        throw const FormatException('Expected a JSON array');
      } else {
        throw Exception('Failed to load series: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching series: $e');
      return [];
    }
  }

  // ---------- Session helpers ----------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kSeriesIds);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final uri = Uri.parse('$baseUrl/Auth/validate-token');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<http.Response> authenticatedRequest(
      Future<http.Response> Function() request,
      ) async {
    try {
      final response = await request();
      if (response.statusCode == 401) {
        await _handleUnauthorized();
      }
      return response;
    } catch (e) {
      if (e is http.ClientException || e.toString().contains('401')) {
        await _handleUnauthorized();
      }
      rethrow;
    }
  }

  Future<void> _handleUnauthorized() async {
    await logout();
    final context = navigatorKey.currentContext;
    if (context != null && navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<Map<String, String>?> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString(_kFullName);
    final email = prefs.getString(_kEmail);
    final mobileNumber = prefs.getString(_kMobileNumber);
    if (fullName != null && email != null && mobileNumber != null) {
      return {'name': fullName, 'email': email, 'mobileNumber': mobileNumber};
    }
    return null;
  }

  Future<bool> ensureAuthenticated(BuildContext context) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      _redirectToLogin(context);
      return false;
    }

    try {
      final uri = Uri.parse('$baseUrl/Auth/validate-token');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('❌ Token validation failed: $e');
    }

    // If we reach here: token invalid or expired
    await logout();
    _redirectToLogin(context);
    return false;
  }

  void _redirectToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}