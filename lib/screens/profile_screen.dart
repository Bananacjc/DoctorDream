import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF081944);
    const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16.0);

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 12.0, bottom: 8.0),
                child: const Text(
                  'User Central',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Three information cards
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 16.0),
                child: Row(
                  children: const [
                    Expanded(
                      child: _InfoCard(
                        color: Color(0xFFFAD7B7),
                        icon: Icons.local_fire_department_outlined,
                        iconColor: Colors.red,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        color: Color(0xFFB7B9FF),
                        icon: Icons.nightlight_round_outlined,
                        iconColor: Color(0xFF081944),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        color: Color(0xFFA7E8D7),
                        icon: Icons.emoji_events_outlined,
                        iconColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mood Trend Graph
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recently 30 days Mood Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const _MoodTrendGraph(),
                    ),
                  ],
                ),
              ),
            ),

            // Action List Items
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 24.0),
                child: Column(
                  children: const [
                    _ActionItem(
                      icon: Icons.person_outline,
                      title: 'User Information',
                    ),
                    SizedBox(height: 12),
                    _ActionItem(
                      icon: Icons.phone_outlined,
                      title: 'Family/Friend Contact',
                    ),
                    SizedBox(height: 12),
                    _ActionItem(
                      icon: Icons.favorite_outline,
                      title: 'My Calm Kit / Favorites',
                    ),
                    SizedBox(height: 12),
                    _ActionItem(
                      icon: Icons.access_time_outlined,
                      title: 'Mood Journal / Dream History',
                    ),
                    SizedBox(height: 12),
                    _ActionItem(
                      icon: Icons.add_circle_outline,
                      title: 'Safety Plan',
                    ),
                  ],
                ),
              ),
            ),

            // Emergency Help Link
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 24.0, bottom: 20.0),
                child: const Center(
                  child: Text(
                    '↑ Scroll Up For Emergency Help ↑',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9AA5C4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  
  const _InfoCard({
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Continuous record 7 days',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodTrendGraph extends StatelessWidget {
  const _MoodTrendGraph();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GraphPainter(),
      child: Container(),
    );
  }
}

class _GraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;
    
    // Create a simple fluctuating line graph
    final points = <Offset>[];
    final step = width / 10;
    
    for (int i = 0; i <= 10; i++) {
      final x = i * step;
      // Create a wavy pattern
      final y = height / 2 + (height / 3) * 
          (i % 2 == 0 ? 1 : -1) * 
          (i == 0 || i == 10 ? 0.5 : 1.0);
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ActionItem({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.black87,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black54,
        ),
        onTap: () {
          // TODO: Handle navigation
        },
      ),
    );
  }
}


