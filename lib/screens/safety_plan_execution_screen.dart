import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';
import '../data/models/safety_plan.dart';

class SafetyPlanExecutionScreen extends StatefulWidget {
  final SafetyPlan plan;

  const SafetyPlanExecutionScreen({
    super.key,
    required this.plan,
  });

  @override
  State<SafetyPlanExecutionScreen> createState() =>
      _SafetyPlanExecutionScreenState();
}

class _SafetyPlanExecutionScreenState
    extends State<SafetyPlanExecutionScreen> {
  int _activeStepIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_activeStepIndex < widget.plan.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Completed
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildCompletionDialog(),
      );
    }
  }

  void _previousStep() {
    if (_activeStepIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildCompletionDialog() {
    return AlertDialog(
      backgroundColor: ColorConstant.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        "You're doing great",
        style: GoogleFonts.robotoFlex(
            color: ColorConstant.onSurface, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: Text(
        "You've completed this safety plan. Take a moment to breathe. Are you feeling better now?",
        style: GoogleFonts.robotoFlex(
            color: ColorConstant.onSurfaceVariant, fontSize: 16),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: Text("I'm Good",
              style: TextStyle(color: ColorConstant.primary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              _activeStepIndex = 0;
              _pageController = PageController(initialPage: 0);
            });
          },
          child: Text("Restart Plan",
              style: TextStyle(color: ColorConstant.secondary)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_activeStepIndex + 1) / widget.plan.steps.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: ColorConstant.surfaceContainerLowest,
        body: SafeArea(
          child: Stack(
            children: [
              // Layer 1: PageView for Swiping
              Positioned.fill(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.plan.steps.length,
                  onPageChanged: (index) {
                    setState(() {
                      _activeStepIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: ColorConstant.secondaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Step ${index + 1} of ${widget.plan.steps.length}",
                                style: GoogleFonts.robotoFlex(
                                  color: ColorConstant.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              widget.plan.steps[index],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.robotoFlex(
                                fontSize: 28,
                                height: 1.3,
                                fontWeight: FontWeight.bold,
                                color: ColorConstant.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Layer 2: Header (Fixed)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: ColorConstant.onSurface),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.plan.title,
                              style: GoogleFonts.robotoFlex(
                                fontSize: 16,
                                color: ColorConstant.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  ColorConstant.surfaceContainerHighest,
                              color: ColorConstant.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for close button
                    ],
                  ),
                ),
              ),

              // Layer 3: Controls (Fixed)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_activeStepIndex > 0)
                        TextButton.icon(
                          onPressed: _previousStep,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Previous"),
                          style: TextButton.styleFrom(
                            foregroundColor: ColorConstant.onSurfaceVariant,
                          ),
                        )
                      else
                        const SizedBox(width: 100), // Spacer
                      ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstant.primaryContainer,
                          foregroundColor: ColorConstant.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _activeStepIndex == widget.plan.steps.length - 1
                                  ? "Complete"
                                  : "Next Step",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _activeStepIndex == widget.plan.steps.length - 1
                                  ? Icons.check_circle_outline
                                  : Icons.arrow_forward,
                            ),
                          ],
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

