// ignore_for_file: unnecessary_null_comparison, unused_field

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/service_joblisting_list.dart';
import 'view_js_profile_screen.dart';
import '../services/service_chat.dart';
import 'chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployerApplicationsOverviewScreen extends StatefulWidget {
  static const String id = 'employer_applications_overview_screen';
  const EmployerApplicationsOverviewScreen({super.key});

  @override
  State<EmployerApplicationsOverviewScreen> createState() =>
      _EmployerApplicationsOverviewScreenState();
}

class _EmployerApplicationsOverviewScreenState
    extends State<EmployerApplicationsOverviewScreen> {
  final ProjectService _projectService = ProjectService();
  final ChatService _chatService = ChatService();
  bool isLoading = true;
  List<dynamic> openProjects = [];
  List<dynamic> allProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => isLoading = true);
    try {
      final projects = await _projectService.fetchUserProjects();
      setState(() {
        allProjects = projects;
        openProjects = projects.where((p) => p.status == 'open').toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load projects: $e')),
      );
    }
  }

  bool isJobSeekerWorkingElsewhere(
      String jobSeekerId, String currentProjectId) {
    for (final project in allProjects) {
      if (project.id == currentProjectId) continue;
      if (project.status != 'in-progress') continue;
      final acceptedBy = project.acceptedBy ?? [];
      for (final applicant in acceptedBy) {
        // If jobSeeker is a populated object, use applicant.jobSeeker.id
        final js = applicant.jobSeeker;
        String jsId;
        if (js is Map) {
          jsId = js['_id'] ?? js['id'] ?? '';
        } else {
          jsId = js?.toString() ?? '';
        }
        if (jsId == jobSeekerId && applicant.status == 'accepted') {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _updateStatus(
      String projectId, String applicantId, String status) async {
    try {
      await _projectService.updateApplicantStatus(
          projectId, applicantId, status);
      if (status == 'accepted') {
        await _projectService.updateProjectStatus(projectId, 'in-progress');
      }
      _loadProjects();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Projects & Applications',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : openProjects.isEmpty
              ? const Center(
                  child: Text('No open projects.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: openProjects.length,
                  itemBuilder: (context, projectIdx) {
                    final project = openProjects[projectIdx];
                    final applicants = project.acceptedBy ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          color: Colors.amber.shade50,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text(project.title ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(project.description ?? '',
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: Text('Budget: ${project.budget}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                        if (applicants.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 12),
                            child: Text('No applicants yet.',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        ...applicants.map<Widget>((applicant) {
                          // Handle both populated and non-populated jobSeeker
                          final js = applicant.jobSeeker;
                            String jobSeekerId;
                            String jobSeekerName = '';
                            String jobSeekerEmail = '';

                            if (js is Map) {
                              jobSeekerId = js['_id'] ?? js['id'] ?? '';
                              jobSeekerName = js['name'] ?? '';
                              jobSeekerEmail = js['email'] ?? '';
                            } else {
                              jobSeekerId = js?.toString() ?? '';
                            }
                          final isWorkingElsewhere =
                              isJobSeekerWorkingElsewhere(
                                  jobSeekerId, project.id);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber.shade100,
                                child: const Icon(Icons.person,
                                    color: Colors.amber),
                              ),
                              title: Text(jobSeekerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(jobSeekerEmail,
                                      style: const TextStyle(fontSize: 13)),
                                  Text(
                                    'Applied: ${DateFormat('MMM d, yyyy').format(applicant.acceptedAt is String ? DateTime.parse(applicant.acceptedAt) : applicant.acceptedAt)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    'Status: ${applicant.status}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: applicant.status == 'accepted'
                                          ? Colors.green
                                          : applicant.status == 'rejected'
                                              ? Colors.red
                                              : Colors.amber,
                                    ),
                                  ),
                                  if (isWorkingElsewhere)
                                    const Text(
                                      'Already working on another project',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 12),
                                    ),
                                  if (applicant.status == 'accepted')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.message),
                                        label: const Text('Message'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber,
                                          minimumSize: const Size(120, 36),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () async {
                                          // Get current user's ID (employer)
                                          final prefs = await SharedPreferences.getInstance();
                                          final yourUserId = prefs.getString('user_id') ?? '';

                                          final canAccess = await _chatService.canAccessConversation(
                                            otherUserId: jobSeekerId,
                                            projectId: project.id,
                                          );
                                          if (canAccess) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  conversationId: '$jobSeekerId-${project.id}',
                                                  roomName: jobSeekerName,
                                                  otherUserId: jobSeekerId,
                                                  projectId: project.id,
                                                  yourUserId: yourUserId,
                                                ),
                                              ),
                                            );
                                          } else {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text('Chat Unavailable'),
                                                content: const Text('Accept the application first to start messaging'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        }
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert,
                                    color: Colors.amber),
                                onSelected: (value) {
                                  if (jobSeekerId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Jobseeker ID not found for this applicant.')),
                                    );
                                    return;
                                  }
                                  if (value == 'accept')
                                    _updateStatus(
                                        project.id, jobSeekerId, 'accepted');
                                  if (value == 'reject')
                                    _updateStatus(
                                        project.id, jobSeekerId, 'rejected');
                                  if (value == 'profile') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => JobSeekerProfileScreen(
                                            userId: jobSeekerId),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (applicant.status != 'accepted')
                                    const PopupMenuItem(
                                        value: 'accept', child: Text('Accept')),
                                  if (applicant.status != 'rejected')
                                    const PopupMenuItem(
                                        value: 'reject', child: Text('Reject')),
                                  const PopupMenuItem(
                                      value: 'profile',
                                      child: Text('View Profile')),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 18),
                      ],
                    );
                  },
                ),
    );
  }
}
