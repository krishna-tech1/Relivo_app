import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:refugee_app/models/grant.dart';
import 'package:refugee_app/services/auth_services.dart';

class GrantService {
  final AuthService _authService = AuthService();
  // Use the same base URL as AuthService
  static const String baseUrl = AuthService.baseUrl; 

  // Fetch all grants
  Future<List<Grant>> getGrants() async {
    final token = await _authService.getToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl/grants/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    } else {
      throw Exception('Failed to load grants: ${response.statusCode}');
    }
  }

  // Create a grant
  Future<Grant> createGrant(Grant grant) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.post(
      Uri.parse('$baseUrl/grants/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(_toJson(grant)),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create grant: ${response.body}');
    }
  }

  // Update a grant
  Future<Grant> updateGrant(Grant grant) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.put(
      Uri.parse('$baseUrl/grants/${grant.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(_toJson(grant)),
    );

    if (response.statusCode == 200) {
      return _fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update grant: ${response.body}');
    }
  }

  // Delete a grant
  Future<void> deleteGrant(String id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Authentication required');

    final response = await http.delete(
      Uri.parse('$baseUrl/grants/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete grant: ${response.body}');
    }
  }

  // Helper methods to convert between Grant model and Backend JSON
  // Note: Backend JSON keys might differ slightly, adjusting here.
  Grant _fromJson(Map<String, dynamic> json) {
    return Grant(
      id: json['id'].toString(),
      title: json['title'],
      organizer: json['provider'],
      country: json['location'] ?? 'Unknown',
      category: 'General', 
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : DateTime.now().add(const Duration(days: 30)),
      amount: json['amount'] ?? '',
      description: json['description'] ?? '',
      eligibilityCriteria: json['eligibility_criteria'] != null 
          ? List<String>.from(json['eligibility_criteria']) 
          : [],
      requiredDocuments: json['required_documents'] != null 
          ? List<String>.from(json['required_documents']) 
          : [],
      isVerified: true, 
      isUrgent: false,
      applyUrl: json['apply_url'] ?? '',
    );
  }

  Map<String, dynamic> _toJson(Grant grant) {
    return {
      'title': grant.title,
      'provider': grant.organizer,
      'description': grant.description,
      'amount': grant.amount,
      'deadline': grant.deadline.toIso8601String(),
      'location': grant.country,
      'apply_url': grant.applyUrl,
      'eligibility_criteria': grant.eligibilityCriteria,
      'required_documents': grant.requiredDocuments,
    };
  }
}
