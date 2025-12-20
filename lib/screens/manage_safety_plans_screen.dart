import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';
import '../data/models/safety_plan.dart';
import '../view_models/safety_plan_view_model.dart';
import 'safety_plan_execution_screen.dart';

class ManageSafetyPlansScreen extends StatefulWidget {
  const ManageSafetyPlansScreen({super.key});

  @override
  State<ManageSafetyPlansScreen> createState() =>
      _ManageSafetyPlansScreenState();
}

class _ManageSafetyPlansScreenState extends State<ManageSafetyPlansScreen> {
  late final SafetyPlanViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SafetyPlanViewModel();
    _viewModel.loadPlans();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _startPlan(SafetyPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SafetyPlanExecutionScreen(plan: plan),
      ),
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

  Future<void> _duplicatePlan(SafetyPlan plan) async {
    await _viewModel.addPlan(
      title: "${plan.title} (Copy)",
      steps: List.from(plan.steps),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.surface,
      appBar: AppBar(
        backgroundColor: ColorConstant.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Manage Safety Plans",
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

          final planCount = _viewModel.plans.length;

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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorConstant.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ColorConstant.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "You have $planCount safety plan${planCount == 1 ? '' : 's'}",
                          style: GoogleFonts.robotoFlex(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _viewModel.plans.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final plan = _viewModel.plans[index];
                    return _buildPlanCard(plan);
                  },
                ),
              ),
            ],
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
                    icon: Icon(Icons.more_vert,
                        color: ColorConstant.onSurfaceVariant),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddPlanDialog(existingPlan: plan);
                      } else if (value == 'duplicate') {
                        _duplicatePlan(plan);
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
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 12),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete',
                                style: TextStyle(color: Colors.red)),
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
}

