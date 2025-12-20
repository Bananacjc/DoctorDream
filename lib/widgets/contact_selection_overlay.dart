import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/color_constant.dart';
import '../data/models/support_contact.dart';
import '../view_models/contact_view_model.dart';

class ContactSelectionOverlay extends StatefulWidget {
  final ContactViewModel viewModel;
  final Function(SupportContact) onContactSelected;

  const ContactSelectionOverlay({
    super.key,
    required this.viewModel,
    required this.onContactSelected,
  });

  @override
  State<ContactSelectionOverlay> createState() =>
      _ContactSelectionOverlayState();
}

class _ContactSelectionOverlayState
    extends State<ContactSelectionOverlay> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _breathingController;
  late List<AnimationController> _itemControllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // 4 seconds for breathing cycle
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    final contacts = widget.viewModel.contacts;
    _itemControllers = List.generate(
      contacts.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    _slideAnimations = _itemControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ),
      );
    }).toList();

    _fadeAnimations = _itemControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
        ),
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() async {
    await _controller.forward();
    // Animate items from bottom to top with gentle staggered delay
    for (int i = 0; i < _itemControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 150 * i));
      _itemControllers[i].forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _breathingController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
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
        SnackBar(
          content: Text('Could not launch $phoneNumber'),
          backgroundColor: ColorConstant.surfaceContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = widget.viewModel.contacts;

    return Scaffold(
      backgroundColor: ColorConstant.scrim.withOpacity(0.9),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorConstant.surfaceDim,
              ColorConstant.surface,
              ColorConstant.surfaceContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _controller,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ColorConstant.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: ColorConstant.outlineVariant.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstant.scrim.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Breathing guide circle
                              AnimatedBuilder(
                                animation: _breathingAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          ColorConstant.primary.withOpacity(0.2 * _breathingAnimation.value),
                                          ColorConstant.primaryContainer.withOpacity(0.15 * _breathingAnimation.value),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 50 * _breathingAnimation.value,
                                        height: 50 * _breathingAnimation.value,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: ColorConstant.primaryContainer.withOpacity(0.4),
                                          border: Border.all(
                                            color: ColorConstant.primary.withOpacity(0.4),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.favorite_outline,
                                          color: ColorConstant.primary,
                                          size: 24 * _breathingAnimation.value,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "You are loved",
                                style: GoogleFonts.robotoFlex(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: ColorConstant.onSurface,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Reach out to someone you trust.\nThey're here for you.",
                                style: GoogleFonts.robotoFlex(
                                  fontSize: 15,
                                  color: ColorConstant.onSurfaceVariant,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: ColorConstant.primaryContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: ColorConstant.primary.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "Breathe with the circle",
                                  style: GoogleFonts.robotoFlex(
                                    fontSize: 12,
                                    color: ColorConstant.onPrimaryContainer,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (contacts.isEmpty)
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_outlined,
                                size: 64,
                                color: ColorConstant.outline.withOpacity(0.5),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "No contacts yet",
                                style: GoogleFonts.robotoFlex(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: ColorConstant.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "You can add contacts in Settings.\nFor now, please reach out to someone you trust.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.robotoFlex(
                                  fontSize: 15,
                                  color: ColorConstant.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        flex: 3,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          itemCount: contacts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            return SlideTransition(
                              position: _slideAnimations[index],
                              child: FadeTransition(
                                opacity: _fadeAnimations[index],
                                child: _buildContactButton(contact),
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: ColorConstant.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ColorConstant.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "I need a moment",
                                style: GoogleFonts.robotoFlex(
                                  fontSize: 15,
                                  color: ColorConstant.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildContactButton(SupportContact contact) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close contact overlay
          _makePhoneCall(contact.phone);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ColorConstant.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ColorConstant.primary.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConstant.scrim.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ColorConstant.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorConstant.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    contact.initials,
                    style: GoogleFonts.robotoFlex(
                      fontSize: 18,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contact.name,
                      style: GoogleFonts.robotoFlex(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: ColorConstant.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            contact.relationship.isNotEmpty
                                ? contact.relationship
                                : "Tap to call",
                            style: GoogleFonts.robotoFlex(
                              fontSize: 13,
                              color: ColorConstant.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.phone_rounded,
                color: ColorConstant.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

