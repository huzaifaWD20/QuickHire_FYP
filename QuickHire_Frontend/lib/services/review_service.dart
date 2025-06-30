import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';


class ReviewService {
  final String baseUrl = '${AppConfig.apiBaseUrl}/api/v1/reviews';

  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${prefs.getString('auth_token') ?? ''}',
    };
  }

  Future<bool> hasReviewed(String projectId, String userId) async {
    final headers = await _headers;
    final res = await http.get(Uri.parse('$baseUrl/project/$projectId'), headers: headers);
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'] as List;
      return data.any((r) =>
        r['reviewer'] is Map && r['reviewer']['_id'] == userId
      );
    }
    return false;
  }

  Future<void> submitReview({
    required String projectId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    final headers = await _headers;
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: json.encode({
        'project': projectId,
        'reviewee': revieweeId,
        'rating': rating,
        'comment': comment,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception(json.decode(res.body)['message'] ?? 'Failed to submit review');
    }
  }

  Future<List<dynamic>> getJobSeekerReviews(String userId) async {
    final headers = await _headers;
    final res = await http.get(Uri.parse('$baseUrl/user/$userId'), headers: headers);
    if (res.statusCode == 200) {
      return json.decode(res.body)['data'];
    }
    throw Exception('Failed to fetch jobseeker reviews');
  }
}