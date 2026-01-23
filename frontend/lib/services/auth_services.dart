import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ---------------------------------------------------------------------------
  // CHANGE THIS URL BASED ON YOUR ENVIRONMENT
  // ---------------------------------------------------------------------------
  
  // OPTION 1: Production (Render) - Use this if you have deployed your backend changes
  // static const String baseUrl = "https://relivo-app.onrender.com";

  // OPTION 2: Android Emulator - Use this if running on the emulator on the same PC
  // static const String baseUrl = "http://10.0.2.2:8000";

  // OPTION 3: Physical Device - Use your PC's IP address (Run 'ipconfig' in cmd to find it)
  static const String baseUrl = "https://relivo-app.onrender.com"; // Production Render URL
  // ---------------------------------------------------------------------------

  // REGISTER
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    print("Attempting to connect to $baseUrl/auth/register");
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "full_name": name,
        }),
      ).timeout(const Duration(seconds: 90));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("Request failed with status: ${response.statusCode}");
        print("Response body: ${response.body}");
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['detail'] ?? "Registration failed");
        } catch (e) {
          // If body is not JSON (e.g. html error page)
          throw Exception("Server Error (${response.statusCode}): ${response.body}");
        }
      }
    } catch (e) {
      print("Register Error: $e");
      throw Exception("Connection failed: $e. Check if your PC and phone are on the same WiFi and firewall is off.");
    }
  }

  // VERIFY CODE
  Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/verify"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "code": code,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await saveToken(data['access_token']);
      }
      return data;
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? "Verification failed");
      } catch (e) {
        throw Exception("Server Error (${response.statusCode}): ${response.body}");
      }
    }
  }

  // RESEND CODE
  Future<void> resendCode(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/resend-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? "Resend failed");
      } catch (e) {
        throw Exception("Server Error (${response.statusCode})");
      }
    }
  }

  // LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    print("Attempting to login to $baseUrl/auth/login");
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 90));

      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          await saveToken(data['access_token']);
        }
        return data;
      } else {
        print("Login Request failed with status: ${response.statusCode}");
        print("Response body: ${response.body}");
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['detail'] ?? "Login failed");
        } catch (e) {
          throw Exception("Server Error (${response.statusCode}): ${response.body}");
        }
      }
    } catch (e) {
      print("Login Error: $e");
      throw Exception("Connection failed: $e. Check firewall/network.");
    }
  }

  // TOKEN PERSISTENCE
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    if (token == null) throw Exception("No token found");

    final response = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user");
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
