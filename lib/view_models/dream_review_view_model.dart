import 'package:flutter/foundation.dart';
import '../data/models/dream_entry.dart';
import '../data/local/local_database.dart';

import 'dart:developer';

class ReviewViewModel extends ChangeNotifier {
  List<DreamEntry> _dreams = [];
  bool _isLoading = false;

  List<DreamEntry> get dreams => _dreams;
  bool get isLoading => _isLoading;

  Future<void> loadDreams() async {
    _isLoading = true;
    notifyListeners();

    try {
      _dreams = await LocalDatabase.instance.fetchDreamEntries();
    } catch (e) {
      log("ERROR LOADING DREAMS: $e");
      _dreams = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}