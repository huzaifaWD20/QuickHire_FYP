import 'package:flutter/material.dart';
import '../services/jobseeker_dashboard_service.dart';
import '../models/job_listing.dart';
import '../services/user_service.dart';
import '../services/review_service.dart';

class JsDashboard extends StatefulWidget {
  static const String id = 'js_dashboard';
  const JsDashboard({super.key});

  @override
  State<JsDashboard> createState() => _JsDashboardState();
}

class _JsDashboardState extends State<JsDashboard> {
  final JobSeekerDashboardService _service = JobSeekerDashboardService();
  final UserService _userService = UserService();
  final ReviewService _reviewService = ReviewService();

  List<JobListing> matchedProjects = [];
  List<JobListing> acceptedProjects = [];
  List<dynamic> reviews = [];
  Map<String, dynamic>? profile;
  bool isLoading = true;
  String userName = "";
  String error = '';
  bool showAllSkills = false;

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
      final fetchedProfile = await _userService.fetchProfile();
      final matches = await _service.getMatchedProjects();
      final accepted = await _service.getAcceptedProjects();
      final userId = fetchedProfile?['user']?['id'] ?? '';
      final fetchedReviews = userId.isNotEmpty
          ? await _reviewService.getJobSeekerReviews(userId)
          : [];
      setState(() {
        profile = fetchedProfile;
        userName = fetchedProfile?['user']?['name'] ?? "Jobseeker";
        matchedProjects = matches;
        acceptedProjects = accepted;
        reviews = fetchedReviews;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  int completedProjectsCount() =>
      acceptedProjects.where((job) => job.status == 'completed').length;

  double avgRating() {
    if (reviews.isEmpty) return 0.0;
    final total = reviews.fold<num>(0, (sum, r) => sum + (r['rating'] ?? 0));
    return total / reviews.length;
  }

  double profileCompleteness(Map<String, dynamic>? profile) {
    if (profile == null) return 0.0;
    int total = 4; // Only 4 fields now
    int filled = 0;
    final p = profile['profile'] ?? {};
    if ((p['bio'] ?? '').toString().isNotEmpty) filled++;
    if ((p['skills'] as List?)?.isNotEmpty ?? false) filled++;
    if ((p['phoneNumber'] ?? '').toString().isNotEmpty) filled++;
    if ((profile['user']?['location'] ?? '').toString().isNotEmpty) filled++;
    return filled / total;
  }

  List<Widget> buildBadges(int completedProjects, double avgRating) {
    List<Widget> badges = [];
    if (completedProjects >= 10) {
      badges
          .add(_badgeChip('Top Rated', Icons.emoji_events, Colors.green[700]!));
    }
    if (avgRating >= 4.5 && reviews.length >= 5) {
      badges.add(
          _badgeChip('Consistent Performer', Icons.star, Colors.amber[800]!));
    }
    return badges;
  }

  Widget _badgeChip(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      child: Chip(
        label: Text(text,
            style: const TextStyle(fontSize: 12, color: Colors.white)),
        avatar: Icon(icon, color: Colors.white, size: 16),
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget buildCompactRating(List<dynamic> reviews) {
    if (reviews.isEmpty) return const SizedBox();
    final avg = avgRating();
    return Row(
      children: [
        ...List.generate(
            5,
            (i) => Icon(
                  i < avg.round() ? Icons.star : Icons.star_border,
                  color: Colors.amber[700],
                  size: 16,
                )),
        const SizedBox(width: 4),
        Text(
          avg.toStringAsFixed(1),
          style: TextStyle(
              color: Colors.amber[800],
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
        Text(' (${reviews.length})',
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget buildSkillsChips(List<dynamic> skills) {
    // Responsive, multi-line, no overflow
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: skills
            .map((skill) => Chip(
                  label: Text(skill,
                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                  backgroundColor: Colors.amber[700],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ))
            .toList(),
      ),
    );
  }

  
  Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    Widget? child,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08), // subtle colored background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.22), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2), // <--- smaller margin
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6), // <--- smaller padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            if (child != null) ...[const SizedBox(height: 6), child],
          ],
        ),
      ),
    );
  }

  Widget buildReviewCard(dynamic review) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.amber.shade100, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                  5,
                  (i) => Icon(
                        i < (review['rating'] ?? 0)
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber[700],
                        size: 16,
                      )),
            ),
            const SizedBox(height: 4),
            Text(
              review['comment'] ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'By: ${review['reviewer']?['name'] ?? 'Anonymous'}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completeness = profileCompleteness(profile);
    final showCompleteProfile = completeness < 1.0;
    final completedProjects = completedProjectsCount();
    final avg = avgRating();
    final skills = (profile?['profile']?['skills'] as List<dynamic>? ?? []);

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
              : RefreshIndicator(
                  onRefresh: _fetchDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER: Profile summary (no fixed height!)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.amber.shade100,
                                child: const Icon(Icons.person, size: 36, color: Colors.amber),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        ...buildBadges(completedProjects, avg),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    buildCompactRating(reviews),
                                    const SizedBox(height: 8),
                                    if (skills.isNotEmpty)
                                      buildSkillsChips(skills),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // DASHBOARD STATS GRID (no overflow, responsive)
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1.4,
                          padding: EdgeInsets.zero,
                          children: [
                            buildStatCard(
                              title: 'Profile',
                              value: '${(completeness * 100).round()}%',
                              icon: Icons.account_circle,
                              color: Colors.amber[800]!,
                              child: LinearProgressIndicator(
                                value: completeness,
                                backgroundColor: Colors.amber[100],
                                color: Colors.amber[700],
                                minHeight: 6,
                              ),
                            ),
                            buildStatCard(
                              title: 'Completed',
                              value: '$completedProjects',
                              icon: Icons.check_circle,
                              color: Colors.green[700]!,
                            ),
                            buildStatCard(
                              title: 'Applied',
                              value: '${acceptedProjects.length}',
                              icon: Icons.send,
                              color: Colors.amber[700]!,
                            ),
                            buildStatCard(
                              title: 'Matched',
                              value: '${matchedProjects.length}',
                              icon: Icons.thumb_up,
                              color: Colors.amber[700]!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // RECENT ACTIVITY & APPLICATION STATUS
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade100, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Recent Activity',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.amber[800])),
                                    const SizedBox(height: 6),
                                    ...matchedProjects
                                        .take(2)
                                        .map((project) => Padding(
                                              padding: const EdgeInsets.only(bottom: 2.0),
                                              child: Text(
                                                project.title,
                                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 48,
                                color: Colors.amber[100],
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Application Status',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.amber[800])),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.send, color: Colors.amber[700], size: 16),
                                        const SizedBox(width: 4),
                                        Text('Applied: ${acceptedProjects.length}',
                                            style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.thumb_up, color: Colors.amber[700], size: 16),
                                        const SizedBox(width: 4),
                                        Text('Matched: ${matchedProjects.length}',
                                            style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // REVIEWS SECTION
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reviews',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.amber[800])),
                            TextButton(
                              onPressed: () {
                                // Navigate to all reviews screen
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.amber[800],
                              ),
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 140,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: reviews.take(2).map(buildReviewCard).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Complete your profile button (only if not complete)
                        if (showCompleteProfile)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_forward, color: Colors.white),
                              label: const Text(
                                "Complete your profile",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                // Navigate to profile completion screen
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
