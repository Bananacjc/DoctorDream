import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/color_constant.dart';
import '../data/models/support_contact.dart';
import '../view_models/contact_view_model.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late final ContactViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ContactViewModel();
    _viewModel.loadContacts();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $phoneNumber')),
      );
    }
  }

  Future<void> _showAddContactDialog({SupportContact? existingContact}) async {
    final isEditing = existingContact != null;
    final nameController = TextEditingController(text: existingContact?.name);
    final relationshipController =
        TextEditingController(text: existingContact?.relationship);
    final phoneController = TextEditingController(text: existingContact?.phone);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Close",
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ColorConstant.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: ColorConstant.outlineVariant.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorConstant.primaryContainer.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEditing ? Icons.edit : Icons.person_add_rounded,
                        size: 40,
                        color: ColorConstant.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEditing ? "Edit Contact" : "Add Contact",
                      style: GoogleFonts.robotoFlex(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorConstant.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Keep your support circle close.",
                      style: GoogleFonts.robotoFlex(
                        fontSize: 16,
                        color: ColorConstant.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: ColorConstant.onSurface),
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle:
                            TextStyle(color: ColorConstant.onSurfaceVariant),
                        prefixIcon: Icon(Icons.person,
                            color: ColorConstant.onSurfaceVariant),
                        filled: true,
                        fillColor: ColorConstant.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: ColorConstant.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: relationshipController,
                      style: TextStyle(color: ColorConstant.onSurface),
                      decoration: InputDecoration(
                        labelText: "Relationship",
                        labelStyle:
                            TextStyle(color: ColorConstant.onSurfaceVariant),
                        prefixIcon: Icon(Icons.favorite_outline,
                            color: ColorConstant.onSurfaceVariant),
                        filled: true,
                        fillColor: ColorConstant.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: ColorConstant.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: ColorConstant.onSurface),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\+\-\s]')),
                      ],
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        labelStyle:
                            TextStyle(color: ColorConstant.onSurfaceVariant),
                        prefixIcon: Icon(Icons.phone,
                            color: ColorConstant.onSurfaceVariant),
                        filled: true,
                        fillColor: ColorConstant.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: ColorConstant.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: ColorConstant.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.robotoFlex(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.isNotEmpty &&
                                  phoneController.text.isNotEmpty) {
                                bool success;
                                if (isEditing) {
                                  success = await _viewModel.updateContact(
                                    existingContact.copyWith(
                                      name: nameController.text.trim(),
                                      relationship:
                                          relationshipController.text.trim(),
                                      phone: phoneController.text.trim(),
                                    ),
                                  );
                                } else {
                                  success = await _viewModel.addContact(
                                    name: nameController.text.trim(),
                                    relationship:
                                        relationshipController.text.trim(),
                                    phone: phoneController.text.trim(),
                                  );
                                }
                                if (success && mounted) Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstant.primary,
                              foregroundColor: ColorConstant.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Save",
                              style: GoogleFonts.robotoFlex(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(SupportContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorConstant.surfaceContainer,
        title: Text('Delete Contact?',
            style: TextStyle(color: ColorConstant.onSurface)),
        content: Text('Are you sure you want to remove ${contact.name}?',
            style: TextStyle(color: ColorConstant.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: ColorConstant.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: ColorConstant.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _viewModel.removeContact(contact);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.surface,
      appBar: AppBar(
        backgroundColor: ColorConstant.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Support Circle",
          style: GoogleFonts.robotoFlex(
            color: ColorConstant.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: ColorConstant.onSurface),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(),
        backgroundColor: ColorConstant.primaryContainer,
        foregroundColor: ColorConstant.onPrimaryContainer,
        icon: const Icon(Icons.person_add),
        label: const Text("Add Contact"),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined,
                      size: 64, color: ColorConstant.outline.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    "Your circle is empty",
                    style: GoogleFonts.robotoFlex(
                      fontSize: 18,
                      color: ColorConstant.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add trusted contacts to call when you need support.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoFlex(
                      fontSize: 14,
                      color: ColorConstant.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _viewModel.contacts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final contact = _viewModel.contacts[index];
              return _buildContactCard(contact);
            },
          );
        },
      ),
    );
  }

  Widget _buildContactCard(SupportContact contact) {
    return Card(
      color: ColorConstant.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: ColorConstant.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _makePhoneCall(contact.phone),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ColorConstant.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                    style: GoogleFonts.robotoFlex(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: GoogleFonts.robotoFlex(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorConstant.onSurface,
                      ),
                    ),
                    if (contact.relationship.isNotEmpty)
                      Text(
                        contact.relationship,
                        style: GoogleFonts.robotoFlex(
                          fontSize: 14,
                          color: ColorConstant.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: ColorConstant.onSurfaceVariant),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddContactDialog(existingContact: contact);
                  } else if (value == 'delete') {
                    _confirmDelete(contact);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _makePhoneCall(contact.phone),
                icon: Icon(Icons.phone_in_talk, color: ColorConstant.secondary),
                style: IconButton.styleFrom(
                  backgroundColor: ColorConstant.secondaryContainer,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
