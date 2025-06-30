import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  static const String id = 'profile_screen';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  Map<String, dynamic>? profile;
  bool isLoading = true;
  String _profileImageUrl = ''; // Placeholder for future image support

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    // Optionally: await prefs.clear(); // to clear all keys
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Login.id, (route) => false);
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    final data = await UserService().fetchProfile();
    setState(() {
      user = data?['user'];
      profile = data?['profile'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Failed to load profile')),
      );
    }

    final isEmployer = user!['role'] == 'employer';
    final isJobseeker = user!['role'] == 'jobseeker';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Profile photo with edit option
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _profileImageUrl.isNotEmpty
                        ? NetworkImage(_profileImageUrl) as ImageProvider
                        : const AssetImage('assets/quickhirelogo.png'),
                    child: _profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.amber)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: () {
                          _showPhotoUploadOptions(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              user!['name'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              user!['email'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user!['role'].toString().toUpperCase(),
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (user!['location'] != null && user!['location'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(user!['location'], style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employer fields
                  if (isEmployer && profile != null) ...[
                    _profileField(Icons.business, 'Company Name', profile!['companyName']),
                    _profileField(Icons.link, 'LinkedIn URL', profile!['linkedinUrl']),
                    _profileField(Icons.phone, 'Phone Number', profile!['phoneNumber']),
                  ],
                  // Jobseeker fields
                  if (isJobseeker && profile != null) ...[
                    _profileField(Icons.info_outline, 'Bio', profile!['bio']),
                    _skillsField(profile!['skills']),
                    _profileField(Icons.phone, 'Phone Number', profile!['phoneNumber']),
                  ],
                  const SizedBox(height: 18),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Edit Profile', style: TextStyle(fontSize: 16)),
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            EditProfileScreen.id,
                            arguments: {'user': user, 'profile': profile},
                          );
                          _loadProfile();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Logout', style: TextStyle(fontSize: 16)),
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileField(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Beautiful skills chips with icons
  Widget _skillsField(dynamic skills) {
    if (skills == null || (skills is List && skills.isEmpty)) return const SizedBox.shrink();
    final List<String> skillList = skills is List
        ? skills.cast<String>()
        : skills.toString().split(',').map((s) => s.trim()).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skillList.map((skill) {
                return Chip(
                  avatar: const Icon(Icons.check_circle, color: Colors.amber, size: 18),
                  label: Text(skill, style: const TextStyle(fontWeight: FontWeight.w500)),
                  backgroundColor: Colors.amber.withOpacity(0.13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Photo upload options (UI only, no backend logic) ---
  void _showPhotoUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement camera functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement gallery functionality
                },
              ),
              if (_profileImageUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement remove photo functionality
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}