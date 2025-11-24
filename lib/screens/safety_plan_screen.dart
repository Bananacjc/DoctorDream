import 'package:flutter/material.dart';

import '../data/models/safety_plan.dart';
import '../view_models/safety_plan_view_model.dart';

class SafetyPlanScreen extends StatefulWidget {
  const SafetyPlanScreen({super.key});

  @override
  State<SafetyPlanScreen> createState() => _SafetyPlanScreenState();
}

class _SafetyPlanScreenState extends State<SafetyPlanScreen> {
  late final SafetyPlanViewModel _viewModel;
  int? _activePlanIndex;

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

  Future<void> _addPlan() async {
    final titleController = TextEditingController();
    final stepsController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var isSaving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> savePlan() async {
              final title = titleController.text.trim();
              final steps = stepsController.text
                  .split('\n')
                  .map((step) => step.trim())
                  .where((step) => step.isNotEmpty)
                  .toList();
              if (title.isEmpty || steps.isEmpty || isSaving) {
                return;
              }
              setModalState(() => isSaving = true);
              try {
                final success = await _viewModel.addPlan(
                  title: title,
                  steps: steps,
                );
                if (!mounted) return;
                if (success) {
                  Navigator.of(context).pop();
                } else {
                  setModalState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Failed to save plan. Please try again later.'),
                    ),
                  );
                }
              } catch (_) {
                if (!mounted) return;
                setModalState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Failed to save plan. Please try again later.'),
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2F55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Create Safety Plan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Plan name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.flag_outlined,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(color: Color(0xFF9CC4FF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stepsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Steps (one per line)',
                        hintText:
                            'Breathe in 4-7-8\nCall Avery\nWrite a comforting note',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(color: Color(0xFF9CC4FF)),
                        ),
                      ),
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : savePlan,
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Plan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startPlan(int index) {
    setState(() {
      _activePlanIndex = index;
    });
    final plans = _viewModel.plans;
    if (index < 0 || index >= plans.length) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting "${plans[index].title}"')),
    );
  }

  Future<void> _deletePlan(SafetyPlan plan, int index) async {
    setState(() {
      if (_activePlanIndex == index) {
        _activePlanIndex = null;
      }
    });

    final success = await _viewModel.deletePlan(plan);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${plan.title} deleted'
              : 'Failed to delete plan. Please try again.',
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
        final plans = _viewModel.plans;
        final isLoading = _viewModel.isLoading;
        final errorMessage = _viewModel.errorMessage;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Safety Plan'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _addPlan,
                icon: const Icon(Icons.add_task),
                tooltip: 'Add Plan',
              )
            ],
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
                                onPressed: _viewModel.loadPlans,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : plans.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Create your first safety plan',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _addPlan,
                                    child: const Text('Add Plan'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _viewModel.loadPlans,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final plan = plans[index];
                                  final isActive = index == _activePlanIndex;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1F325D),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 18,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Theme(
                                      data: theme.copyWith(
                                        dividerColor: Colors.transparent,
                                      ),
                                      child: ExpansionTile(
                                        initiallyExpanded: isActive,
                                        collapsedIconColor: Colors.black54,
                                        iconColor: const Color(0xFF4E8BFF),
                                        tilePadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        title: Text(
                                          plan.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isActive
                                                ? const Color(0xFF4E8BFF)
                                                : Colors.white,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${plan.steps.length} steps',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        trailing: Wrap(
                                          spacing: 4,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.play_arrow),
                                              color: Colors.green,
                                              onPressed: () =>
                                                  _startPlan(index),
                                              tooltip: 'Start plan',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline),
                                              color: Colors.redAccent,
                                              onPressed: () =>
                                                  _deletePlan(plan, index),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              20,
                                              0,
                                              20,
                                              20,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                for (var i = 0;
                                                    i < plan.steps.length;
                                                    i++)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      bottom: 10,
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 14,
                                                          backgroundColor:
                                                              Colors.white
                                                                  .withOpacity(
                                                                      0.15),
                                                          child: Text(
                                                            '${i + 1}',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                          child: Text(
                                                            plan.steps[i],
                                                            style:
                                                                const TextStyle(
                                                              height: 1.4,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemCount: plans.length,
                              ),
                            ),
            ),
          ),
        );
      },
    );
  }
}
