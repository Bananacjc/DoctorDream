import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Keep your existing imports
import 'calm_kit_screen.dart';
import 'contact_screen.dart';
import 'emergency_screen.dart';
import 'review_screen.dart';
import 'safety_plan_screen.dart';
import 'user_information_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  // Logic variables
  double _pullDistance = 0.0;
  final double _triggerThreshold = 70.0; // Distance to pull to trigger (reduced for easier activation)
  bool _isTriggered = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Simplified Notification Handler
  bool _handleScrollNotification(ScrollNotification notification) {
    // Handle OverscrollNotification (from BouncingScrollPhysics)
    if (notification is OverscrollNotification) {
      // overscroll is negative when pulling down past bottom
      if (notification.overscroll < 0) {
        final pullAmount = -notification.overscroll;
        setState(() {
          _pullDistance = pullAmount;
        });

        // Haptic feedback as you pull
        final previousStep = ((_pullDistance - pullAmount) / 20).floor();
        final currentStep = (pullAmount / 20).floor();
        if (currentStep != previousStep && currentStep > 0) {
          HapticFeedback.selectionClick();
        }

        // Trigger immediately when threshold is reached (don't wait for release)
        if (pullAmount >= _triggerThreshold && !_isTriggered) {
          _triggerEmergency();
        }
      } else if (notification.overscroll > 0 && _pullDistance > 0) {
        // User released or scrolled back up - reset
        setState(() {
          _pullDistance = 0.0;
        });
      }
    }

    // Also check ScrollUpdateNotification as fallback
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      final overscroll = metrics.pixels - metrics.maxScrollExtent;

      if (overscroll > 0) {
        setState(() {
          _pullDistance = overscroll;
        });

        // Haptic feedback as you pull
        final currentStep = (overscroll / 20).floor();
        if (currentStep > 0 && overscroll.toInt() % 20 == 0) {
          HapticFeedback.selectionClick();
        }

        // Trigger immediately when threshold is reached
        if (overscroll >= _triggerThreshold && !_isTriggered) {
          _triggerEmergency();
        }
      } else if (_pullDistance > 0 && overscroll <= 0) {
        // Reset if scrolled back up
        setState(() {
          _pullDistance = 0.0;
        });
      }
    }

    // Handle Release (backup trigger)
    if (notification is ScrollEndNotification) {
      if (_pullDistance >= _triggerThreshold && !_isTriggered) {
        _triggerEmergency();
      } else if (_pullDistance < _triggerThreshold) {
        // Reset if not pulled far enough
        setState(() {
          _pullDistance = 0.0;
        });
      }
    }

    return false;
  }

  Future<void> _triggerEmergency() async {
    setState(() => _isTriggered = true);

    // Distinct Emergency Haptics
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();

    if (!mounted) return;

    // Navigate immediately
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EmergencyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up from bottom animation (Urgent feel)
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutExpo;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    // Reset state when they return
    if (mounted) {
      setState(() {
        _isTriggered = false;
        _pullDistance = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF081944);
    const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16.0);

    // Calculate opacity for the indicator based on pull distance
    double progress = (_pullDistance / _triggerThreshold).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
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
                        icon: Icons.access_time_outlined,
                        title: 'Mood Journal / Dream History',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ReviewScreen(),
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

              // --- NEW EMERGENCY PULL FOOTER ---
              SliverToBoxAdapter(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: 120, // Fixed height area for the gesture visual
                  padding: const EdgeInsets.only(top: 20),
                  child: Opacity(
                    opacity: _pullDistance > 5
                        ? 1.0
                        : 0.0, // Hide if not pulling
                    child: Column(
                      children: [
                        // Dynamic Icon
                        Icon(
                          progress >= 1.0
                              ? Icons.gpp_good
                              : Icons.keyboard_double_arrow_up,
                          color: progress >= 1.0
                              ? Colors.redAccent
                              : Colors.white54,
                          size: 32 + (progress * 10), // Icon grows
                        ),
                        const SizedBox(height: 8),

                        // Dynamic Text
                        Text(
                          progress >= 1.0
                              ? 'RELEASE FOR HELP'
                              : 'PULL UP FOR EMERGENCY',
                          style: TextStyle(
                            color: progress >= 1.0
                                ? Colors.redAccent
                                : Colors.white54,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Progress Bar
                        Container(
                          width: 200,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: progress >= 1.0
                                        ? Colors.red
                                        : Colors.redAccent.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: progress >= 1.0
                                        ? [
                                            BoxShadow(
                                              color: Colors.red.withOpacity(
                                                0.6,
                                              ),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
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
              // Add extra padding at the bottom so the scroll view has room to bounce
              const SliverPadding(padding: EdgeInsets.only(bottom: 1)),
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
