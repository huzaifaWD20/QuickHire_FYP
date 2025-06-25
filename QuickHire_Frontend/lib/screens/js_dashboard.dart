// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../services/jobseeker_dashboard_service.dart';
import '../models/job_listing.dart';
import '../services/user_service.dart'; // Add this import
import '../services/service_chat.dart';

class JsDashboard extends StatefulWidget {
  static const String id = 'js_dashboard';
  const JsDashboard({super.key});

  @override
  State<JsDashboard> createState() => _JsDashboardState();
}

class _JsDashboardState extends State<JsDashboard> {
  final JobSeekerDashboardService _service = JobSeekerDashboardService();
  final UserService _userService = UserService(); // Add this line
  final ChatService chatService = ChatService();

  List<JobListing> matchedProjects = [];
  List<JobListing> acceptedProjects = [];
  bool isLoading = true;
  String userName = ""; // Add this line
  String error = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      final profile = await _userService.fetchProfile(); // Fetch profile
      print(profile); // Debugging line to check profile data
      final matches = await _service.getMatchedProjects();
      final accepted = await _service.getAcceptedProjects();
      setState(() {
        userName = profile?['user']?['name'] ?? "Jobseeker";
        matchedProjects = matches;
        acceptedProjects = accepted;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : error.isNotEmpty
              ? Center(child: Text(error))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile summary (replace with real user data if available)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.amber.shade100,
                            child: const Icon(Icons.person, size: 36, color: Colors.amber),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: matchedProjects.isNotEmpty
                                      ? matchedProjects.first.skills
                                          .map((skill) => Chip(
                                                label: Text(skill),
                                                avatar: const Icon(Icons.check_circle, color: Colors.amber, size: 18),
                                                backgroundColor: Colors.amber.withOpacity(0.13),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ))
                                          .toList()
                                      : [],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Application status overview
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statusColumn("Applied", acceptedProjects.length, Icons.send),
                              _statusColumn("Matched", matchedProjects.length, Icons.thumb_up),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Recent activity feed (show matched project titles as demo)
                      Text("Recent Activity", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...matchedProjects.take(3).map((project) => ListTile(
                            leading: const Icon(Icons.notifications, color: Colors.amber),
                            title: Text(project.title),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          )),
                      const SizedBox(height: 24),

                      // Quick stats (demo)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _quickStat("Matched", matchedProjects.length, Icons.visibility),
                          _quickStat("Applied", acceptedProjects.length, Icons.swipe),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Recommended actions (static for now)
                      Text("Recommended Actions", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                        label: const Text(
                          "Complete your profile",
                          style: TextStyle(color: Colors.white), // <-- Set text color to white
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _statusColumn(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 28),
        const SizedBox(height: 6),
        Text(
          "$count",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _quickStat(String label, int count, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber, size: 22),
            const SizedBox(height: 4),
            Text(
              "$count",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}