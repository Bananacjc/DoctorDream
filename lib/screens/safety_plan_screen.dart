import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';
import '../data/models/safety_plan.dart';
import '../view_models/safety_plan_view_model.dart';

class SafetyPlanScreen extends StatefulWidget {
  const SafetyPlanScreen({super.key});

  @override
  State<SafetyPlanScreen> createState() => _SafetyPlanScreenState();
}

class _SafetyPlanScreenState extends State<SafetyPlanScreen> {
  late final SafetyPlanViewModel _viewModel;
  SafetyPlan? _activePlan;
  int _activeStepIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _viewModel = SafetyPlanViewModel();
    _viewModel.loadPlans();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _startPlan(SafetyPlan plan) {
    setState(() {
      _activePlan = plan;
      _activeStepIndex = 0;
      _pageController = PageController(initialPage: 0);
    });
  }

  void _exitActiveMode() {
    setState(() {
      _activePlan = null;
      _activeStepIndex = 0;
    });
  }

  void _nextStep() {
    if (_activePlan == null) return;
    if (_activeStepIndex < _activePlan!.steps.length - 1) {
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
            _exitActiveMode();
          },
          child: Text("I'm Good", style: TextStyle(color: ColorConstant.primary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Optionally restart or keep active
            setState(() {
              _activeStepIndex = 0;
            });
          },
          child: Text("Restart Plan", style: TextStyle(color: ColorConstant.secondary)),
        ),
      ],
    );
  }

  Future<void> _showAddPlanDialog({SafetyPlan? existingPlan}) async {
    final isEditing = existingPlan != null;
    final titleController = TextEditingController(text: existingPlan?.title);
    final stepController = TextEditingController();
    final List<String> steps =
        isEditing ? List.from(existingPlan.steps) : [];

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
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints:
                        const BoxConstraints(maxWidth: 400, maxHeight: 600),
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
                            color:
                                ColorConstant.primaryContainer.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEditing ? Icons.edit : Icons.shield_outlined,
                            size: 40,
                            color: ColorConstant.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isEditing ? "Edit Safety Plan" : "New Safety Plan",
                          style: GoogleFonts.robotoFlex(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "What helps you feel safe?",
                          style: GoogleFonts.robotoFlex(
                            fontSize: 16,
                            color: ColorConstant.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Title Input
                    TextField(
                      controller: titleController,
                          style: TextStyle(color: ColorConstant.onSurface),
                      decoration: InputDecoration(
                            labelText: "Plan Title (e.g., 'Anxiety Attack')",
                            labelStyle: TextStyle(
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
                        // Steps List
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorConstant.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ColorConstant.outlineVariant
                                    .withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: stepController,
                                          style: TextStyle(
                                              color: ColorConstant.onSurface),
                                          decoration: InputDecoration(
                                            hintText: "Add a step...",
                                            hintStyle: TextStyle(
                                                color: ColorConstant
                                                    .onSurfaceVariant
                                                    .withOpacity(0.5)),
                                            border: InputBorder.none,
                                            isDense: true,
                                          ),
                                          onSubmitted: (value) {
                                            if (value.trim().isNotEmpty) {
                                              setState(() {
                                                steps.add(value.trim());
                                                stepController.clear();
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_rounded,
                                            color: ColorConstant.secondary),
                                        onPressed: () {
                                          if (stepController.text
                                              .trim()
                                              .isNotEmpty) {
                                            setState(() {
                                              steps.add(stepController.text
                                                  .trim());
                                              stepController.clear();
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (steps.isNotEmpty)
                                  Flexible(
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      itemCount: steps.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                              height: 1,
                                              color: ColorConstant
                                                  .outlineVariant
                                                  .withOpacity(0.1)),
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: ColorConstant
                                                      .secondaryContainer,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "${index + 1}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: ColorConstant
                                                          .onSecondaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () async {
                                                    final editedStep =
                                                        await showDialog<String>(
                                                      context: context,
                                                      builder: (context) {
                                                        final controller =
                                                            TextEditingController(
                                                                text: steps[
                                                                    index]);
                                                        return AlertDialog(
                                                          backgroundColor:
                                                              ColorConstant
                                                                  .surfaceContainer,
                                                          title: Text(
                                                              "Edit Step",
                                                              style: TextStyle(
                                                                  color: ColorConstant
                                                                      .onSurface)),
                                                          content: TextField(
                                                            controller:
                                                                controller,
                                                            autofocus: true,
                                                            style: TextStyle(
                                                                color: ColorConstant
                                                                    .onSurface),
                                                            decoration:
                                                                InputDecoration(
                                                              hintText:
                                                                  "Enter step details...",
                                                              hintStyle: TextStyle(
                                                                  color: ColorConstant
                                                                      .onSurfaceVariant),
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: Text(
                                                                  "Cancel",
                                                                  style: TextStyle(
                                                                      color: ColorConstant
                                                                          .primary)),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      controller
                                                                          .text
                                                                          .trim()),
                                                              child: Text(
                                                                  "Save",
                                                                  style: TextStyle(
                                                                      color: ColorConstant
                                                                          .primary)),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                    if (editedStep != null &&
                                                        editedStep.isNotEmpty) {
                                                      setState(() {
                                                        steps[index] =
                                                            editedStep;
                                                      });
                                                    }
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 4),
                                                    child: Text(
                                                      steps[index],
                                                      style: TextStyle(
                                                          color: ColorConstant
                                                              .onSurface),
                                                    ),
                        ),
                      ),
                    ),
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    size: 18,
                                                    color: ColorConstant
                                                        .onSurfaceVariant),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () async {
                                                  final editedStep =
                                                      await showDialog<String>(
                                                    context: context,
                                                    builder: (context) {
                                                      final controller =
                                                          TextEditingController(
                                                              text:
                                                                  steps[index]);
                                                      return AlertDialog(
                                                        backgroundColor:
                                                            ColorConstant
                                                                .surfaceContainer,
                                                        title: Text("Edit Step",
                                                            style: TextStyle(
                                                                color: ColorConstant
                                                                    .onSurface)),
                                                        content: TextField(
                                                          controller:
                                                              controller,
                                                          autofocus: true,
                                                          style: TextStyle(
                                                              color: ColorConstant
                                                                  .onSurface),
                                                          decoration:
                                                              InputDecoration(
                        hintText:
                                                                "Enter step details...",
                                                            hintStyle: TextStyle(
                                                                color: ColorConstant
                                                                    .onSurfaceVariant),
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child: Text(
                                                                "Cancel",
                                                                style: TextStyle(
                                                                    color: ColorConstant
                                                                        .primary)),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    controller
                                                                        .text
                                                                        .trim()),
                                                            child: Text("Save",
                                                                style: TextStyle(
                                                                    color: ColorConstant
                                                                        .primary)),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                  if (editedStep != null &&
                                                      editedStep.isNotEmpty) {
                                                    setState(() {
                                                      steps[index] = editedStep;
                                                    });
                                                  }
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: Icon(Icons.close,
                                                    size: 18,
                                                    color: ColorConstant
                                                        .onSurfaceVariant),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () {
                                                  setState(() {
                                                    steps.removeAt(index);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                if (steps.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text(
                                      "No steps added yet",
                                      style: TextStyle(
                                        color: ColorConstant.onSurfaceVariant
                                            .withOpacity(0.5),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      ColorConstant.onSurfaceVariant,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                                  if (titleController.text.isNotEmpty &&
                                      steps.isNotEmpty) {
                                    if (isEditing) {
                                      await _viewModel.updatePlan(
                                        existingPlan.copyWith(
                                          title: titleController.text,
                                          steps: steps,
                                        ),
                                      );
                                    } else {
                                      await _viewModel.addPlan(
                                        title: titleController.text,
                                        steps: steps,
                                      );
                                    }
                                    if (mounted) Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConstant.primary,
                                  foregroundColor: ColorConstant.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  "Save Plan",
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
            );
          },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activePlan != null) {
      return _buildActiveMode();
    }
    return _buildListMode();
  }

  Widget _buildListMode() {
    return Scaffold(
      backgroundColor: ColorConstant.surface,
      appBar: AppBar(
        backgroundColor: ColorConstant.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Safety Plans",
          style: GoogleFonts.robotoFlex(
            color: ColorConstant.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: ColorConstant.onSurface),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlanDialog(),
        backgroundColor: ColorConstant.primaryContainer,
        foregroundColor: ColorConstant.onPrimaryContainer,
        icon: const Icon(Icons.add),
        label: const Text("Create Plan"),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 64, color: ColorConstant.outline.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    "No safety plans yet",
                    style: GoogleFonts.robotoFlex(
                      fontSize: 18,
                      color: ColorConstant.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create a plan to guide you when you need it most.",
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
            itemCount: _viewModel.plans.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final plan = _viewModel.plans[index];
              return _buildPlanCard(plan);
            },
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(SafetyPlan plan) {
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
        onTap: () => _startPlan(plan),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConstant.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shield,
                        color: ColorConstant.onSecondaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                          child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                          plan.title,
                          style: GoogleFonts.robotoFlex(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.onSurface,
                          ),
                        ),
                                  Text(
                          "${plan.steps.length} Steps",
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
                        _showAddPlanDialog(existingPlan: plan);
                      } else if (value == 'delete') {
                        _confirmDelete(plan);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
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
                  const SizedBox(width: 8),
                  Icon(Icons.play_circle_fill_rounded,
                      size: 40, color: ColorConstant.primary),
                ],
              ),
              if (plan.steps.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstant.surface,
                    borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      children: [
                      Text(
                        "First step:",
                        style: GoogleFonts.robotoFlex(
                          color: ColorConstant.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                          plan.steps.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.robotoFlex(
                            color: ColorConstant.onSurface,
                            fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(SafetyPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorConstant.surfaceContainer,
        title: Text('Delete Plan?',
            style: TextStyle(color: ColorConstant.onSurface)),
        content: Text('Are you sure you want to delete "${plan.title}"?',
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
      await _viewModel.deletePlan(plan);
    }
  }

  Widget _buildActiveMode() {
    final progress = (_activeStepIndex + 1) / _activePlan!.steps.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exitActiveMode();
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
                  itemCount: _activePlan!.steps.length,
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
                                "Step ${index + 1} of ${_activePlan!.steps.length}",
                                style: GoogleFonts.robotoFlex(
                                  color: ColorConstant.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              _activePlan!.steps[index],
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
                        onPressed: _exitActiveMode,
                        icon: Icon(Icons.close, color: ColorConstant.onSurface),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _activePlan!.title,
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
                              _activeStepIndex == _activePlan!.steps.length - 1
                                  ? "Complete"
                                  : "Next Step",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _activeStepIndex == _activePlan!.steps.length - 1
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
