import 'package:flutter/foundation.dart';
import '../../../data/models/friend.dart';
import '../../../data/models/location.dart';
import 'map_state.dart';

class MapViewModel extends ChangeNotifier {
  static const List<Friend> _mockFriends = [
    Friend(
      userId: '1',
      displayName: 'Anastasia',
      avatarUrl: '',
      bio: 'Coffee and city walks',
    ),
    Friend(
      userId: '2',
      displayName: 'Anatoly',
      avatarUrl: '',
      bio: 'Cycling around town',
    ),
    Friend(
      userId: '3',
      displayName: 'Boris',
      avatarUrl: '',
      bio: 'Always near the river',
    ),
  ];

  MapState state = const MapState(isLoading: false);

  Future<void> initialize() async {
    final now = DateTime.now();
    final mockLocations = [
      Location(
        userId: '1',
        latitude: 56.5010,
        longitude: 84.9815,
        updatedAt: now,
      ),
      Location(
        userId: '2',
        latitude: 56.4925,
        longitude: 84.9680,
        updatedAt: now,
      ),
      Location(
        userId: '3',
        latitude: 56.5063,
        longitude: 84.9578,
        updatedAt: now,
      ),
    ];

    state = state.applyState(
      isLoading: false,
      friends: _mockFriends,
      friendLocations: mockLocations,
      clearSelectedFriend: true,
      clearError: true,
    );
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
