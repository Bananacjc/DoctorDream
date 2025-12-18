import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';
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
          success ? 'Profile saved.' : 'Error saving profile.',
          style: TextStyle(color: ColorConstant.onPrimary),
        ),
        backgroundColor: success ? ColorConstant.primary : ColorConstant.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          return Scaffold(
            backgroundColor: ColorConstant.surface,
            body: Center(
              child: CircularProgressIndicator(color: ColorConstant.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: ColorConstant.surface,
          appBar: AppBar(
            backgroundColor: ColorConstant.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: ColorConstant.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: Text(
              "My Profile",
              style: GoogleFonts.robotoFlex(
                color: ColorConstant.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: _viewModel.isSaving ? null : _toggleEditState,
                  style: IconButton.styleFrom(
                    backgroundColor: _isEditing
                        ? ColorConstant.primaryContainer
                        : Colors.transparent,
                    foregroundColor: _isEditing
                        ? ColorConstant.onPrimaryContainer
                        : ColorConstant.onSurfaceVariant,
                  ),
                  icon: _viewModel.isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorConstant.primary,
                          ),
                        )
                      : Icon(
                          _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                        ),
                  tooltip: _isEditing ? 'Save Profile' : 'Edit Profile',
                ),
                ),
            ],
          ),
          body: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
                      child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                // Header / Avatar
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                            color:
                                ColorConstant.primaryContainer.withOpacity(0.5),
                            width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                          backgroundColor: ColorConstant.secondaryContainer,
                          child: Icon(
                                      Icons.person_rounded, 
                                      size: 50, 
                            color: ColorConstant.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                          right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ColorConstant.primary,
                                        shape: BoxShape.circle,
                              border: Border.all(
                                  color: ColorConstant.surface, width: 2),
                                      ),
                            child: Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                              color: ColorConstant.onPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!_isEditing) ...[
                  Center(
                    child: Column(
                      children: [
                            Text(
                              _nameController.text.isNotEmpty 
                                  ? _nameController.text 
                                  : 'Your Name',
                          style: GoogleFonts.robotoFlex(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                            color: ColorConstant.onSurface,
                              ),
                            ),
                            if (_pronounsController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _pronounsController.text,
                              style: GoogleFonts.robotoFlex(
                                    fontSize: 14,
                                color: ColorConstant.onSurfaceVariant,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ] else
                            const SizedBox(height: 32),

                // Sections
                _buildSectionHeader("Identity"),
                const SizedBox(height: 16),
                _buildCardContainer([
                  _buildTextField(
                    controller: _nameController,
                    label: "Full Name",
                            icon: Icons.badge_outlined,
                    isLast: false,
                          ),
                  _buildTextField(
                    controller: _pronounsController,
                    label: "Pronouns",
                            icon: Icons.record_voice_over_outlined,
                    isLast: false,
                          ),
                  _buildTextField(
                    controller: _birthdayController,
                    label: "Birthday",
                            icon: Icons.cake_outlined,
                    isLast: true,
                            keyboardType: TextInputType.datetime,
                          ),
                ]),

                const SizedBox(height: 24),
                _buildSectionHeader("Contact Info"),
                          const SizedBox(height: 16),
                _buildCardContainer([
                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                            icon: Icons.email_outlined,
                    isLast: false,
                            keyboardType: TextInputType.emailAddress,
                          ),
                  _buildTextField(
                    controller: _phoneController,
                    label: "Phone",
                            icon: Icons.phone_outlined,
                    isLast: false,
                            keyboardType: TextInputType.phone,
                          ),
                  _buildTextField(
                    controller: _locationController,
                    label: "Location",
                            icon: Icons.location_on_outlined,
                    isLast: true,
                          ),
                ]),

                const SizedBox(height: 24),
                _buildSectionHeader("About Me"),
                          const SizedBox(height: 16),
                _buildCardContainer([
                  _buildTextField(
                    controller: _notesController,
                    label: "Personal Notes",
                            icon: Icons.edit_note_outlined,
                    isLast: true,
                            maxLines: 4,
                          ),
                ]),
                const SizedBox(height: 40),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
        child: Text(
          title.toUpperCase(),
        style: GoogleFonts.robotoFlex(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          color: ColorConstant.primary,
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstant.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorConstant.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isLast = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: Icon(
                  icon,
                  size: 24,
                  color: _isEditing
                      ? ColorConstant.primary
                      : ColorConstant.onSurfaceVariant,
          ),
        ),
              Expanded(
        child: TextField(
          controller: controller,
                  readOnly: !_isEditing,
                  enabled: _isEditing,
          maxLines: maxLines,
          keyboardType: keyboardType,
                  style: GoogleFonts.robotoFlex(
                    fontSize: 16,
                    color: ColorConstant.onSurface,
                  ),
          decoration: InputDecoration(
            labelText: label,
                    labelStyle: GoogleFonts.robotoFlex(
                      color: ColorConstant.onSurfaceVariant,
                    ),
            border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
            isDense: true,
          ),
        ),
      ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: ColorConstant.outlineVariant.withOpacity(0.2),
          ),
      ],
    );
  }
}
