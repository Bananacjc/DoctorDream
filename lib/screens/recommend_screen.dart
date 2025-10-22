import 'package:flutter/material.dart';

class RecommendScreen extends StatelessWidget {
  const RecommendScreen({super.key});

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
                  children: const [
                    _SectionRow(title: 'Music'),
                    SizedBox(height: 12),
                    _CardRow(),
                    SizedBox(height: 20),
                    _SectionRow(title: 'Video'),
                    SizedBox(height: 12),
                    _CardRow(),
                    SizedBox(height: 20),
                    _SectionRow(title: 'Exercise'),
                    SizedBox(height: 12),
                    _CardRow(),
                    SizedBox(height: 20),
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
  const _SectionRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
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


