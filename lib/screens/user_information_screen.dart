import 'package:flutter/material.dart';

import '../data/local/local_database.dart';
import '../data/models/user_profile.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  final _database = LocalDatabase.instance;
  final _nameController = TextEditingController();
  final _pronounsController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile _profile = UserProfile.empty();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pronounsController.dispose();
    _birthdayController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _database.fetchUserProfile();
      UserProfile resolvedProfile = profile;
      if (profile.fullName.isEmpty &&
          profile.email.isEmpty &&
          profile.phone.isEmpty) {
        final demoProfile = UserProfile(
          fullName: 'Jamie Walker',
          pronouns: 'they / them',
          birthday: '1995-08-16',
          email: 'jamie.walker@example.com',
          phone: '+1 202 555 0168',
          location: 'Seattle, WA',
          notes:
              'Loves ambient playlists before bed.\nReminders: breathe, hydrate, stretch.',
        );
        await _database.upsertUserProfile(demoProfile);
        resolvedProfile = demoProfile;
      }
      if (!mounted) return;
      setState(() {
        _profile = resolvedProfile;
        _applyProfileToControllers(resolvedProfile);
        _isLoading = false;
      });
    } catch (e) {
      // If database fails, show default profile
      if (!mounted) return;
      setState(() {
        _profile = UserProfile(
          fullName: 'Jamie Walker',
          pronouns: 'they / them',
          birthday: '1995-08-16',
          email: 'jamie.walker@example.com',
          phone: '+1 202 555 0168',
          location: 'Seattle, WA',
          notes:
              'Loves ambient playlists before bed.\nReminders: breathe, hydrate, stretch.',
        );
        _applyProfileToControllers(_profile);
        _isLoading = false;
      });
      debugPrint('Error loading profile: $e');
    }
  }

  void _applyProfileToControllers(UserProfile profile) {
    _nameController.text = profile.fullName;
    _pronounsController.text = profile.pronouns;
    _birthdayController.text = profile.birthday;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _locationController.text = profile.location;
    _notesController.text = profile.notes;
  }

  Future<void> _toggleEditState() async {
    if (_isLoading) return;
    if (_isEditing) {
      FocusScope.of(context).unfocus();
      await _saveProfile();
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final updatedProfile = _profile.copyWith(
        fullName: _nameController.text.trim(),
        pronouns: _pronounsController.text.trim(),
        birthday: _birthdayController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );
      final savedProfile = await _database.upsertUserProfile(updatedProfile);
      if (!mounted) return;
      setState(() {
        _profile = savedProfile;
        _isSaving = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved locally.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
      debugPrint('Error saving profile: $e');
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.white70,
      ),
      hintStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF9CC4FF), width: 1.6),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: !_isEditing,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: maxLines > 1
            ? TextCapitalization.sentences
            : textCapitalization,
        style: const TextStyle(color: Colors.white),
        decoration: _decoration(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1F44),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('User Information'),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _toggleEditState,
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            label: Text(_isEditing ? 'Save' : 'Edit'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1F44), Color(0xFF122A5C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                color: Colors.white.withOpacity(0.12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: const Icon(Icons.person, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.isEmpty
                                  ? 'User Profile'
                                  : _nameController.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Tap edit to update your profile',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF13254F),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildField('Full Name', _nameController),
                      _buildField('Pronouns', _pronounsController),
                      _buildField(
                        'Birthday',
                        _birthdayController,
                        keyboardType: TextInputType.datetime,
                        textCapitalization: TextCapitalization.none,
                      ),
                      _buildField(
                        'Email',
                        _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                      ),
                      _buildField(
                        'Phone Number',
                        _phoneController,
                        keyboardType: TextInputType.phone,
                        textCapitalization: TextCapitalization.none,
                      ),
                      _buildField('City / Timezone', _locationController),
                      _buildField(
                        'Personal Notes',
                        _notesController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF4E8BFF),
                            disabledBackgroundColor: Colors.blueGrey.shade200,
                          ),
                          onPressed: _isEditing && !_isSaving
                              ? _toggleEditState
                              : null,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
