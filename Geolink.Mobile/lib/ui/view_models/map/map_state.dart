import '../../../data/models/friend.dart';
import '../../../data/models/location.dart';

class MapState {
  final Location? currentUserLocation;
  final List<Friend> friends;
  final List<Location> friendLocations;
  final Friend? selectedFriend;
  final bool isLoading;
  final String? error;

  const MapState({
    this.currentUserLocation,
    this.friends = const [],
    this.friendLocations = const [],
    this.selectedFriend,
    this.isLoading = false,
    this.error,
  });

  MapState applyState({
    Location? currentUserLocation,
    List<Friend>? friends,
    List<Location>? friendLocations,
    Friend? selectedFriend,
    bool? isLoading,
    String? error,
    bool clearSelectedFriend = false,
    bool clearError = false,
  }) {
    return MapState(
      currentUserLocation: currentUserLocation ?? this.currentUserLocation,
      friends: friends ?? this.friends,
      friendLocations: friendLocations ?? this.friendLocations,
      selectedFriend: clearSelectedFriend ? null : (selectedFriend ?? this.selectedFriend),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
