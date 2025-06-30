// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/service_joblisting_list.dart';
import '../models/job_listing.dart';
import 'create_jobListing_screen.dart';
import '../services/review_service.dart';
import '../widgets/review_dialog.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

class JobListingScreen extends StatefulWidget {
  static const String id = 'job_listing';
  const JobListingScreen({super.key});

  @override
  _JobListingScreenState createState() => _JobListingScreenState();
}

class _JobListingScreenState extends State<JobListingScreen> {
  final ProjectService _projectService = ProjectService();
  List<JobListing> _openJobs = [];
  List<JobListing> _progressJobs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    final jobs = await _projectService.fetchUserProjects();
    setState(() {
      _openJobs = jobs.where((j) => j.status == 'open' || j.status == 'active').toList();
      _progressJobs = jobs.where((j) =>
          j.status == 'in-progress' ||
          j.status == 'completed' ||
          j.status == 'paused').toList();
      _isLoading = false;
    });
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

  void _onSearch(String query) {
    setState(() => _searchQuery = query.trim().toLowerCase());
  }

  void _onFilter(String? status) {
    setState(() => _filterStatus = status ?? 'all');
  }

  List<JobListing> _applyFilters(List<JobListing> jobs) {
    var filtered = jobs;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((j) =>
        j.title.toLowerCase().contains(_searchQuery) ||
        j.description.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    if (_filterStatus != 'all') {
      filtered = filtered.where((j) => j.status == _filterStatus).toList();
    }
    return filtered;
  }

  void _editJob(JobListing job) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateJobListingScreen(existingProject: job),
      ),
    );
    if (updated == true) _loadJobs();
  }

  Future<void> _deleteJob(String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _projectService.deleteProject(jobId);
      _loadJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final openJobs = _applyFilters(_openJobs);
    final progressJobs = _applyFilters(_progressJobs);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Manage Jobs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amber),
            onPressed: _loadJobs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Job', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateJobListingScreen()),
          ).then((_) => _loadJobs());
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : OrientationBuilder(
              builder: (context, orientation) {
                return isLandscape
                    ? Row(
                        children: [
                          Expanded(child: _sectionWidget(
                            title: 'Open Jobs',
                            jobs: openJobs,
                            emptyMsg: 'No open jobs. Tap + to post a new job!',
                            cardBuilder: (job) => _openJobCard(job),
                          )),
                          const VerticalDivider(width: 1, color: Colors.grey),
                          Expanded(child: _sectionWidget(
                            title: 'Jobs in Progress',
                            jobs: progressJobs,
                            emptyMsg: 'No jobs in progress.',
                            cardBuilder: (job) => _progressJobCard(job),
                          )),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: _sectionWidget(
                            title: 'Open Jobs',
                            jobs: openJobs,
                            emptyMsg: 'No open jobs. Tap + to post a new job!',
                            cardBuilder: (job) => _openJobCard(job),
                          )),
                          const Divider(height: 1, color: Colors.grey),
                          Expanded(child: _sectionWidget(
                            title: 'Jobs in Progress',
                            jobs: progressJobs,
                            emptyMsg: 'No jobs in progress.',
                            cardBuilder: (job) => _progressJobCard(job),
                          )),
                        ],
                      );
              },
            ),
    );
  }

  Widget _sectionWidget({
    required String title,
    required List<JobListing> jobs,
    required String emptyMsg,
    required Widget Function(JobListing) cardBuilder,
  }) {
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with search/filter
            Row(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.amber),
                  onPressed: () async {
                    final query = await showSearch<String>(
                      context: context,
                      delegate: _JobSearchDelegate(),
                    );
                    if (query != null) _onSearch(query);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_alt, color: Colors.amber),
                  onSelected: _onFilter,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('All')),
                    const PopupMenuItem(value: 'open', child: Text('Open')),
                    const PopupMenuItem(value: 'active', child: Text('Active')),
                    const PopupMenuItem(value: 'in-progress', child: Text('In Progress')),
                    const PopupMenuItem(value: 'completed', child: Text('Completed')),
                    const PopupMenuItem(value: 'paused', child: Text('Paused')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: jobs.isEmpty
                  ? Center(
                      child: Text(
                        emptyMsg,
                        style: const TextStyle(color: Colors.grey, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: ListView.builder(
                        key: ValueKey(jobs.length),
                        itemCount: jobs.length,
                        itemBuilder: (context, idx) => cardBuilder(jobs[idx]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _openJobCard(JobListing job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editJob(job);
                    if (value == 'delete') _deleteJob(job.id);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Posted: ${DateFormat('MMM d, yyyy').format(job.createdAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text('${job.acceptedBy.length} Applications', style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.visibility, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text('${job.views} Views', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressJobCard(JobListing job) {
    final assigned = job.acceptedBy.where((a) => a.status == 'accepted' || a.status == 'completed').toList();
    final candidateName = assigned.isNotEmpty && assigned.first.jobSeeker is Map
        ? assigned.first.jobSeeker['name'] ?? 'N/A'
        : 'N/A';
        
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.amber.withOpacity(0.07),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // Implement actions as needed
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'contact', child: Text('Contact Candidate')),
                    // const PopupMenuItem(value: 'complete', child: Text('Mark as Completed')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text(candidateName, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text(
                  'Start: ${DateFormat('MMM d, yyyy').format(job.createdAt)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text(
                  job.status.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LinearProgressIndicator(
                    value: job.status == 'completed'
                        ? 1
                        : job.status == 'in-progress'
                            ? 0.6
                            : 0.3,
                    backgroundColor: Colors.grey[300],
                    color: Colors.amber,
                    minHeight: 6,
                  ),
                ),
              ],
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
      ),
    );
  }
}

// Custom search delegate for jobs
class _JobSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search jobs...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.amber),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) => Container();
}