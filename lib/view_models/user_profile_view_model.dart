import 'package:flutter/foundation.dart';

import '../data/local/local_database.dart';
import '../data/models/user_profile.dart';

class UserProfileViewModel extends ChangeNotifier {
  UserProfileViewModel({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance;

  final LocalDatabase _database;

  UserProfile _profile = UserProfile.empty();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      var fetchedProfile = await _database.fetchUserProfile();
      if (_shouldSeedDemoProfile(fetchedProfile)) {
        fetchedProfile = await _database.upsertUserProfile(_demoProfile);
      }
      _profile = fetchedProfile;
    } catch (error, stackTrace) {
      debugPrint('Failed to load profile: $error\n$stackTrace');
      _profile = _demoProfile;
      _errorMessage = 'Unable to load profile. Showing demo details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile(UserProfile updatedProfile) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final savedProfile = await _database.upsertUserProfile(updatedProfile);
      _profile = savedProfile;
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to save profile: $error\n$stackTrace');
      _errorMessage = 'Unable to save profile. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  bool _shouldSeedDemoProfile(UserProfile profile) {
    return profile.fullName.isEmpty &&
        profile.email.isEmpty &&
        profile.phone.isEmpty;
  }

  UserProfile get _demoProfile => UserProfile(
        fullName: 'Jamie Walker',
        pronouns: 'they / them',
        birthday: '1995-08-16',
        email: 'jamie.walker@example.com',
        phone: '+1 202 555 0168',
        location: 'Seattle, WA',
        notes:
            'Loves ambient playlists before bed.\nReminders: breathe, hydrate, stretch.',
      );
}


