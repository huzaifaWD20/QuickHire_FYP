import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class UserService {
  static const String profileUrl = '${AppConfig.authEndpoint}/me';
  static const String updateUserUrl = '${AppConfig.authEndpoint}/updatedetails';
  static const String updateEmployerProfileUrl = '${AppConfig.authEndpoint}/employer-profile';
  static const String updateJobSeekerProfileUrl = '${AppConfig.authEndpoint}/jobseeker-profile';

  Future<Map<String, dynamic>?> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      print('No token found in SharedPreferences');
      return null;
    }
    final response = await http.get(
      Uri.parse(profileUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    print('Profile fetch failed: ${response.body}');
    return null;
  }

  Future<bool> updateUserDetails({required String name, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;
    final response = await http.put(
      Uri.parse(updateUserUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'name': name, 'email': email}),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateEmployerProfile({
    required String companyName,
    required String linkedinUrl,
    required String phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;
    final response = await http.put(
      Uri.parse(updateEmployerProfileUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'companyName': companyName,
        'linkedinUrl': linkedinUrl,
        'phoneNumber': phoneNumber,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateJobSeekerProfile({
    required String bio,
    required List<String> skills,
    required String phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;
    final response = await http.put(
      Uri.parse(updateJobSeekerProfileUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'bio': bio,
        'skills': skills,
        'phoneNumber': phoneNumber,
      }),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> fetchJobSeekerProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;
    final response = await http.get(
      Uri.parse('${AppConfig.projectsEndpoint}/jobseeker-profile/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    else{
      print('Profile fetch failed: ${response.body}');
    }
    return null;
  }
}