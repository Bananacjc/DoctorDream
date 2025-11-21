import 'package:flutter/material.dart';

class SafetyPlanScreen extends StatefulWidget {
  const SafetyPlanScreen({super.key});

  @override
  State<SafetyPlanScreen> createState() => _SafetyPlanScreenState();
}

class _SafetyPlanScreenState extends State<SafetyPlanScreen> {
  final List<_SafetyPlan> _plans = [
    _SafetyPlan(
      title: 'Ground + Reach Out',
      steps: [
        '30-second grounding: name 5 things you can see',
        'Send “Need a check-in” text to Marcus',
        'Play favorite calm playlist',
      ],
    ),
    _SafetyPlan(
      title: 'Emergency Reset',
      steps: [
        'Move to safe, quiet space',
        'Open breathing exercise app',
        'Call therapist hotline if still overwhelmed',
      ],
    ),
  ];

  int? _activePlanIndex;

  Future<void> _addPlan() async {
    final titleController = TextEditingController();
    final stepsController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    prefixIcon:
                        const Icon(Icons.flag_outlined, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
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
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
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
                    onPressed: () {
                      final rawSteps = stepsController.text
                          .split('\n')
                          .map((step) => step.trim())
                          .where((step) => step.isNotEmpty)
                          .toList();
                      if (titleController.text.trim().isEmpty ||
                          rawSteps.isEmpty) {
                        return;
                      }
                      setState(() {
                        _plans.add(
                          _SafetyPlan(
                            title: titleController.text.trim(),
                            steps: rawSteps,
                          ),
                        );
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save Plan'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startPlan(int index) {
    setState(() {
      _activePlanIndex = index;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting "${_plans[index].title}"')),
    );
  }

  void _deletePlan(int index) {
    final removed = _plans[index];
    setState(() {
      if (_activePlanIndex == index) {
        _activePlanIndex = null;
      }
      _plans.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${removed.title} deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: _plans.isEmpty
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
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
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
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                              const EdgeInsets.symmetric(horizontal: 16),
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
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow),
                                color: Colors.green,
                                onPressed: () => _startPlan(index),
                                tooltip: 'Start plan',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.redAccent,
                                onPressed: () => _deletePlan(index),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0; i < plan.steps.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.15),
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                            color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              plan.steps[i],
                                              style: const TextStyle(
                                              height: 1.4,
                                              color: Colors.white,
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
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemCount: _plans.length,
                ),
        ),
      ),
    );
  }
}

class _SafetyPlan {
  _SafetyPlan({
    required this.title,
    required this.steps,
  });

  final String title;
  final List<String> steps;
}

