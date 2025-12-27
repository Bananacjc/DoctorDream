import 'package:doctor_dream/screens/safety_plan_execution_screen.dart';
import 'package:doctor_dream/widgets/dream_diagnosis_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';
import '../view_models/contact_view_model.dart';
import '../view_models/dream_diagnosis_view_model.dart';
import '../view_models/safety_plan_view_model.dart';
import '../widgets/contact_selection_overlay.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_progress_indicator.dart';
import '../widgets/custom_prompt_dialog.dart';
import '../widgets/safety_plan_selection_overlay.dart';
import 'dream_edit_screen.dart';
import 'hotline_screen.dart';
import '../widgets/transition_overlay.dart';

class DreamDiagnosisScreen extends StatefulWidget {
  const DreamDiagnosisScreen({super.key});

  @override
  State<DreamDiagnosisScreen> createState() => _DreamDiagnosisScreenState();
}

class _DreamDiagnosisScreenState extends State<DreamDiagnosisScreen> {
  final DreamDiagnosisViewModel _viewModel = DreamDiagnosisViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadDiagnosis();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Widget _showNoDiagnosisDialog() {
    return CustomPromptDialog(
      title: "Quiet Mind?",
      description:
          "We haven't explored your patterns yet. Ready to see what your dreams are saying?",
      icon: Icons.nightlight_round,
      actions: [
        CustomTextButton(
          buttonText: "Discover My Patterns",
          type: ButtonType.confirm,
          onPressed: () async {
            await _handleDiagnosisTrigger();
          },
        ),
      ],
    );
  }

  Widget _showNotEnoughDreamDialog() {
    return CustomPromptDialog(
      title: "Gathering Stardust",
      description:
          "I need just a few more dreams to find the hidden threads. Keep journaling!",
      icon: Icons.hourglass_top_rounded,
      actions: [
        CustomTextButton(
          buttonText: "Write a Dream",
          type: ButtonType.confirm,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DreamEditScreen()),
            );

            if (result == true) {
              _viewModel.loadDiagnosis();
            }
          },
        ),
      ],
    );
  }

  Future<void> _showSevereConditionPrompt() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomPromptDialog(
          title: "Check In",
          icon: Icons.warning_amber_rounded,
          description:
              "Based on your recent dreams, it seems you might be "
              "going through a particularly tough time. Would you like some "
              "help?",
          actions: [
            CustomTextButton(
              buttonText: "I'm okay",
              type: ButtonType.cancel,
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
            CustomTextButton(
              buttonText: "Yes, please",
              type: ButtonType.warning,
              onPressed: () async {
                Navigator.of(context).pop();
                _showHelpDialog(context);
              },
            )
          ],
        );
      },
    );
  }

  Future<void> _diagnoseDreams() async {
    _handleDiagnosisTrigger();
  }

  Future<void> _handleDiagnosisTrigger() async {
    final result = await _viewModel.diagnose();

    if (result != null && result['content'] != null) {
      await _viewModel.saveDreamDiagnosis(result['content']);

      await _viewModel.loadDiagnosis();

      if (result['is_critical'] == true) {
        await _showSevereConditionPrompt();
      }
    }

    _viewModel.loadDiagnosis();
  }

  void _showHelpDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Close",
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: GestureDetector(
                  onTap: () {},
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      FadeTransition(
                        opacity: animation,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: const [
                              Icon(
                                Icons.emergency,
                                size: 64,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'You\'re Not Alone',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Help is available 24/7',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: const Interval(
                                  0.0,
                                  0.6,
                                  curve: Curves.easeOutBack,
                                ),
                              ),
                            ),
                        child: FadeTransition(
                          opacity: animation,
                          child: _buildEmergencyStyleButton(
                            context: context,
                            title: "Safety Plan",
                            subtitle: "Your step-by-step guide",
                            icon: Icons.shield_outlined,
                            color: ColorConstant.secondary,
                            onTap: () async {
                              final viewModel = SafetyPlanViewModel();
                              await viewModel.loadPlans();

                              if (!context.mounted) {
                                viewModel.dispose();
                                return;
                              }

                              // Always show overlay (even when there are no plans).
                              // The overlay itself will explain that no plans exist and
                              // guide the user to create one.
                              await showDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierColor: Colors.transparent,
                                builder: (context) =>
                                    SafetyPlanSelectionOverlay(
                                      viewModel: viewModel,
                                      onPlanSelected: (plan) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SafetyPlanExecutionScreen(
                                                  plan: plan,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                              );
                              // Dispose viewModel after dialog closes
                              viewModel.dispose();
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: const Interval(
                                  0.2,
                                  0.8,
                                  curve: Curves.easeOutBack,
                                ),
                              ),
                            ),
                        child: FadeTransition(
                          opacity: animation,
                          child: _buildEmergencyStyleButton(
                            context: context,
                            title: "Help Call",
                            subtitle: "Connect with your support circle",
                            icon: Icons.phone_in_talk_outlined,
                            color: ColorConstant.primary,
                            onTap: () async {
                              final viewModel = ContactViewModel();
                              await viewModel.loadContacts();

                              if (!context.mounted) {
                                viewModel.dispose();
                                return;
                              }

                              // Always show overlay (even when there are no contacts).
                              // The overlay itself will explain that no contacts exist and
                              // encourage the user to add some.
                              await showDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierColor: Colors.transparent,
                                builder: (context) => ContactSelectionOverlay(
                                  viewModel: viewModel,
                                  onContactSelected: (contact) {
                                    // Contact call is handled in the overlay
                                  },
                                ),
                              );
                              // Dispose viewModel after dialog closes
                              viewModel.dispose();
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: const Interval(
                                  0.4,
                                  1.0,
                                  curve: Curves.easeOutBack,
                                ),
                              ),
                            ),
                        child: FadeTransition(
                          opacity: animation,
                          child: _buildEmergencyStyleButton(
                            context: context,
                            title: "Hotline & Clinic",
                            subtitle: "Professional support resources",
                            icon: Icons.medical_services_outlined,
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => TransitionOverlay(
                                        nextScreen: const HotlineScreen(),
                                        message:
                                            "Connecting you to professional help.\nYou are taking a brave step.",
                                        icon: Icons.medical_services_outlined,
                                        waitForLoad: true,
                                      ),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 100),

                      FadeTransition(
                        opacity: animation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quick Grounding Techniques',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildGroundingStep(
                                number: '1',
                                text: 'Take 5 deep breaths',
                              ),
                              _buildGroundingStep(
                                number: '2',
                                text: 'Name 5 things you can see',
                              ),
                              _buildGroundingStep(
                                number: '3',
                                text: 'Name 4 things you can touch',
                              ),
                              _buildGroundingStep(
                                number: '4',
                                text: 'Name 3 things you can hear',
                              ),
                              _buildGroundingStep(
                                number: '5',
                                text: 'Name 2 things you can smell',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyStyleButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildGroundingStep({required String number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4E8BFF).withAlpha(77),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: ColorConstant.surface,
          appBar: AppBar(
            backgroundColor: ColorConstant.surface,
            centerTitle: true,
            title: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monitor_heart_rounded,
                      color: ColorConstant.primary,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Your Inner Compass",
                      style: GoogleFonts.robotoFlex(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorConstant.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Understanding the whispers of your mind",
                  style: GoogleFonts.robotoFlex(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: ColorConstant.onSurfaceVariant.withAlpha(205),
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorConstant.surfaceContainer,
                  ColorConstant.surfaceContainerHigh,
                  ColorConstant.surfaceContainerHighest,
                ],
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraint) {
                      if (_viewModel.isLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: ColorConstant.primary,
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty_rounded,
                                    color: ColorConstant.onSurface,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Connecting the dots...",
                                    style: GoogleFonts.robotoFlex(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: ColorConstant.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      if (_viewModel.hasNoDiagnosis &&
                          _viewModel.hasEnoughDreams) {
                        return Expanded(
                          child: Center(child: _showNoDiagnosisDialog()),
                        );
                      }

                      if (!_viewModel.hasEnoughDreams) {
                        return Expanded(
                          child: Center(child: _showNotEnoughDreamDialog()),
                        );
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(),
                          Icon(
                            Icons.psychology_alt_rounded,
                            size: 64,
                            color: ColorConstant.tertiary.withAlpha(200),
                          ),
                          SizedBox(height: 24),

                          if (_viewModel.diagnosis.isNotEmpty)
                            Hero(
                              tag: "diagnosis_card",
                              child: DreamDiagnosisItem(
                                dreamDiagnosis: _viewModel.diagnosis.first,
                                onRefresh: () => _viewModel.loadDiagnosis(),
                              ),
                            ),
                          SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: CustomPillButton(
                              labelText: _viewModel.isDiagnosing
                                  ? "Analyzing Patterns..."
                                  : "Reveal New Insights",
                              icon: Icons.refresh_rounded,
                              onPressed: _viewModel.isDiagnosing
                                  ? null
                                  : _diagnoseDreams,
                            ),
                          ),
                          Spacer(),
                          Text(
                            "Analysis updates based on your recent 10 dreams.",
                            style: GoogleFonts.robotoFlex(
                              color: ColorConstant.onSurfaceVariant.withAlpha(
                                100,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (_viewModel.isDiagnosing)
                  Positioned.fill(
                    child: CustomProgressIndicator(
                      icon: Icon(
                        Icons.monitor_heart_rounded,
                        size: 18,
                        color: ColorConstant.onSurface,
                      ),
                      indicatorText: Text(
                        "Revealing what is in the subconscious...",
                        style: GoogleFonts.robotoFlex(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.onSurface,
                        ),
                      ),
                    ),
                  ),
                if (!_viewModel.isDiagnosing)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: "help_button",
                      onPressed: () => _showHelpDialog(context),
                      backgroundColor: ColorConstant.secondary,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorConstant.onSecondary,
                                width: 2,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.priority_high,
                            color: ColorConstant.onSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
