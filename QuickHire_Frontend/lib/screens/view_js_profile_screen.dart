import 'package:flutter/material.dart';
import '../services/user_service.dart';

class JobSeekerProfileScreen extends StatefulWidget {
  static const String id = 'jobseeker_profile_screen';
  final String userId;
  const JobSeekerProfileScreen({super.key, required this.userId});

  @override
  State<JobSeekerProfileScreen> createState() => _JobSeekerProfileScreenState();
}

class _JobSeekerProfileScreenState extends State<JobSeekerProfileScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      profile = await _userService.fetchJobSeekerProfile(widget.userId);
      print('Profile data: $profile');
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Jobseeker Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : profile == null
              ? const Center(
                  child: Text('Profile not found.',
                      style: TextStyle(color: Colors.grey)))
              : Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.amber.shade100,
                            child: const Icon(Icons.person,
                                color: Colors.amber, size: 32),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?['name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                Text(
                                  profile?['email'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Bio',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(profile?['bio'] ?? '-',
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 18),
                      Text('Skills',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: (profile?['skills'] as List<dynamic>? ?? [])
                            .map((s) => Chip(
                                  label: Text(s,
                                      style: const TextStyle(fontSize: 13)),
                                  backgroundColor:
                                      Colors.amber.withOpacity(0.18),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      Text('Phone',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(profile?['phoneNumber'] ?? '-',
                          style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
    );
  }
}
