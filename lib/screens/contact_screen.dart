import 'package:flutter/material.dart';

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

  Future<void> _showContactSheet() async {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final phoneController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var isSaving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveContact() async {
              final name = nameController.text.trim();
              final relationship = relationshipController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.isEmpty || isSaving) {
                return;
              }
              setModalState(() => isSaving = true);
              try {
                final success = await _viewModel.addContact(
                  name: name,
                  relationship: relationship,
                  phone: phone,
                );
                if (!mounted) return;
                if (success) {
                  Navigator.of(context).pop();
                } else {
                  setModalState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Failed to save contact. Please try again later.'),
                    ),
                  );
                }
              } catch (_) {
                if (!mounted) return;
                setModalState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Failed to save contact. Please try again later.'),
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2F55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Add Contact',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DialogField(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                    _DialogField(
                      controller: relationshipController,
                      label: 'Relationship',
                      icon: Icons.favorite_outline,
                    ),
                    _DialogField(
                      controller: phoneController,
                      label: 'Phone Number',
                      icon: Icons.call,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveContact,
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Contact'),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeContact(SupportContact contact) async {
    final success = await _viewModel.removeContact(contact);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${contact.name} removed'
              : 'Failed to remove contact. Please try again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final contacts = _viewModel.contacts;
        final isLoading = _viewModel.isLoading;
        final errorMessage = _viewModel.errorMessage;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Family & Friend Contacts'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showContactSheet,
            backgroundColor: const Color(0xFFB7B9FF),
            foregroundColor: const Color(0xFF081944),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Contact'),
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                errorMessage,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _viewModel.loadContacts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : contacts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.groups_outlined,
                                      size: 48, color: Colors.white54),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No contacts yet.\nAdd trusted people to reach out quickly.',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: Colors.white70),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFB7B9FF),
                                      foregroundColor:
                                          const Color(0xFF081944),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _showContactSheet,
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: const Text('Add Contact'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _viewModel.loadContacts,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final contact = contacts[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.18),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor:
                                                const Color(0xFFB7B9FF)
                                                    .withOpacity(0.25),
                                            foregroundColor:
                                                const Color(0xFF081944),
                                            child: Text(
                                              contact.initials,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  contact.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  contact.relationship.isEmpty
                                                      ? 'Support contact'
                                                      : contact.relationship,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  contact.phone,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF9CC4FF),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.14),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(Icons.call),
                                                  color: Colors.green.shade400,
                                                  tooltip: 'Call',
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Pretending to call ${contact.name}...',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.12),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                  color: Colors.red.shade300,
                                                  tooltip: 'Remove',
                                                  onPressed: () =>
                                                      _removeContact(contact),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemCount: contacts.length,
                              ),
                            ),
            ),
          ),
        );
      },
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF9CC4FF)),
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
