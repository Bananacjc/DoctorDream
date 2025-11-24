import 'package:flutter/foundation.dart';

import '../data/local/local_database.dart';
import '../data/models/support_contact.dart';

class ContactViewModel extends ChangeNotifier {
  ContactViewModel({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance;

  final LocalDatabase _database;

  List<SupportContact> _contacts = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<SupportContact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _database.fetchSupportContacts();
      _contacts = result;
    } catch (error, stackTrace) {
      debugPrint('Failed to load contacts: $error\n$stackTrace');
      _errorMessage = 'Unable to load contacts. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addContact({
    required String name,
    required String phone,
    String relationship = '',
  }) async {
    try {
      final savedContact = await _database.insertSupportContact(
        SupportContact(
          name: name,
          relationship: relationship,
          phone: phone,
        ),
      );
      _contacts = [savedContact, ..._contacts];
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to add contact: $error\n$stackTrace');
      return false;
    }
  }

  Future<bool> removeContact(SupportContact contact) async {
    final index = _contacts.indexWhere((element) => element.id == contact.id);
    if (index == -1) return true;

    final removed = _contacts[index];
    _contacts.removeAt(index);
    notifyListeners();

    final contactId = removed.id;
    if (contactId == null) return true;

    try {
      await _database.deleteSupportContact(contactId);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to delete contact: $error\n$stackTrace');
      _contacts.insert(index, removed);
      notifyListeners();
      return false;
    }
  }
}


