// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/job_listing.dart';
import '../services/service_joblisting_list.dart';
import '../services/user_service.dart';
import 'create_jobListing_screen.dart';
import 'joblisting_screen.dart';
import 'applications_screen.dart';
import '../services/service_chat.dart';
import 'chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/review_service.dart';
import '../widgets/review_dialog.dart';



class EmpDashboard extends StatefulWidget {
  static const String id = 'emp_dashboard';
  const EmpDashboard({super.key});

  @override
  State<EmpDashboard> createState() => _EmpDashboardState();
}

class _EmpDashboardState extends State<EmpDashboard> {
  final ProjectService _projectService = ProjectService();
  final UserService _userService = UserService();
  final ChatService chatService = ChatService();

  String employerName = '';
  int totalJobs = 0;
  int activeJobs = 0;
  int hiredCount = 0;
  int totalApplications = 0;
  int applicationsThisWeek = 0;
  double responseRate = 0.0;

  List<JobListing> jobs = [];
  List<_RecentApplication> recentApplications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<String> getCurrentUserId() async {
    final userService = UserService();
    final profile = await userService.fetchProfile();
    if (profile == null) return '';
    // The user id is inside profile['user']['id']
    return profile['user']?['id'] ?? '';
  }

  Future<bool> _showReviewButton(JobListing job) async {
    final userId = await getCurrentUserId();
    return await ReviewService().hasReviewed(job.id, userId);
  }

  Future<void> _loadDashboard() async {
    setState(() => isLoading = true);
    try {
      // Fetch employer profile
      final profile = await _userService.fetchProfile();
      employerName = profile?['user']?['name'] ?? 'Employer';

      // Fetch all jobs posted by employer
      jobs = await _projectService.fetchUserProjects();
      totalJobs = jobs.length;
      activeJobs = jobs.where((j) => j.status == 'open' || j.status == 'in-progress').length;
      hiredCount = jobs.fold(0, (sum, job) =>
        sum + job.acceptedBy.where((a) => a.status == 'accepted').length);

      // Gather all applications
      List<_RecentApplication> allApplications = [];
      for (var job in jobs) {
        for (var applicant in job.acceptedBy) {
          allApplications.add(_RecentApplication(
            applicant: applicant,
            job: job,
          ));
        }
      }
      // Sort by application date (descending)
      allApplications.sort((a, b) => b.applicant.acceptedAt.compareTo(a.applicant.acceptedAt));
      recentApplications = allApplications.take(5).toList();

      totalApplications = allApplications.length;
      // Applications this week
      final now = DateTime.now();
      applicationsThisWeek = allApplications
          .where((a) => a.applicant.acceptedAt.isAfter(now.subtract(const Duration(days: 7))))
          .length;

      // Response rate: % of applications with status not 'pending'
      final responded = allApplications.where((a) => a.applicant.status != 'pending').length;
      responseRate = allApplications.isEmpty ? 0 : (responded / allApplications.length) * 100;

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard: $e')),
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
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.amber.shade100,
                          child: const Icon(Icons.business, color: Colors.amber, size: 32),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, $employerName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _statChip('Jobs', totalJobs, Icons.work),
                                  _statChip('Active', activeJobs, Icons.play_arrow),
                                  _statChip('Hired', hiredCount, Icons.verified, color: Colors.green),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Analytics Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _analyticsCard('Applications\nThis Week', applicationsThisWeek, Icons.assignment_turned_in),
                        _analyticsCard('Response\nRate', '${responseRate.toStringAsFixed(0)}%', Icons.speed),
                        _analyticsCard('Active\nJobs', activeJobs, Icons.work_outline),
                        _analyticsCard('Hires', hiredCount, Icons.emoji_events),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Recent Applications Section
                    Text('Recent Applications', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    if (recentApplications.isEmpty)
                      const Text('No recent applications.', style: TextStyle(color: Colors.grey)),
                    ...recentApplications.map((app) => _applicationTile(app, context)).toList(),
                    const SizedBox(height: 28),

                    // Quick Actions Section
                    Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Post New Job', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CreateJobListingScreen()),
                              ).then((_) => _loadDashboard());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.list_alt, color: Colors.white),
                            label: const Text('View All Applications', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (jobs.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EmployerApplicationsOverviewScreen(),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.manage_search, color: Colors.white),
                        label: const Text('Manage Active Jobs', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const JobListingScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statChip(String label, int count, IconData icon, {Color color = Colors.amber}) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text('$count $label', style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      backgroundColor: color.withOpacity(0.13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _analyticsCard(String label, dynamic value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber, size: 28),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _applicationTile(_RecentApplication app, BuildContext context) {
    final applicant = app.applicant;
    final job = app.job;
    String name = '';
    String email = '';
    String profilePic = '';
    List<String> skills = [];
    if (applicant.jobSeeker is Map) {
      name = applicant.jobSeeker['name'] ?? '';
      email = applicant.jobSeeker['email'] ?? '';
      // profilePic = applicant.jobSeeker['profilePic'] ?? '';
    } else {
      name = applicant.jobSeeker.toString();
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: ListTile(
          isThreeLine: true,
          contentPadding: EdgeInsets.zero,
          onTap: () {
            // TODO: Navigate to application details screen
          },
          leading: CircleAvatar(
            backgroundColor: Colors.amber.shade100,
            child: profilePic.isNotEmpty
                ? ClipOval(child: Image.network(profilePic, width: 36, height: 36, fit: BoxFit.cover))
                : const Icon(Icons.person, color: Colors.amber),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      job.title,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM d, yyyy').format(applicant.acceptedAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              // Skills preview (if available)
              if (skills.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: skills
                        .take(3)
                        .map((s) => Chip(
                              label: Text(s, style: const TextStyle(fontSize: 11)),
                              backgroundColor: Colors.amber.withOpacity(0.18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              if (applicant.status == 'accepted')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.message, size: 18 , color: Colors.white),
                    label: const Text('Message', style: TextStyle(fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      minimumSize: const Size(90, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      // final yourUserId = prefs.getString('user_id') ?? '';

                      final jobSeekerId = applicant.jobSeeker is Map
                          ? applicant.jobSeeker['_id'] ?? applicant.jobSeeker['id']
                          : applicant.jobSeeker.toString();
                      final projectId = job.id;
                      final roomName = name;

                      final canAccess = await chatService.canAccessConversation(
                        otherUserId: jobSeekerId,
                        projectId: projectId,
                      );
                      if (canAccess) {
                        Navigator.pushNamed(
                          context,
                          ChatScreen.id,
                          arguments: {
                            'conversationId': '$jobSeekerId-$projectId',
                            'roomName': roomName,
                            'otherUserId': jobSeekerId,
                            'projectId': projectId,
                          },
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Chat Unavailable'),
                            content: const Text('Chat will be available once your application is accepted'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // --- Review Button Section ---
                if (job.status == 'completed')
                  FutureBuilder(
                    future: _showReviewButton(job),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      if (snapshot.data == true) {
                        return const Text('You have already Reviewed the project.',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500));
                      }
                      return ElevatedButton.icon(
                        icon: const Icon(Icons.rate_review, color: Colors.white),
                        label: const Text('Give Review', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          minimumSize: const Size(120, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final result = await showDialog(
                            context: context,
                            builder: (ctx) => ReviewDialog(
                              onSubmit: (rating, comment) async {
                                final userId = await getCurrentUserId();
                                print('Submitting review for user: $userId');
                                final revieweeId = job.acceptedBy.isNotEmpty
                                    ? (job.acceptedBy.first.jobSeeker is Map
                                        ? job.acceptedBy.first.jobSeeker['_id']
                                        : job.acceptedBy.first.jobSeeker.toString())
                                    : '';
                                await ReviewService().submitReview(
                                  projectId: job.id,
                                  revieweeId: revieweeId,
                                  rating: rating,
                                  comment: comment,
                                );
                                Navigator.pop(ctx, true);
                              },
                            ),
                          );
                          if (result == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Review submitted for admin approval!')),
                            );
                            setState(() {});
                          }
                        },
                      );
                    },
                  ),
            ],
          ),
          trailing: _statusTag(applicant.status),
        ),
      ),
    );
  }

  Widget _statusTag(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = Colors.amber;
        label = 'Pending';
        break;
      case 'accepted':
        color = Colors.green;
        label = 'Accepted';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// Helper class for recent applications
class _RecentApplication {
  final AcceptedBy applicant;
  final JobListing job;
  _RecentApplication({required this.applicant, required this.job});
}