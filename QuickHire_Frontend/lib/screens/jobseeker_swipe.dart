import 'package:flutter/material.dart';
import '../models/job_listing.dart';
import '../services/jobseeker_dashboard_service.dart';

class JobSeekerSwipeScreen extends StatefulWidget {
  static const String id = 'JobSeekerSwipeScreen';
  const JobSeekerSwipeScreen({super.key});

  @override
  JobSeekerSwipeScreenState createState() => JobSeekerSwipeScreenState();
}

class JobSeekerSwipeScreenState extends State<JobSeekerSwipeScreen> {
  final JobSeekerDashboardService _service = JobSeekerDashboardService();
  List<JobListing> _openProjects = [];
  List<JobListing> _appliedProjects = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final openProjects = await _service.getOpenProjects();
      final appliedProjects = await _service.getAppliedProjects();
      final appliedIds = appliedProjects.map((e) => e.id).toSet();
      final swipeProjects = openProjects.where((p) => !appliedIds.contains(p.id)).toList();

      setState(() {
        _openProjects = swipeProjects;
        _appliedProjects = appliedProjects;
        _isLoading = false;
        _currentIndex = 0;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading jobs: $e')),
      );
    }
  }

  void _handleSwipe(DismissDirection direction) async {
    if (_currentIndex < _openProjects.length) {
      final currentJob = _openProjects[_currentIndex];

      if (direction == DismissDirection.startToEnd) {
        // Swipe right: Apply/Like
        try {
          await _service.applyToProject(currentJob.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Applied to job!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to apply: $e')),
          );
        }
      } else if (direction == DismissDirection.up) {
        // Swipe up: Save for later (implement as needed)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved for later!')),
        );
      }
      // Swipe left: Pass (do nothing)
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Jobs'),
        content: const Text('Filter options coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // All backgrounds white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: BackButton(color: Colors.black),
        title: const Text(
          'Jobs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.amber),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                children: [
                  // Section: Already Applied
                  if (_appliedProjects.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Already Applied',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._appliedProjects.map((job) => Card(
                                color: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.check_circle, color: Colors.green),
                                  title: Text(job.title),
                                  subtitle: Text(job.location),
                                  trailing: Text(job.status),
                                ),
                              )),
                        ],
                      ),
                    ),
                  // Section: Swipeable Jobs
                  if (_openProjects.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No more jobs to swipe!', style: TextStyle(fontSize: 18)),
                    )
                  else if (_currentIndex >= _openProjects.length)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 80, color: Colors.amber),
                          const SizedBox(height: 20),
                          const Text('No more jobs right now', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text('Check back later for new opportunities', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _loadProjects,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            ),
                            child: const Text('Refresh', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Dismissible(
                        key: ValueKey(_openProjects[_currentIndex].id),
                        direction: DismissDirection.horizontal,
                        onDismissed: _handleSwipe,
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.check_circle, color: Colors.white, size: 36),
                        ),
                        secondaryBackground: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.cancel, color: Colors.white, size: 36),
                        ),
                        child: _buildJobCard(_openProjects[_currentIndex]),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildJobCard(JobListing job) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company logo placeholder
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber.shade100,
                  child: const Icon(Icons.business, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.employer is Map && job.employer['name'] != null
                  ? job.employer['name']
                  : job.employer.toString(),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: const TextStyle(fontSize: 16),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text('${job.budget}', style: TextStyle(color: Colors.green[700])),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(job.location, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            // Visually appealing skills block
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: job.skills
                  .map((skill) => Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber[700], size: 16),
                            const SizedBox(width: 4),
                            Text(skill, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        backgroundColor: Colors.amber.withOpacity(0.18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.work, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(job.workType, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(job.duration, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Swipe right to apply, left to pass',
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}