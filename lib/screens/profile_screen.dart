import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Keep your existing imports
import 'calm_kit_screen.dart';
import 'contact_screen.dart';
import 'manage_safety_plans_screen.dart';
import 'user_information_screen.dart';
import '../view_models/profile_metrics_view_model.dart';
import '../data/models/safety_plan.dart';
import 'dream_review_screen.dart';
import 'dream_edit_screen.dart';
import 'safety_plan_execution_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileMetricsViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileMetricsViewModel();
    _viewModel.loadMetrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showMoodInsights(BuildContext context) {
    final trend = _viewModel.moodTrend;
    String title;
    String message;
    IconData icon;
    Color color;

    switch (trend) {
      case MoodTrend.improving:
        title = 'Great Progress!';
        message = 'Your dream recording activity has been increasing. Keep up the great work! Regular tracking helps you understand your patterns better.';
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case MoodTrend.stable:
        title = 'Steady Progress';
        message = 'You\'re maintaining a consistent routine. Consider recording dreams more frequently to gain deeper insights into your patterns.';
        icon = Icons.trending_flat;
        color = Colors.orange;
        break;
      case MoodTrend.declining:
        title = 'Support Available';
        message = 'Your activity has decreased recently. Remember, it\'s okay to take breaks. When you\'re ready, recording your dreams can help you process emotions.';
        icon = Icons.trending_down;
        color = Colors.amber;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF152C69),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.robotoFlex(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.robotoFlex(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.robotoFlex(color: Colors.white),
            ),
          ),
          if (trend == MoodTrend.declining)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageSafetyPlansScreen(),
                  ),
                );
              },
              child: Text(
                'View Safety Plans',
                style: GoogleFonts.robotoFlex(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              if (_viewModel.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _viewModel.loadMetrics(),
                color: Colors.white,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
              // --- Header ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: pagePadding.copyWith(top: 12.0, bottom: 8.0),
                  child: Text(
                    'User Central',
                    style: GoogleFonts.robotoFlex(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // --- Feature 2: Top 3 Info Cards ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: pagePadding.copyWith(top: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StreakCard(
                          streak: _viewModel.streak,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DreamReviewScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MoodTrendCard(
                          moodTrend: _viewModel.moodTrend,
                          onTap: () {
                            _showMoodInsights(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LastSafetyPlanCard(
                          plan: _viewModel.lastSafetyPlan,
                          onTap: () {
                            final plan = _viewModel.lastSafetyPlan;
                            if (plan != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SafetyPlanExecutionScreen(plan: plan),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManageSafetyPlansScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Feature 3: Dream Frequency Graph ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: pagePadding.copyWith(top: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dream Frequency Per Week',
                        style: GoogleFonts.robotoFlex(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _viewModel.weeklyDreamData.isEmpty
                            ? _EmptyGraphState(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DreamEditScreen(),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    _viewModel.loadMetrics();
                                  }
                                },
                              )
                            : _DreamFrequencyGraph(
                                data: _viewModel.weeklyDreamData,
                                onBarTap: (weekData) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DreamReviewScreen(),
                                    ),
                                  );
                                },
                              ),
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
                        title: 'Manage Safety Plans',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ManageSafetyPlansScreen(),
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
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- Feature 2: Card 1 - Streak ---
class _StreakCard extends StatelessWidget {
  final int streak;
  final VoidCallback? onTap;

  const _StreakCard({required this.streak, this.onTap});

  int get _nextMilestone {
    if (streak < 7) return 7;
    if (streak < 30) return 30;
    if (streak < 100) return 100;
    return streak + 50; // Every 50 after 100
  }

  int get _daysUntilMilestone => _nextMilestone - streak;

  String get _encouragementMessage {
    if (streak == 0) return 'Start your journey!';
    if (streak < 3) return 'Keep it up!';
    if (streak < 7) return 'You\'re doing great!';
    if (streak < 30) return 'Amazing progress!';
    return 'Incredible dedication!';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFAD7B7),
          borderRadius: BorderRadius.circular(12),
          border: onTap != null
              ? Border.all(color: Colors.black.withOpacity(0.1), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.local_fire_department_outlined,
                  color: Colors.red,
                  size: 32,
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.black.withOpacity(0.5),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$streak',
              style: GoogleFonts.robotoFlex(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Day Streak',
              style: GoogleFonts.robotoFlex(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (_daysUntilMilestone > 0 && streak > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_daysUntilMilestone} days to ${_nextMilestone}',
                  style: GoogleFonts.robotoFlex(
                    fontSize: 9,
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (streak > 0) ...[
              const SizedBox(height: 6),
              Text(
                _encouragementMessage,
                style: GoogleFonts.robotoFlex(
                  fontSize: 10,
                  color: Colors.black.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Feature 2: Card 2 - Mood Trend ---
class _MoodTrendCard extends StatelessWidget {
  final MoodTrend moodTrend;
  final VoidCallback? onTap;

  const _MoodTrendCard({required this.moodTrend, this.onTap});

  String get _trendText {
    switch (moodTrend) {
      case MoodTrend.improving:
        return 'Improving';
      case MoodTrend.stable:
        return 'Stable';
      case MoodTrend.declining:
        return 'Needs Support';
    }
  }

  Color get _trendColor {
    switch (moodTrend) {
      case MoodTrend.improving:
        return Colors.green;
      case MoodTrend.stable:
        return Colors.white;
      case MoodTrend.declining:
        return Colors.amber;
    }
  }

  String get _insightText {
    switch (moodTrend) {
      case MoodTrend.improving:
        return 'Based on recent activity';
      case MoodTrend.stable:
        return 'Consistent pattern';
      case MoodTrend.declining:
        return 'Support available';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFB7B9FF),
          borderRadius: BorderRadius.circular(12),
          border: onTap != null
              ? Border.all(color: Colors.black.withOpacity(0.1), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.nightlight_round_outlined,
                  color: Color(0xFF081944),
                  size: 32,
                ),
                if (onTap != null)
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.black.withOpacity(0.5),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _trendText,
              style: GoogleFonts.robotoFlex(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _trendColor,
              ),
            ),
            Text(
              'Mood Trend',
              style: GoogleFonts.robotoFlex(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _insightText,
              style: GoogleFonts.robotoFlex(
                fontSize: 9,
                color: Colors.black.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Feature 2: Card 3 - Last Safety Plan ---
class _LastSafetyPlanCard extends StatelessWidget {
  final SafetyPlan? plan;
  final VoidCallback? onTap;

  const _LastSafetyPlanCard({required this.plan, this.onTap});

  String get _displayText {
    if (plan == null) {
      return 'Create one';
    }
    
    final createdAt = plan!.createdAt;
    if (createdAt == null) {
      return 'Available';
    }

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }

  String get _actionText {
    if (plan == null) return 'Create Plan';
    return 'Use Now';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFA7E8D7),
          borderRadius: BorderRadius.circular(12),
          border: onTap != null
              ? Border.all(color: Colors.black.withOpacity(0.1), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.green,
                  size: 32,
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.black.withOpacity(0.5),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan?.title ?? 'No Plan',
              style: GoogleFonts.robotoFlex(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _displayText,
              style: GoogleFonts.robotoFlex(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _actionText,
                  style: GoogleFonts.robotoFlex(
                    fontSize: 9,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Feature 3: Dream Frequency Graph ---
class _DreamFrequencyGraph extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final Function(Map<String, dynamic>)? onBarTap;

  const _DreamFrequencyGraph({required this.data, this.onBarTap});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.robotoFlex(color: Colors.white70),
        ),
      );
    }

    final maxCount = data.map((d) => d['count'] as int).reduce(math.max);
    final maxValue = math.max(maxCount, 1); // Avoid division by zero
    final average = data.map((d) => d['count'] as int).reduce((a, b) => a + b) / data.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Average indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 14, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(
                'Average: ${average.toStringAsFixed(1)} dreams/week',
                style: GoogleFonts.robotoFlex(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        // Graph area (fixed height to avoid overflow)
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.map((weekData) {
              final count = weekData['count'] as int;
              final height = count / maxValue;
              // Give very small counts a visible bar and cap extremely high values
              final barHeight = count == 0 ? 4.0 : (30 + 70 * height); // 30–100 px within 110
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: onBarTap != null ? () => onBarTap!(weekData) : null,
                    child: Tooltip(
                      message: '${weekData['label']}: $count dream${count != 1 ? 's' : ''}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Bar
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: onBarTap != null
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.8),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              border: onBarTap != null
                                  ? Border.all(color: Colors.white, width: 1.5)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Count label
                          Text(
                            '$count',
                            style: GoogleFonts.robotoFlex(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Week labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: data.map((weekData) {
            final label = weekData['label'] as String;
            return Expanded(
              child: Text(
                label,
                style: GoogleFonts.robotoFlex(
                  color: Colors.white70,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// --- Empty Graph State ---
class _EmptyGraphState extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyGraphState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_queue_rounded,
            size: 48,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Start Your Journey',
            style: GoogleFonts.robotoFlex(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record your first dream to see your progress',
            style: GoogleFonts.robotoFlex(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Record Dream'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
          style: GoogleFonts.robotoFlex(
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
