import 'dart:developer';

import 'package:doctor_dream/data/local/local_database.dart';
import 'package:flutter/material.dart';

class DreamDetailViewModel extends ChangeNotifier {
  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

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
}