import 'package:flutter/material.dart';

import '../data/models/user_profile.dart';
import '../view_models/user_profile_view_model.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  final _nameController = TextEditingController();
  final _pronounsController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEditing = false;
  bool _hasAppliedInitialProfile = false;
  late final UserProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UserProfileViewModel();
    _viewModel.loadProfile();
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
    _viewModel.dispose();
    super.dispose();
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
    if (_viewModel.isLoading) return;
    if (_isEditing) {
      FocusScope.of(context).unfocus();
      await _saveProfile();
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    final updatedProfile = _viewModel.profile.copyWith(
      fullName: _nameController.text.trim(),
      pronouns: _pronounsController.text.trim(),
      birthday: _birthdayController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final success = await _viewModel.saveProfile(updatedProfile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profile saved locally.' : 'Error saving profile.',
        ),
      ),
    );
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
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        if (!_hasAppliedInitialProfile && !_viewModel.isLoading) {
          _applyProfileToControllers(_viewModel.profile);
          _hasAppliedInitialProfile = true;
        }

        if (_viewModel.isLoading) {
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
                                  style:
                                      theme.textTheme.titleLarge?.copyWith(
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF4E8BFF),
                                disabledBackgroundColor:
                                    Colors.blueGrey.shade200,
                              ),
                              onPressed: _isEditing && !_viewModel.isSaving
                                  ? _toggleEditState
                                  : null,
                              icon: _viewModel.isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_viewModel.isSaving
                                  ? 'Saving...'
                                  : 'Save Changes'),
                            ),
                          ),
                          if (_viewModel.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _viewModel.errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
