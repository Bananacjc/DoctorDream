import 'package:flutter/foundation.dart';

import '../data/local/local_database.dart';
import '../data/models/safety_plan.dart';

class SafetyPlanViewModel extends ChangeNotifier {
  SafetyPlanViewModel({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance;

  final LocalDatabase _database;

  List<SafetyPlan> _plans = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<SafetyPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _database.fetchSafetyPlans();
      _plans = result;
    } catch (error, stackTrace) {
      debugPrint('Failed to load safety plans: $error\n$stackTrace');
      _errorMessage = 'Unable to load safety plans. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPlan({
    required String title,
    required List<String> steps,
  }) async {
    try {
      final savedPlan = await _database.insertSafetyPlan(
        SafetyPlan(title: title, steps: steps),
      );
      _plans = [savedPlan, ..._plans];
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to add safety plan: $error\n$stackTrace');
      return false;
    }
  }

  Future<bool> deletePlan(SafetyPlan plan) async {
    final index = _plans.indexWhere((element) => element.id == plan.id);
    if (index == -1) return true;

    final removed = _plans[index];
    _plans.removeAt(index);
    notifyListeners();

    final planId = removed.id;
    if (planId == null) return true;

    try {
      await _database.deleteSafetyPlan(planId);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to delete safety plan: $error\n$stackTrace');
      _plans.insert(index, removed);
      notifyListeners();
      return false;
    }
  }
}


