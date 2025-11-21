import 'package:flutter/material.dart';

class CalmKitScreen extends StatefulWidget {
  const CalmKitScreen({super.key});

  @override
  State<CalmKitScreen> createState() => _CalmKitScreenState();
}

class _CalmKitScreenState extends State<CalmKitScreen> {
  final List<_CalmResource> _resources = [
    _CalmResource(title: 'Ocean Waves', description: '5 min audio reset'),
    _CalmResource(title: '4-7-8 Breath', description: 'Guided breathing drill'),
    _CalmResource(title: 'Gentle Stretch', description: 'Neck + shoulders'),
    _CalmResource(title: 'Gratitude Notes', description: 'List 3 good things'),
    _CalmResource(title: 'Warm Tea', description: 'Chamomile ritual'),
  ];

  Future<void> _addResource() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Add Calm Tool',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.self_improvement_outlined,
                      color: Colors.white70),
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
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Reminder / Usage',
                  hintText: 'Short note for how you use this tool',
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
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    setState(() {
                      _resources.add(
                        _CalmResource(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                        ),
                      );
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save Tool'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _removeResource(int index) {
    final removed = _resources[index];
    setState(() {
      _resources.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${removed.title} removed from Calm Kit')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Calm Kit'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addResource,
        backgroundColor: const Color(0xFF4E8BFF),
        icon: const Icon(Icons.add),
        label: const Text('Add Tool'),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            child: _resources.isEmpty
                ? Center(
                    child: Text(
                      'Add your favorite calming tools to see them here.',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  )
                : GridView.builder(
                    itemCount: _resources.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 140 / 176,
                    ),
                    itemBuilder: (context, index) {
                      final resource = _resources[index];
                      return Dismissible(
                        key: ValueKey(resource.title + index.toString()),
                        direction: DismissDirection.up,
                        onDismissed: (_) => _removeResource(index),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade200.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        child: _CalmResourceCard(
                          resource: resource,
                          onRemove: () => _removeResource(index),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _CalmResource {
  _CalmResource({required this.title, required this.description});

  final String title;
  final String description;
}

class _CalmResourceCard extends StatelessWidget {
  const _CalmResourceCard({
    required this.resource,
    required this.onRemove,
  });

  final _CalmResource resource;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Optional: Could add detail view or action
      },
      onLongPress: onRemove,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF243B6B), Color(0xFF0D2357)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          height: 176,
          width: 140,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    _CalmThumb(initials: resource.title),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          resource.description.isEmpty
                              ? 'Calm tool'
                              : resource.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB4BEDA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalmThumb extends StatelessWidget {
  final String initials;

  const _CalmThumb({required this.initials});

  @override
  Widget build(BuildContext context) {
    final display = initials.isNotEmpty ? initials[0].toUpperCase() : '?';
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB7B9FF), Color(0xFF6C6EE4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              display,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

