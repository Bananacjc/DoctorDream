import 'package:flutter/foundation.dart';
import '../data/local/local_database.dart';
import '../data/models/dream_entry.dart';
import '../data/models/dream_diagnosis.dart';
import '../data/models/safety_plan.dart';

enum MoodTrend { improving, stable, declining }

class ProfileMetricsViewModel extends ChangeNotifier {
  ProfileMetricsViewModel({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance;

  final LocalDatabase _database;

  int _streak = 0;
  MoodTrend _moodTrend = MoodTrend.stable;
  SafetyPlan? _lastSafetyPlan;
  List<Map<String, dynamic>> _weeklyDreamData = [];

  int get streak => _streak;
  MoodTrend get moodTrend => _moodTrend;
  SafetyPlan? get lastSafetyPlan => _lastSafetyPlan;
  List<Map<String, dynamic>> get weeklyDreamData => _weeklyDreamData;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadMetrics() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load all data
      final dreams = await _database.fetchDreamEntries();
      final diagnoses = await _database.fetchDreamDiagnosis();
      final safetyPlans = await _database.fetchSafetyPlans();

      // Calculate streak
      _streak = _calculateStreak(dreams, diagnoses);

      // Calculate mood trend
      _moodTrend = _calculateMoodTrend(dreams);

      // Get last safety plan (most recently created for now)
      _lastSafetyPlan = safetyPlans.isNotEmpty
          ? safetyPlans.first // Already sorted by created_at DESC
          : null;

      // Calculate weekly dream frequency
      _weeklyDreamData = _calculateWeeklyDreamFrequency(dreams);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile metrics: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate streak: consecutive days with dream entries or diagnoses
  int _calculateStreak(List<DreamEntry> dreams, List<DreamDiagnosis> diagnoses) {
    // Combine all activity dates
    final activityDates = <DateTime>{};
    
    for (final dream in dreams) {
      if (dream.status == DreamEntryStatus.completed) {
        // Use only the date part (ignore time)
        final date = DateTime(
          dream.createdAt.year,
          dream.createdAt.month,
          dream.createdAt.day,
        );
        activityDates.add(date);
      }
    }

    for (final diagnosis in diagnoses) {
      final date = DateTime(
        diagnosis.createdAt.year,
        diagnosis.createdAt.month,
        diagnosis.createdAt.day,
      );
      activityDates.add(date);
    }

    if (activityDates.isEmpty) return 0;

    // Sort dates descending
    final sortedDates = activityDates.toList()..sort((a, b) => b.compareTo(a));

    // Calculate consecutive days from today backwards
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    int streak = 0;
    DateTime? expectedDate = todayDate;

    for (final date in sortedDates) {
      if (expectedDate != null && date == expectedDate) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (expectedDate != null && date.isBefore(expectedDate)) {
        // Gap found, streak broken
        break;
      }
      // If date is after expected, skip it (shouldn't happen with sorted list)
    }

    return streak;
  }

  /// Calculate mood trend based on dream frequency pattern
  MoodTrend _calculateMoodTrend(List<DreamEntry> dreams) {
    // Get dreams from last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentDreams = dreams
        .where((d) => d.createdAt.isAfter(thirtyDaysAgo))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (recentDreams.length < 2) return MoodTrend.stable;

    // Split into two halves: first 15 days vs last 15 days
    final midPoint = recentDreams.length ~/ 2;
    final firstHalf = recentDreams.sublist(0, midPoint);
    final secondHalf = recentDreams.sublist(midPoint);

    final firstHalfCount = firstHalf.length;
    final secondHalfCount = secondHalf.length;

    // Simple heuristic: more dreams in second half = improving, fewer = declining
    if (secondHalfCount > firstHalfCount * 1.2) {
      return MoodTrend.improving;
    } else if (secondHalfCount < firstHalfCount * 0.8) {
      return MoodTrend.declining;
    } else {
      return MoodTrend.stable;
    }
  }

  /// Calculate weekly dream frequency for the last 4 weeks
  List<Map<String, dynamic>> _calculateWeeklyDreamFrequency(
      List<DreamEntry> dreams) {
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    
    // Filter dreams from last 4 weeks
    final recentDreams = dreams
        .where((d) => d.createdAt.isAfter(fourWeeksAgo) &&
            d.status == DreamEntryStatus.completed)
        .toList();

    // Group by week
    final weeklyData = <Map<String, dynamic>>[];
    
    for (int week = 3; week >= 0; week--) {
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));
      final weekEnd = now.subtract(Duration(days: week * 7));
      
      final weekDreams = recentDreams.where((dream) {
        return dream.createdAt.isAfter(weekStart) &&
            dream.createdAt.isBefore(weekEnd);
      }).length;

      // Generate label
      String label;
      if (week == 0) {
        label = 'This Week';
      } else if (week == 1) {
        label = 'Last Week';
      } else {
        label = '${week}W Ago';
      }

      weeklyData.add({
        'week': week,
        'count': weekDreams,
        'label': label,
      });
    }

    return weeklyData;
  }
}
