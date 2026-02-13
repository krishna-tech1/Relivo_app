import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:refugee_app/models/grant.dart';
import 'package:refugee_app/services/auth_services.dart';

class GrantService {
  final AuthService _authService = AuthService();
  // Use the same base URL as AuthService
  static const String baseUrl = AuthService.baseUrl; 

  // Fetch all grants (public)
  Future<List<Grant>> getGrants() async {
    // Public endpoint for verified grants only
    final endpoint = '/grants/public';
    
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    } else {
      throw Exception('Failed to load grants: ${response.statusCode}');
    }
  }

  // Phase-2: Fetch grants submitted by the current user
  Future<List<Grant>> getMyGrants() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.get(
      Uri.parse('$baseUrl/grants/my-submissions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    } else {
      throw Exception('Failed to load my grants: ${response.statusCode}');
    }
  }

  // Phase-2: Submit a grant for verification (User)
  Future<Grant> submitUserGrant(Grant grant) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    // Users submit to a general endpoint, not admin
    final response = await http.post(
      Uri.parse('$baseUrl/grants/submit'), 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(_toJson(grant)), // is_verified will be ignored/false by backend
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    } else {
      String errorMessage = response.body;
      try {
        final errorJson = jsonDecode(response.body);
        if (errorJson is Map && errorJson.containsKey('detail')) {
          errorMessage = errorJson['detail'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  // Phase-2: Update user's own grant
  Future<Grant> updateMyGrant(Grant grant) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.put(
      Uri.parse('$baseUrl/grants/my-submissions/${grant.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(_toJson(grant)),
    );

    if (response.statusCode == 200) {
      return _fromJson(jsonDecode(response.body));
    } else {
      String errorMessage = response.body;
      try {
        final errorJson = jsonDecode(response.body);
        if (errorJson is Map && errorJson.containsKey('detail')) {
          errorMessage = errorJson['detail'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  // Phase-2: Delete user's own grant
  Future<void> deleteMyGrant(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.delete(
      Uri.parse('$baseUrl/grants/my-submissions/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete my grant: ${response.body}');
    }
  }

  // Helper methods to convert between Grant model and Backend JSON
  // Note: Backend JSON keys might differ slightly, adjusting here.
  Grant _fromJson(Map<String, dynamic> json) {
    try {
      // 1. CATEGORY PARSING & NORMALIZATION
      String category = (json['category'] ?? '').toString().trim();
      
      // If category is missing or "General", try to detect a better one from text
      if (category.isEmpty || category.toLowerCase() == 'general') {
        String detected = _detectCategory(
          json['title']?.toString(), 
          json['description']?.toString(), 
          (json['organizer'] ?? json['provider'])?.toString()
        );
        if (detected != 'General') {
          category = detected;
        } else {
          category = 'General';
        }
      }

      // Ensure it matches the Title case format of GrantData.categories
      if (category.isNotEmpty) {
        // Safe title casing
        category = category[0].toUpperCase() + (category.length > 1 ? category.substring(1).toLowerCase() : '');
      } else {
        category = 'General';
      }

      // 2. DATE PARSING (Defensive)
      DateTime deadline;
      try {
        if (json['deadline'] != null && json['deadline'].toString().isNotEmpty) {
          deadline = DateTime.parse(json['deadline'].toString());
        } else {
          deadline = DateTime.now().add(const Duration(days: 30));
        }
      } catch (e) {
        deadline = DateTime.now().add(const Duration(days: 30));
      }

      // 3. SAFE LIST CONVERSION
      List<String> parseList(dynamic val) {
        if (val == null) return [];
        if (val is List) return val.map((e) => e.toString()).toList();
        if (val is String && val.isNotEmpty) return [val];
        return [];
      }

      return Grant(
        id: (json['id'] ?? json['grant_id'] ?? '').toString(),
        title: (json['title'] ?? 'Untitled Grant').toString(),
        organizer: (json['organizer'] ?? json['provider'] ?? 'Unknown').toString(),
        country: (json['refugee_country'] ?? json['location'] ?? 'Global').toString(),
        category: category,
        deadline: deadline,
        amount: (json['amount'] ?? 'Check Details').toString(),
        description: (json['description'] ?? 'No description provided.').toString(),
        eligibilityCriteria: parseList(json['eligibility_criteria'] ?? json['eligibility']),
        requiredDocuments: parseList(json['required_documents']),
        isVerified: json['is_verified'] == true || json['is_verified'] == 1, 
        isUrgent: json['is_urgent'] == true || json['is_urgent'] == 1,
        applyUrl: (json['apply_url'] ?? '').toString(),
      );
    } catch (e) {
      // Fallback for extreme cases to prevent app crash
      return Grant(
        id: 'error',
        title: 'Error loading grant',
        organizer: 'System',
        country: 'N/A',
        category: 'General',
        deadline: DateTime.now(),
        amount: 'N/A',
        description: 'This grant data could not be parsed: $e',
        eligibilityCriteria: [],
        requiredDocuments: [],
      );
    }
  }

  // Helper method to detect category from grant data
  String _detectCategory(String? title, String? description, String? organizer) {
    final text = '${title ?? ''} ${description ?? ''} ${organizer ?? ''}'.toLowerCase();
    
    // Emergency / Urgent Support
    if (text.contains('emergency') || text.contains('urgent') || text.contains('immediate') || 
        text.contains('crisis') || text.contains('relief') || text.contains('basic needs') ||
        text.contains('food') || text.contains('water') || text.contains('shelter')) {
      return 'Emergency';
    }
    
    // Housing / Shelter
    if (text.contains('housing') || text.contains('rent') || text.contains('accommodation') || 
        text.contains('apartment') || text.contains('shelter') || text.contains('settlement') ||
        text.contains('rehousing') || text.contains('construction')) {
      return 'Housing';
    }
    
    // Education / Training
    if (text.contains('education') || text.contains('school') || text.contains('university') || 
        text.contains('scholarship') || text.contains('training') || text.contains('learning') ||
        text.contains('course') || text.contains('student') || text.contains('academic')) {
      return 'Education';
    }
    
    // Healthcare / Medical
    if (text.contains('health') || text.contains('medical') || text.contains('hospital') || 
        text.contains('doctor') || text.contains('treatment') || text.contains('medicine') ||
        text.contains('wellness') || text.contains('mental') || text.contains('psychological')) {
      return 'Healthcare';
    }
    
    // Employment / Business
    if (text.contains('job') || text.contains('employment') || text.contains('career') || 
        text.contains('business') || text.contains('startup') || text.contains('entrepreneur') ||
        text.contains('work') || text.contains('salary') || text.contains('skills')) {
      return 'Employment';
    }
    
    // Legal / Rights
    if (text.contains('legal') || text.contains('rights') || text.contains('lawyer') || 
        text.contains('protection') || text.contains('asylum') || text.contains('visa') ||
        text.contains('documentation') || text.contains('advocacy') || text.contains('justice')) {
      return 'Legal';
    }
    
    return 'General';
  }

  Map<String, dynamic> _toJson(Grant grant) {
    return {
      'title': grant.title,
      'organizer': grant.organizer,
      'description': grant.description,
      'eligibility': grant.eligibilityCriteria.isNotEmpty 
          ? grant.eligibilityCriteria.join('; ') 
          : null,  // Convert list to text
      'amount': grant.amount,
      'deadline': grant.deadline.toIso8601String(),
      'refugee_country': grant.country,
      'apply_url': grant.applyUrl.isNotEmpty ? grant.applyUrl : 'https://example.com/apply',
      'eligibility_criteria': grant.eligibilityCriteria,
      'required_documents': grant.requiredDocuments,
      'is_verified': grant.isVerified,
      'is_active': true,
      'category': grant.category,
      'source': 'manual',
    };
  }
}
