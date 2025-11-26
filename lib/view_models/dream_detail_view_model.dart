import 'dart:developer';

import 'package:doctor_dream/data/local/local_database.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/services/gemini_service.dart';

class DreamDetailViewModel extends ChangeNotifier {
  String? _existingAnalysis;
  bool _isDeleting = false;
  bool _isAnalyzing = false;
  bool _isFetchingAnalysis = false;

  String? get existingAnalysis => _existingAnalysis;
  bool get isDeleting => _isDeleting;
  bool get isAnalyzing => _isAnalyzing;
  bool get isFetchingAnalysis => _isFetchingAnalysis;

  Future<bool> deleteDream(String dreamID) async {
    _isDeleting = true;
    notifyListeners();

    try {
      await LocalDatabase.instance.deleteDreamEntry(dreamID);
      return true;
    } catch (e) {
      log("ERROR DELETING DREAM FROM VM: $e");
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  Future<String?> analyzeDream(String title, String content) async {
    _isAnalyzing = true;
    notifyListeners();

    try{
      final analysis = await GeminiService.instance.analyzeDream(title,
          content);
      _existingAnalysis = analysis;
      return analysis;
    } catch (e) {
      return "Error analyzing dream";
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<bool> saveDreamAnalysis(String dreamID, String content) async {
    final analysisID = '${Uuid().v4().substring(0, 6)}_123456';

    try {
      await LocalDatabase.instance.saveDreamAnalysis(dreamID, content,
          analysisID);
      return true;
    } catch (e) {
      log("ERROR SAVING ANALYSIS: $e");
      return false;
    }
   }

   Future<void> loadDreamAnalysis(String dreamID) async {
    _isFetchingAnalysis = true;
    notifyListeners();

    try {
      final analysis = await LocalDatabase.instance.fetchDreamAnalysis(dreamID);
      if (analysis != null) {
        _existingAnalysis = analysis.analysisContent;
      } else {
        _existingAnalysis = null;
      }
    } catch (e) {
      log("ERROR LOADING ANALYSIS: $e");
    } finally {
      _isFetchingAnalysis = false;
      notifyListeners();
    }
   }
}