import 'package:flutter/foundation.dart';
import '../../../data/models/friend.dart';
import 'map_state.dart';

class MapViewModel extends ChangeNotifier {
  MapState state = const MapState(isLoading: false);

  Future<void> initialize() async {
    state = state.applyState(isLoading: false);
    notifyListeners();
  }

  void onFriendMarkerTapped(String userId) {
    final friend = state.friends.firstWhere(
      (f) => f.userId == userId,
      orElse: () => Friend(userId: userId, displayName: '', avatarUrl: '', bio: ''),
    );
    state = state.applyState(selectedFriend: friend);
    notifyListeners();
  }

  void dismissFriendCard() {
    state = state.applyState(clearSelectedFriend: true);
    notifyListeners();
  }
}