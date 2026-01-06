import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static const String baseUrl =
      'https://jpapi.inspirertechnologies.com/api';

  /// Forgot Password (send OTP)
  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/forgot-password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
      },
      body: jsonEncode({'Email': email}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to send OTP');
    }
  }

  /// Verify OTP → RETURNS TOKEN
  static Future<String> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/verify-otp'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
      },
      body: jsonEncode({
        'Email': email,
        'OTP': otp,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OTP verification failed');
    }

    final data = jsonDecode(response.body);

    if (data['Status'] != 'Success' ||
        data['VerificationToken'] == null) {
      throw Exception(data['Message'] ?? 'Invalid OTP');
    }

    return data['VerificationToken'];
  }

  /// Reset Password WITH TOKEN
  static Future<void> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/reset-password-with-token'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
      },
      body: jsonEncode({
        'Email': email,
        'VerificationToken': token,
        'NewPassword': newPassword,
        'ConfirmNewPassword': confirmPassword,
      }),
    );

    final Map<String, dynamic> data =
    response.body.isNotEmpty ? jsonDecode(response.body) : {};

    // ❌ Error from backend
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        data['Message'] ?? 'Password reset failed',
      );
    }

    // ❌ Backend logical failure (Status = Error)
    if (data.isNotEmpty && data['Status'] == 'Error') {
      throw Exception(
        data['Message'] ?? 'Password reset failed',
      );
    }
  }

  /// Resend OTP
  static Future<void> resendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/resend-otp'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
      },
      body: jsonEncode({'Email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to resend OTP');
    }
  }
  /// Edit Profile API with Bearer Token
  static Future<Map<String, dynamic>> editProfile({
    required String fullName,
    required String email,
    required String cityName,
    required String regionName,
    required String schoolName,
    required String seriesIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('No token available. Please login again.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/Auth/edit-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'Authorization': 'Bearer $token', // <-- Add token here
      },
      body: jsonEncode({
        "FullName": fullName,
        "Email": email,
        "CityName": cityName,
        "RegionName": regionName,
        "SchoolName": schoolName,
        "SeriesIds": seriesIds,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['Message'] ?? 'Failed to update profile');
    }

    return data;
  }
}
