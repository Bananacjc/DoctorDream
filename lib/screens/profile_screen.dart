import 'dart:math' as math;
import 'package:flutter/material.dart';

// Keep your existing imports
import 'calm_kit_screen.dart';
import 'contact_screen.dart';
import 'safety_plan_screen.dart';
import 'user_information_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF081944);
    const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF081944), // navy
              Color(0xFF0D2357), // slightly lighter navy
              Color(0xFF152C69), // even lighter
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            // IMPORTANT: BouncingScrollPhysics is required for this effect to work on Android
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // --- Header ---
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

              // --- Info Cards ---
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

              // --- Mood Graph ---
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
                        height: 110,
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

              // --- Action Items ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: pagePadding.copyWith(top: 24.0),
                  child: Column(
                    children: [
                      _ActionItem(
                        icon: Icons.person_outline,
                        title: 'User Information',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const UserInformationScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionItem(
                        icon: Icons.phone_outlined,
                        title: 'Family/Friend Contact',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ContactScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionItem(
                        icon: Icons.favorite_outline,
                        title: 'My Calm Kit / Favorites',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CalmKitScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionItem(
                        icon: Icons.add_circle_outline,
                        title: 'Safety Plan',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SafetyPlanScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Add extra padding at the bottom so the scroll view has room to bounce
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
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
          Icon(icon, color: iconColor, size: 32),
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
    return CustomPaint(painter: _GraphPainter(), child: Container());
  }
}

class _GraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final width = size.width;
    final height = size.height;

    // Generate more granular data points using sine waves for a smoother trend.
    final points = <Offset>[];
    const totalPoints = 24;

    for (int i = 0; i < totalPoints; i++) {
      final progress = i / (totalPoints - 1);
      final x = progress * width;
      final baseWave = math.sin(progress * math.pi * 2);
      final subtleWave = math.sin(progress * math.pi * 6) * 0.25;
      final y = height * 0.55 - (baseWave + subtleWave) * height * 0.28;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midPoint = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(
        previous.dx,
        previous.dy,
        midPoint.dx,
        midPoint.dy,
      );
    }

    // Ensure the final segment reaches the last point.
    final penultimate = points[points.length - 2];
    final last = points.last;
    path.quadraticBezierTo(penultimate.dx, penultimate.dy, last.dx, last.dy);

    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
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
        leading: Icon(icon, color: Colors.black87, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }
}
