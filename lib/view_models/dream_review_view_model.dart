import 'package:flutter/material.dart';
import '../data/models/dream_entry.dart';
import '../data/local/local_database.dart';

import 'dart:developer';

enum SortOrder { newest, oldest }

enum DreamFilterOption { newest, oldest, dateRange, clear }

class DreamReviewViewModel extends ChangeNotifier {
  List<DreamEntry> _allDreams = [];
  List<DreamEntry> _filteredDreams = [];

  String _searchQuery = '';
  SortOrder _currentSort = SortOrder.newest;
  DateTimeRange? _currentDateRange;
  bool _isLoading = false;

  List<DreamEntry> get dreams => _filteredDreams;
  bool get isLoading => _isLoading;
  SortOrder get currentSort => _currentSort;
  bool get hasNoDreams => _allDreams.isEmpty;

  Future<void> loadDreams() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allDreams = await LocalDatabase.instance.fetchDreamEntries();
      _filteredDreams = List.from(_allDreams);
      _applyFilters();
    } catch (e) {
      log("ERROR LOADING DREAMS: $e");
      _allDreams = [];
      _filteredDreams = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchDreams(String query) {
    _searchQuery = query.trim();
    _applyFilters();
  }

  void setSortOrder(SortOrder sort) {
    _currentSort = sort;
    _applyFilters();
  }

  void filterByDateRange(DateTime start, DateTime end) {
    _currentDateRange = DateTimeRange(
      start: start,
      end: end.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
    );
    _applyFilters();
  }

  void _applyFilters() {
    List<DreamEntry> temp = List.from(_allDreams);

    // search filter
    if (_searchQuery.isNotEmpty) {
      temp = temp.where((dream) {
        final title = dream.dreamTitle.toLowerCase() ?? "";
        final content = dream.dreamContent.toLowerCase() ?? "";
        final q = _searchQuery.toLowerCase();
        return title.contains(q) || content.contains(q);
      }).toList();
    }

    temp.sort((a, b) {
      DateTime dateA = a.updatedAt ?? DateTime.now();
      DateTime dateB = b.updatedAt ?? DateTime.now();

      if (_currentSort == SortOrder.newest) {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateB);
      }
    });

    if (_currentDateRange != null) {
      temp = temp.where((dream) {
        return dream.updatedAt.isAfter(_currentDateRange!.start) &&
            dream.updatedAt.isBefore(_currentDateRange!.end);
      }).toList();
    }

    _filteredDreams = temp;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _currentSort = SortOrder.newest;
    _currentDateRange = null;
    _applyFilters();

  }
}
