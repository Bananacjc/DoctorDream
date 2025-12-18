import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';
import '../data/models/safety_plan.dart';
import '../view_models/safety_plan_view_model.dart';

class SafetyPlanSelectionOverlay extends StatefulWidget {
  final SafetyPlanViewModel viewModel;
  final Function(SafetyPlan) onPlanSelected;

  const SafetyPlanSelectionOverlay({
    super.key,
    required this.viewModel,
    required this.onPlanSelected,
  });

  @override
  State<SafetyPlanSelectionOverlay> createState() =>
      _SafetyPlanSelectionOverlayState();
}

class _SafetyPlanSelectionOverlayState
    extends State<SafetyPlanSelectionOverlay> with TickerProviderStateMixin {
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

    final plans = widget.viewModel.plans;
    _itemControllers = List.generate(
      plans.length,
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

  @override
  Widget build(BuildContext context) {
    final plans = widget.viewModel.plans;

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
                                          ColorConstant.secondary.withOpacity(0.2 * _breathingAnimation.value),
                                          ColorConstant.secondaryContainer.withOpacity(0.15 * _breathingAnimation.value),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 50 * _breathingAnimation.value,
                                        height: 50 * _breathingAnimation.value,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: ColorConstant.secondaryContainer.withOpacity(0.4),
                                          border: Border.all(
                                            color: ColorConstant.secondary.withOpacity(0.4),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.shield_outlined,
                                          color: ColorConstant.secondary,
                                          size: 24 * _breathingAnimation.value,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "You're not alone",
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
                                "Take a moment to breathe.\nYour safety plan is here to guide you.",
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
                                  color: ColorConstant.secondaryContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: ColorConstant.secondary.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "Breathe with the circle",
                                  style: GoogleFonts.robotoFlex(
                                    fontSize: 12,
                                    color: ColorConstant.onSecondaryContainer,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (plans.isEmpty)
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 64,
                                color: ColorConstant.outline.withOpacity(0.5),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "No safety plans yet",
                                style: GoogleFonts.robotoFlex(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: ColorConstant.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "You can create a plan in Settings.\nFor now, please reach out to someone you trust.",
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
                          itemCount: plans.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            return SlideTransition(
                              position: _slideAnimations[index],
                              child: FadeTransition(
                                opacity: _fadeAnimations[index],
                                child: _buildPlanButton(plan),
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

  Widget _buildPlanButton(SafetyPlan plan) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close Safety Plan overlay
          widget.onPlanSelected(plan);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ColorConstant.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ColorConstant.secondary.withOpacity(0.3),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstant.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorConstant.secondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: ColorConstant.onSecondaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.title,
                      style: GoogleFonts.robotoFlex(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ColorConstant.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: ColorConstant.secondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "${plan.steps.length} steps",
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
                Icons.arrow_forward_ios,
                color: ColorConstant.secondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


