import 'dart:developer';
import 'dart:convert';

import 'package:doctor_dream/data/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/local/local_database.dart';
import '../data/models/dream_diagnosis.dart';
import '../data/models/dream_entry.dart';

class DreamDiagnosisViewModel extends ChangeNotifier {
  static const int _minDreamCount = 10;
  List<DreamDiagnosis> _allDiagnosis = [];
  List<DreamEntry> _allEntries = [];
  bool _isLoading = false;
  bool _isDiagnosing = false;

  bool get hasNoDiagnosis => _allDiagnosis.isEmpty;
  bool get hasEnoughDreams => _allEntries.length >= _minDreamCount;
  List<DreamDiagnosis> get diagnosis => _allDiagnosis;
  bool get isLoading => _isLoading;
  bool get isDiagnosing => _isDiagnosing;

  Future<void> loadDiagnosis() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allEntries = await LocalDatabase.instance.fetchDreamEntries();
      _allDiagnosis = await LocalDatabase.instance.fetchDreamDiagnosis();
    } catch (e) {
      log("ERROR LOADING : $e");
      _allDiagnosis = [];
      _allEntries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> diagnose() async {
    _isDiagnosing = true;
    notifyListeners();

    try {
      if (!hasEnoughDreams) {
        return null;
      }

      final String? previousDiagnosisContent = _allDiagnosis.isNotEmpty
          ? _allDiagnosis.first.diagnosisContent
          : null;

      final dreams = _allEntries.take(_minDreamCount).toList();
      final jsonResponse = await GeminiService.instance.diagnoseDream(
        dreams,
        previousDiagnosis: previousDiagnosisContent,
      );

      String cleanJson = jsonResponse.replaceAll('```json', '').replaceAll
        ('```', '').trim();

      final Map<String, dynamic> parsedData = jsonDecode(cleanJson);

      return {
        'content' : parsedData['content'] ?? "Analysis unavailable",
        'is_critical' : parsedData['is_critical'] ?? false
      };





    } catch (e) {
      return null;
    } finally {
      _isDiagnosing = false;
      notifyListeners();
    }
  }

  Future<bool> saveDreamDiagnosis(String content) async {
    final diagnosisID = '${Uuid().v4().substring(0, 6)}_123456';

    try {
      await LocalDatabase.instance.saveDreamDiagnosis(diagnosisID, content);
      return true;
    } catch (e) {
      log("ERROR SAVING ANALYSIS: $e");
      return false;
    }
  }
}
