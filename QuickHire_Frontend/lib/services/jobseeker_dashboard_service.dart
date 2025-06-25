import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_listing.dart';
import '../config/app_config.dart';

class JobSeekerDashboardService {
  final String baseUrl = "${AppConfig.apiBaseUrl}/api/v1";

  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get matched projects for jobseeker
  Future<List<JobListing>> getMatchedProjects() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/projects/matches/find'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['success'] == true && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((json) => JobListing.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to fetch matched projects');
  }

  // Get accepted projects (applied/interviews/offers)
  Future<List<JobListing>> getAcceptedProjects() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/projects/jobseeker/accepted'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['success'] == true && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((json) => JobListing.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to fetch accepted projects');
  }

  // Get all open projects (for swiping)
  Future<List<JobListing>> getOpenProjects() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/projects'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['success'] == true && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((json) => JobListing.fromJson(json))
            .where((job) => job.status == 'open')
            .toList();
      }
    }
    throw Exception('Failed to fetch open projects');
  }

  Future<List<JobListing>> getAppliedProjects() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/projects/jobseeker/accepted'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['success'] == true && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((json) => JobListing.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to fetch applied projects');
  }

  // Apply to a project (swipe right)
  Future<void> applyToProject(String projectId) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/projects/$projectId/accept'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to apply to project');
    }
  }
}