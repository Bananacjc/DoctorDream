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

  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
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
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        if (!_hasAppliedInitialProfile && !_viewModel.isLoading) {
          _applyProfileToControllers(_viewModel.profile);
          _hasAppliedInitialProfile = true;
        }

        if (_viewModel.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B1F44),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0B1F44),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'My Profile',
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              if (_isEditing)
                IconButton(
                  onPressed: _viewModel.isSaving ? null : _toggleEditState,
                  icon: _viewModel.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_rounded, color: Colors.white),
                  tooltip: 'Save Profile',
                )
              else
                IconButton(
                  onPressed: _toggleEditState,
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  tooltip: 'Edit Profile',
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
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // Avatar Section
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2), 
                                      width: 1,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: const Color(0xFF243B6B),
                                    child: const Icon(
                                      Icons.person_rounded, 
                                      size: 50, 
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4E8BFF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Name & Pronouns (Header)
                          if (!_isEditing) ...[
                            Text(
                              _nameController.text.isNotEmpty 
                                  ? _nameController.text 
                                  : 'Your Name',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_pronounsController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _pronounsController.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 32),
                          ],

                          // Form Fields
                          _buildSectionTitle('Identity'),
                          _buildField(
                            'Full Name', 
                            _nameController, 
                            icon: Icons.badge_outlined,
                          ),
                          _buildField(
                            'Pronouns', 
                            _pronounsController, 
                            icon: Icons.record_voice_over_outlined,
                          ),
                          _buildField(
                            'Birthday', 
                            _birthdayController, 
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.datetime,
                          ),

                          const SizedBox(height: 16),
                          _buildSectionTitle('Contact'),
                          _buildField(
                            'Email', 
                            _emailController, 
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildField(
                            'Phone', 
                            _phoneController, 
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          _buildField(
                            'Location', 
                            _locationController, 
                            icon: Icons.location_on_outlined,
                          ),

                          const SizedBox(height: 16),
                          _buildSectionTitle('About'),
                          _buildField(
                            'Personal Notes', 
                            _notesController, 
                            icon: Icons.edit_note_outlined,
                            maxLines: 4,
                          ),
                          
                          // Bottom spacing for FAB
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: null,
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    final isReadOnly = !_isEditing;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isReadOnly 
              ? Colors.white.withOpacity(0.05) 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isReadOnly 
                ? Colors.transparent 
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: TextField(
          controller: controller,
          readOnly: isReadOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: isReadOnly 
                  ? Colors.white.withOpacity(0.5) 
                  : Colors.white.withOpacity(0.8),
            ),
            prefixIcon: icon != null 
                ? Icon(
                    icon, 
                    color: isReadOnly 
                        ? Colors.white.withOpacity(0.4) 
                        : const Color(0xFF4E8BFF),
                    size: 22,
                  ) 
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
