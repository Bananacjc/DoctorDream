import 'package:flutter/material.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  // State management
  bool _isLoading = true;
  String? _error;
  // Kept for potential future use; currently we show inline only.
  // ignore: unused_field
  List<dynamic> _musicRecommendations = [];
  String? _musicInlineAnswer;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 1) Hardcoded dream data
      final List<String> demoDreams = <String>[
        'question: please say yes to me. Reply only: yes',
      ];
      // 2) Use a static placeholder (no external services)
      final List<Map<String, String>> rows = [
        {
          'dream_content': demoDreams.first,
          'answer': 'yes',
        }
      ];

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = null;
        _musicRecommendations = rows;
        // Build a compact inline answer summary for the Music header
        final answers = rows.map((e) => (e['answer'] ?? '').trim()).where((s) => s.isNotEmpty).toList();
        _musicInlineAnswer = answers.isEmpty ? null : answers.first;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF081944);
    const Color lightNavy = Color(0xFF0D2357);
    // const Color pillBg = Color(0xFF2E3D6B); // reserved for future use
    const Color accent = Color(0xFFB7B9FF);
    const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16.0);

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 12.0, bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      'Recommend today',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,                
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Something here but i dont know',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9AA5C4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category row
            SliverToBoxAdapter(
              child: SizedBox(
                height: 88,
                child: ListView(
                  padding: pagePadding,
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _CategoryPill(label: 'All', icon: Icons.spa_outlined, selected: true),
                    _CategoryPill(label: 'Music', icon: Icons.music_note_outlined),
                    _CategoryPill(label: 'Video', icon: Icons.play_circle_outline),
                    _CategoryPill(label: 'Exercise', icon: Icons.self_improvement_outlined),
                    _CategoryPill(label: 'Article', icon: Icons.article_outlined),
                  ],
                ),
              ),
            ),

            // Best for you card
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Best for you',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: lightNavy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: _PlayGlyph(color: accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sections: Music, Video, Exercise
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionRow(title: 'Music', trailing: _isLoading ? 'Loading…' : (_error ?? (_musicInlineAnswer ?? ''))),
                    const SizedBox(height: 12),
                    const _CardRow(),
                    const SizedBox(height: 20),
                    const _SectionRow(title: 'Video'),
                    const SizedBox(height: 12),
                    const _CardRow(),
                    const SizedBox(height: 20),
                    const _SectionRow(title: 'Exercise'),
                    const SizedBox(height: 12),
                    const _CardRow(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  const _CategoryPill({required this.label, required this.icon, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFB7B9FF).withOpacity(0.25) : const Color(0xFF2E3D6B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFB7B9FF)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFFB4BEDA),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionRow({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if ((trailing ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trailing!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9AA5C4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: const Color(0xFF9AA5C4)),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Container(
            width: 92,
            decoration: BoxDecoration(
              color: const Color(0xFF0D2357),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: _PlayGlyph()),
          );
        },
      ),
    );
  }
}

class _PlayGlyph extends StatelessWidget {
  final Color color;
  const _PlayGlyph({this.color = const Color(0xFF9AA5C4)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.play_arrow_rounded, color: color, size: 20),
    );
  }
}


// Inline-only display now; list implementation removed.


