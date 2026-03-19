import 'package:flutter/foundation.dart';
import '../../../data/services/api/profile_api_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({ApiProfileService? profileService})
      : _profileService = profileService ?? ApiProfileService();

  final ApiProfileService _profileService;

  bool isEditing = false;
  bool isLoading = false;
  bool isSaving = false;

  String username = '';
  String bio = '';
  String? avatarUrl;
  String? error;

  Future<void> loadProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final profile = await _profileService.getProfile();
      username = profile.username;
      bio = profile.bio;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void startEditing() {
    error = null;
    isEditing = true;
    notifyListeners();
  }

  void cancelEditing() {
    error = null;
    isEditing = false;
    notifyListeners();
  }

  Future<bool> saveProfile({
    required String newUsername,
    required String newBio,
  }) async {
    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final updatedProfile = await _profileService.updateProfile(
        username: newUsername.trim(),
        bio: newBio.trim(),
      );

      username = updatedProfile.username;
      bio = updatedProfile.bio;
      isEditing = false;
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}