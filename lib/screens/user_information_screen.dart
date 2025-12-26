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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pronounsController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  bool _hasChanges = false;
  bool _hasAppliedInitialProfile = false;
  late final UserProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UserProfileViewModel();
    _viewModel.loadProfile();

    _nameController.addListener(_onFieldChanged);
    _pronounsController.addListener(_onFieldChanged);
    _birthdayController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _pronounsController.removeListener(_onFieldChanged);
    _birthdayController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _locationController.removeListener(_onFieldChanged);
    _notesController.removeListener(_onFieldChanged);

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

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Allow empty email
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't save if validation fails
    }

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
    if (success) {
      setState(() {
        _hasChanges = false;
      });
    }
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
                child: _viewModel.isSaving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorConstant.primary,
                        ),
                      )
                    : (_hasChanges
                        ? IconButton(
                            onPressed: () {
                              if (!_viewModel.isSaving) {
                                FocusScope.of(context).unfocus();
                                _saveProfile();
                              }
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: ColorConstant.primaryContainer,
                              foregroundColor:
                                  ColorConstant.onPrimaryContainer,
                            ),
                            icon: const Icon(Icons.check_rounded),
                            tooltip: 'Save Profile',
                          )
                        : const SizedBox.shrink()),
                ),
            ],
          ),
          body: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            validator: _validateEmail,
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
    String? Function(String?)? validator,
  }) {
    return Builder(
      builder: (context) {
        String? errorText;
        if (validator != null) {
          errorText = validator(controller.text);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: errorText != null
                        ? Colors.red.withOpacity(0.7)
                        : Colors.white.withOpacity(0.5),
                    width: errorText != null ? 1.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        icon,
                        size: 22,
                        color: errorText != null
                            ? Colors.red
                            : ColorConstant.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: validator != null
                          ? TextFormField(
                              controller: controller,
                              maxLines: maxLines,
                              keyboardType: keyboardType,
                              validator: validator,
                              onChanged: (value) {
                                // Trigger rebuild to update border color
                                setState(() {});
                              },
                              style: GoogleFonts.robotoFlex(
                                fontSize: 16,
                                color: ColorConstant.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: label,
                                labelStyle: GoogleFonts.robotoFlex(
                                  color: errorText != null
                                      ? Colors.red
                                      : ColorConstant.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorText: null,
                                errorStyle: const TextStyle(height: 0),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                            )
                          : TextField(
                              controller: controller,
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
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 56, top: 4, bottom: 8),
                child: Text(
                  errorText,
                  style: GoogleFonts.robotoFlex(
                    fontSize: 12,
                    color: Colors.red,
                  ),
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
      },
    );
  }
}
