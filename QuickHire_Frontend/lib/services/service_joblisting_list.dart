import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_listing.dart';
import '../config/app_config.dart';

class ProjectService {
  final String baseUrl = AppConfig.projectsEndpoint;

  Future<Map<String, String>> get _headers async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await _getAuthToken()}',
    };
  }

  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  // Fetch all projects created by the user (employer)
  Future<List<JobListing>> fetchUserProjects() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/employer/list'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((json) => JobListing.fromJson(json))
              .toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching projects: $e');
      return [];
    }
  }

  // Create a new project
  Future<JobListing> createProject(JobListing project) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/'),
        headers: headers,
        body: json.encode(project.toJson()),
      );

      if (response.statusCode == 201) {
        final decoded = json.decode(response.body);
        return JobListing.fromJson(decoded['data']);
      } else {
        throw Exception('Failed to create project: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating project: $e');
    }
  }

  // Update an existing project
  Future<JobListing> updateProject(String projectId, JobListing project) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$baseUrl/$projectId'),
        headers: headers,
        body: json.encode(project.toJson()),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return JobListing.fromJson(decoded['data']);
      } else {
        throw Exception('Failed to update project: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating project: $e');
    }
  }

  // Delete/cancel a project
  Future<bool> deleteProject(String projectId) async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('$baseUrl/$projectId'),
        headers: headers,
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting project: $e');
    }
  }

  // Toggle favorite/shortlist status (custom implementation)
  Future<bool> shortlistProject(String projectId, bool shortlist) async {
    try {
      final headers = await _headers;
      // Since there's no specific shortlist endpoint, we'll use the update endpoint
      final response = await http.put(
        Uri.parse('$baseUrl/$projectId'),
        headers: headers,
        body: json.encode({
          'isShortlisted': shortlist,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error shortlisting project: $e');
    }
  }

  // For jobseekers to accept a project
  Future<bool> acceptProject(String projectId) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/$projectId/accept'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error accepting project: $e');
    }
  }

  // For jobseekers to get matched projects
  Future<List<JobListing>> getMatchedProjects() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/matches/find'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> projectsJson = json.decode(response.body);
        return projectsJson.map((json) => JobListing.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load matched projects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting matched projects: $e');
    }
  }

  Future<List<dynamic>> fetchApplicants(String projectId) async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/$projectId/applicants'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['data'] as List<dynamic>;
    } else {
      throw Exception('Failed to fetch applicants');
    }
  }

  // Update applicant status (accept/reject)
  Future<void> updateApplicantStatus(String projectId, String applicantId, String status) async {
    final headers = await _headers;
    final response = await http.put(
      Uri.parse('$baseUrl/$projectId/applicants/$applicantId'),
      headers: headers,
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update applicant status');
    }
  }

  // Update project status (in-progress, completed, cancelled)
  Future<void> updateProjectStatus(String projectId, String status) async {
    final headers = await _headers;
    final response = await http.put(
      Uri.parse('$baseUrl/$projectId'),
      headers: headers,
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update project status');
    }
  }

}
