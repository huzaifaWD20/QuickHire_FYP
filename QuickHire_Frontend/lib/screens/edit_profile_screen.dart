import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class EditProfileScreen extends StatefulWidget {
  static const String id = 'edit_profile_screen';
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String _role = '';
  // Employer fields
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _linkedinUrlController = TextEditingController();
  final TextEditingController _empPhoneController = TextEditingController();
  // Jobseeker fields
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _jsPhoneController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    Map<String, dynamic>? user;
    Map<String, dynamic>? profile;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      user = args['user'];
      profile = args['profile'];
    } else {
      final data = await UserService().fetchProfile();
      user = data?['user'];
      profile = data?['profile'];
    }

    if (user != null) {
      _role = user['role'] ?? '';
      if (_role == 'employer' && profile != null) {
        _companyNameController.text = profile['companyName'] ?? '';
        _linkedinUrlController.text = profile['linkedinUrl'] ?? '';
        _empPhoneController.text = profile['phoneNumber'] ?? '';
      } else if (_role == 'jobseeker' && profile != null) {
        _bioController.text = profile['bio'] ?? '';
        _skillsController.text = (profile['skills'] as List?)?.join(', ') ?? '';
        _jsPhoneController.text = profile['phoneNumber'] ?? '';
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool userUpdated = true;
    bool profileUpdated = true;

    // Update user details if needed (name/email)
    // await UserService().updateUserDetails(name: ..., email: ...);

    if (_role == 'employer') {
      profileUpdated = await UserService().updateEmployerProfile(
        companyName: _companyNameController.text.trim(),
        linkedinUrl: _linkedinUrlController.text.trim(),
        phoneNumber: _empPhoneController.text.trim(),
      );
    } else if (_role == 'jobseeker') {
      profileUpdated = await UserService().updateJobSeekerProfile(
        bio: _bioController.text.trim(),
        skills: _skillsController.text.split(',').map((s) => s.trim()).toList(),
        phoneNumber: _jsPhoneController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (userUpdated && profileUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmployer = _role == 'employer';
    final isJobseeker = _role == 'jobseeker';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.amber.shade100,
                        child: const Icon(Icons.person, size: 48, color: Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isEmployer) ...[
                      const Text(
                        'Company Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your company name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'LinkedIn URL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _linkedinUrlController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your LinkedIn profile URL',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Phone Number',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      IntlPhoneField(
                        initialValue: _empPhoneController.text,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        initialCountryCode: 'PK',
                        onChanged: (phone) {
                          _empPhoneController.text = phone.completeNumber;
                        },
                        validator: (phone) {
                          if (phone == null || phone.completeNumber.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (isJobseeker) ...[
                      const Text(
                        'Bio',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          hintText: 'Enter a short bio',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Skills',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _skillsController,
                        decoration: const InputDecoration(
                          hintText: 'Enter skills (comma separated)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Phone Number',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      IntlPhoneField(
                        initialValue: _jsPhoneController.text,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        initialCountryCode: 'PK', // or your default
                        onChanged: (phone) {
                          _jsPhoneController.text = phone.completeNumber;
                        },
                        validator: (phone) {
                          if (phone == null || phone.completeNumber.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('Save Profile', style: TextStyle(fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveProfile,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _linkedinUrlController.dispose();
    _empPhoneController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _jsPhoneController.dispose();
    super.dispose();
  }
}