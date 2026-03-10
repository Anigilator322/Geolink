import 'package:flutter/foundation.dart';

class ProfileViewModel extends ChangeNotifier {
  bool isEditing = false;
  String username = 'Тимофеев Игнат';
  String bio = 'Информация о пользователе, подробное описание профиля.';
  String? avatarUrl;

  void startEditing() {
    isEditing = true;
    notifyListeners();
  }

  void saveProfile({required String newUsername, required String newBio}) {
    username = newUsername;
    bio = newBio;
    isEditing = false;
    notifyListeners();
  }

  void cancelEditing() {
    isEditing = false;
    notifyListeners();
  }
}
