import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/dream_entry.dart';
import '../data/local/local_database.dart';

class DreamEditViewModel extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<bool> saveDream({
    required DreamEntry? originalEntry,
    required String dreamTitle,
    required String dreamContent,
  }) async {
    if (dreamTitle.isEmpty) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final entryToSave = DreamEntry(
        dreamID: originalEntry?.dreamID ?? '${Uuid().v4().substring(0, 6)
        }_123456',
        dreamTitle: dreamTitle,
        dreamContent: dreamContent,
        createdAt: originalEntry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        status: originalEntry?.status ?? DreamEntryStatus.completed,
        isFavourite: originalEntry?.isFavourite ?? false,
      );

      await LocalDatabase.instance.upsertDreamEntry(entryToSave);
      return true;
    } catch (e) {
      log("ERROR SAVING DREAM : $e");
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }


  }
}
