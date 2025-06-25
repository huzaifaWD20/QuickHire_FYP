import 'package:flutter/material.dart';
import '../models/job_listing.dart';
import '../services/service_joblisting_list.dart';

class CreateJobListingScreen extends StatefulWidget {
  static const String id = 'create_job_listing'; // <-- Add this line

  final JobListing? existingProject;
  const CreateJobListingScreen({Key? key, this.existingProject}) : super(key: key);

  @override
  State<CreateJobListingScreen> createState() => _CreateJobListingScreenState();
}

class _CreateJobListingScreenState extends State<CreateJobListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProjectService _projectService = ProjectService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _skillsController;
  late TextEditingController _locationController;
  late TextEditingController _workTypeController;
  late TextEditingController _budgetController;
  late TextEditingController _durationController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProject;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _skillsController = TextEditingController(text: p != null ? p.skills.join(', ') : '');
    _locationController = TextEditingController(text: p?.location ?? '');
    _workTypeController = TextEditingController(text: p?.workType ?? 'remote');
    _budgetController = TextEditingController(text: p?.budget.toString() ?? '');
    _durationController = TextEditingController(text: p?.duration ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _locationController.dispose();
    _workTypeController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final allowedWorkTypes = ['remote', 'onsite', 'hybrid'];
    final workType = _workTypeController.text.trim().toLowerCase();

    if (!allowedWorkTypes.contains(workType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work Type must be remote, onsite, or hybrid')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one skill')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final budget = num.tryParse(_budgetController.text.trim());
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid budget')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final job = JobListing(
      id: widget.existingProject?.id ?? '',
      employer: widget.existingProject?.employer ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      skills: skills,
      location: _locationController.text.trim(),
      workType: workType,
      budget: budget,
      duration: _durationController.text.trim(),
      status: widget.existingProject?.status ?? 'open',
      acceptedBy: widget.existingProject?.acceptedBy ?? [],
      createdAt: widget.existingProject?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.existingProject == null) {
        await _projectService.createProject(job);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created!')),
        );
      } else {
        await _projectService.updateProject(job.id, job);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated!')),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingProject != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Project' : 'Create Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                maxLines: 3,
              ),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(labelText: 'Skills (comma separated)'),
                validator: (v) => v == null || v.isEmpty ? 'Enter at least one skill' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
              ),
              TextFormField(
                controller: _workTypeController,
                decoration: const InputDecoration(labelText: 'Work Type (remote/onsite/hybrid)'),
                validator: (v) => v == null || v.isEmpty ? 'Enter work type' : null,
              ),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(labelText: 'Budget'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter budget' : null,
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration'),
                validator: (v) => v == null || v.isEmpty ? 'Enter duration' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: Text(_isLoading
                    ? (isEdit ? 'Updating...' : 'Creating...')
                    : (isEdit ? 'Update Project' : 'Create Project')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}