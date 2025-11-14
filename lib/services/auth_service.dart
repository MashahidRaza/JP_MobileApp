import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Result object for downloads
class DownloadResult {
  final String filename;
  final String? url;           // if server returns a URL
  final List<int>? bytes;      // if server returns bytes
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
  static const String baseUrl = 'http://103.83.91.193:8320/api';

  // SharedPreferences keys
  static const String _kToken = 'auth_token';
  static const String _kFullName = 'fullName';
  static const String _kEmail = 'email';

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

  Future<bool> login(String emailOrUsername, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/Auth/login');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': emailOrUsername,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final isJson = _looksLikeJson(response.headers['content-type']);
      final data = isJson ? _decodeJsonSafe(response) : null;

      if (_isSuccessStatus(response.statusCode)) {
        final prefs = await SharedPreferences.getInstance();
        final token = data?['token'];
        final user = data?['user'];
        if (token is String) await prefs.setString(_kToken, token);
        if (user is Map) {
          final fullName = user['fullName'];
          final email = user['email'];
          if (fullName is String) await prefs.setString(_kFullName, fullName);
          if (email is String) await prefs.setString(_kEmail, email);
        }
        return true;
      } else {
        print('[LOGIN] ${response.statusCode} ${response.reasonPhrase}');
        print('[LOGIN] content-type=${response.headers['content-type']}');
        print('[LOGIN] body=${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during API call (login): $e');
      return false;
    }
  }

  /// REGISTER — includes cityName, schoolName, regionName
  Future<Map<String, dynamic>> register(
    String fullName,
    String userName,
    String email,
    String password,
    String cityName,
    String schoolName,
    String regionName,
  ) async {
    final uri = Uri.parse('$baseUrl/Auth/register');

    final payload = {
      'fullName': fullName,
      'username': userName,
      'email': email,
      'password': password,
      'cityName': cityName,
      'schoolName': schoolName,
      'regionName': regionName,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      final isJson = _looksLikeJson(response.headers['content-type']);
      final data = isJson ? _decodeJsonSafe(response) : null;

      print('[REGISTER] -> ${response.statusCode} ${response.reasonPhrase}');
      print('[REGISTER] content-type=${response.headers['content-type']}');
      print('[REGISTER] body=${response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body}');

      if (_isSuccessStatus(response.statusCode)) {
        final token = data?['token'];
        if (token is String) {
          await _saveToken(token);
        }
        final user = data?['user'];
        if (user is Map) {
          final prefs = await SharedPreferences.getInstance();
          final fullName = user['fullName'];
          final email = user['email'];
          if (fullName is String) await prefs.setString(_kFullName, fullName);
          if (email is String) await prefs.setString(_kEmail, email);
        }

        final msg = (data?['message'] as String?) ??
            (response.statusCode == 201 ? 'User created successfully.' : 'Registration successful.');
        final status = (data?['status'] as String?) ?? 'Success';

        return {'status': status, 'message': msg};
      } else {
        final msg = (data?['message'] as String?) ?? 'Registration failed with status ${response.statusCode}.';
        final status = (data?['status'] as String?) ?? 'Error';
        return {'status': status, 'message': msg};
      }
    } catch (e) {
      print('Error during API call (register): $e');
      return {'status': 'Error', 'message': 'Could not contact server. Please try again.'};
    }
  }

  Future<Map<String, dynamic>?> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/Auth/change-password');

      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 30));

      final isJson = _looksLikeJson(response.headers['content-type']);
      final data = isJson ? _decodeJsonSafe(response) : null;

      if (_isSuccessStatus(response.statusCode)) {
        final msg = (data?['message'] as String?) ?? 'Password changed successfully.';
        return {'status': 'Success', 'message': msg};
      } else {
        final msg = (data?['message'] as String?) ?? 'Password change failed (status ${response.statusCode}).';
        return {'status': 'Error', 'message': msg};
      }
    } catch (e) {
      print('Error during API call (changePassword): $e');
      return {'status': 'Error', 'message': 'Could not contact server. Please try again.'};
    }
  }

  // ---------- Files APIs ----------

  Future<List<Map<String, dynamic>>> getFiles() async {
    try {
      final token = await getToken();

      final uri = Uri.parse('$baseUrl/FileDownloads/files');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return <Map<String, dynamic>>[];
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
        throw const FormatException('Expected a JSON array for FileDownloads/files');
      } else {
        throw Exception('Failed to load files: ${response.statusCode} -> ${response.body}');
      }
    } catch (e) {
      print('Error fetching files: $e');
      rethrow;
    }
  }

  /// POST /api/filedownloads/download with { "fileName": "<name>" }
  /// - If server returns binary: fills [bytes] and inferred filename.
  /// - If server returns JSON with a URL: fills [url].
  Future<DownloadResult> downloadFile(String fileName) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/filedownloads/download'); // lowercase per your endpoint

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'application/octet-stream, application/json',
      },
      body: jsonEncode({
        'fileName': fileName,
        // Add extra telemetry if needed later (userID, sessionID, etc.)
      }),
    );

    final ct = res.headers['content-type']?.toLowerCase();

    if (_isSuccessStatus(res.statusCode)) {
      // JSON (e.g., { url: "..." })
      if (_looksLikeJson(ct)) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final url = (data['url'] ?? data['downloadUrl'] ?? '').toString();
        if (url.isNotEmpty) {
          return DownloadResult(filename: fileName, url: url, contentType: ct);
        }
        final msg = data['message']?.toString() ?? 'No download URL returned.';
        throw Exception(msg);
      }

      // Binary bytes
      final suggested = _filenameFromContentDisposition(res.headers['content-disposition']) ?? fileName;
      return DownloadResult(
        filename: suggested,
        bytes: res.bodyBytes,
        contentType: ct,
      );
    } else {
      try {
        final Map<String, dynamic> data = jsonDecode(res.body);
        throw Exception(data['message'] ?? 'Download failed (${res.statusCode}).');
      } catch (_) {
        throw Exception('Download failed (${res.statusCode}).');
      }
    }
  }

  // ---------- Session helpers ----------

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kFullName);
    await prefs.remove(_kEmail);
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
    return token != null;
  }

  Future<Map<String, String>?> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString(_kFullName);
    final email = prefs.getString(_kEmail);
    if (fullName != null && email != null) {
      return {'name': fullName, 'email': email};
    }
    return null;
  }
}
