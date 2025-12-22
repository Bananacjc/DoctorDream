import 'package:flutter/foundation.dart';
import '../data/local/local_database.dart';
import '../data/models/user_info.dart';
import '../data/models/dream_entry.dart';
import '../data/models/dream_analysis.dart';
import '../data/models/recommendation_feedback.dart';

class RecommendationViewModel extends ChangeNotifier {
  RecommendationViewModel({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance;

  final LocalDatabase _database;

  // User information
  UserInfo _userInfo = UserInfo.defaultValues();
  UserInfo get userInfo => _userInfo;

  // Latest dream and analysis
  DreamEntry? _latestDream;
  DreamEntry? get latestDream => _latestDream;

  DreamAnalysis? _latestDreamAnalysis;
  DreamAnalysis? get latestDreamAnalysis => _latestDreamAnalysis;

  // Feedback for current dream
  List<RecommendationFeedback> _currentDreamFeedback = [];
  List<RecommendationFeedback> get currentDreamFeedback => _currentDreamFeedback;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Load user profile and convert to UserInfo
  Future<void> loadUserProfile() async {
    try {
      final profile = await _database.fetchUserProfile();
      _userInfo = UserInfo.fromUserProfile(profile);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _userInfo = UserInfo.defaultValues();
      notifyListeners();
    }
  }

  /// Load the latest dream entry and its analysis
  Future<void> loadLatestDreamAnalysis() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _database.getLatestDreamWithAnalysis();
      if (result != null) {
        final dream = result['dream'] as DreamEntry?;
        final analysis = result['analysis'] as DreamAnalysis?;

        List<RecommendationFeedback> feedback = [];
        if (dream != null) {
          feedback = await _database.fetchFeedbackForDream(dream.dreamID);
        }

        _latestDream = dream;
        _latestDreamAnalysis = analysis;
        _currentDreamFeedback = feedback;
      } else {
        _latestDream = null;
        _latestDreamAnalysis = null;
        _currentDreamFeedback = [];
      }
    } catch (e) {
      debugPrint('Error loading latest dream analysis: $e');
      _latestDream = null;
      _latestDreamAnalysis = null;
      _currentDreamFeedback = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if user has already given feedback for a specific recommendation
  Future<bool> hasFeedback(String recommendationId, String dreamId) async {
    try {
      return await _database.hasFeedback(recommendationId, dreamId);
    } catch (e) {
      debugPrint('Error checking feedback: $e');
      return false;
    }
  }

  /// Save feedback for a recommendation
  Future<void> saveFeedback(RecommendationFeedback feedback) async {
    try {
      await _database.saveFeedback(feedback);
      
      // Refresh feedback list if it's for the current dream
      if (feedback.relatedDreamId == _latestDream?.dreamID) {
        _currentDreamFeedback = await _database.fetchFeedbackForDream(
          feedback.relatedDreamId,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error saving feedback: $e');
      rethrow;
    }
  }

  /// Refresh feedback list for the current dream
  Future<void> refreshFeedback() async {
    if (_latestDream == null) return;

    try {
      _currentDreamFeedback = await _database.fetchFeedbackForDream(
        _latestDream!.dreamID,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing feedback: $e');
    }
  }

  /// Initialize all data needed for recommendations
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadUserProfile(),
        loadLatestDreamAnalysis(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

