import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../data/models/friend.dart';
import '../../../data/models/location.dart';
import '../../../data/repositories/location_repository.dart';
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

  MapViewModel({LocationRepository? locationRepository})
    : _locationRepository = locationRepository ?? LocationRepository();

  final LocationRepository _locationRepository;
  StreamSubscription<Location>? _friendLocationSubscription;
  StreamSubscription<Location>? _currentLocationSubscription;
  bool _isSendingLocation = false;

  MapState state = const MapState(isLoading: false);

  Future<void> initialize() async {
    state = state.applyState(isLoading: true, clearError: true);
    notifyListeners();

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
      friends: _mockFriends,
      friendLocations: mockLocations,
      clearSelectedFriend: true,
      clearError: true,
    );

    try {
      await _locationRepository.connectRealtime();

      await _friendLocationSubscription?.cancel();
      _friendLocationSubscription = _locationRepository.friendLocationUpdates
          .listen(_onFriendLocationUpdated);

      try {
        final currentLocation = await _locationRepository
            .getCurrentUserLocationOnce();
        state = state.applyState(currentUserLocation: currentLocation);
      } catch (_) {
        // Ignore GPS availability on initialization; realtime friend updates remain available.
      }

      await _currentLocationSubscription?.cancel();
      _currentLocationSubscription = _locationRepository
          .watchCurrentUserLocation(distanceFilterMeters: 0)
          .listen(_onCurrentUserLocationUpdated);

      state = state.applyState(isLoading: false);
    } catch (e) {
      state = state.applyState(
        isLoading: false,
        error: 'Realtime unavailable: ${e.toString()}',
      );
    }

    notifyListeners();
  }

  Future<void> sendCurrentLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _locationRepository.sendLocation(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      state = state.applyState(
        error: 'Failed to send location: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  void onFriendMarkerTapped(String userId) {
    final friend = state.friends.firstWhere(
      (f) => f.userId == userId,
      orElse: () =>
          Friend(userId: userId, displayName: '', avatarUrl: '', bio: ''),
    );
    state = state.applyState(selectedFriend: friend);
    notifyListeners();
  }

  void dismissFriendCard() {
    state = state.applyState(clearSelectedFriend: true);
    notifyListeners();
  }

  void _onFriendLocationUpdated(Location location) {
    final updatedLocations = [...state.friendLocations];
    final index = updatedLocations.indexWhere(
      (loc) => loc.userId == location.userId,
    );

    if (index >= 0) {
      updatedLocations[index] = location;
    } else {
      updatedLocations.add(location);
    }

    state = state.applyState(
      friendLocations: updatedLocations,
      clearError: true,
    );
    notifyListeners();
  }

  void _onCurrentUserLocationUpdated(Location location) {
    state = state.applyState(currentUserLocation: location, clearError: true);
    notifyListeners();
    unawaited(_sendLocationFromGpsEvent(location));
  }

  Future<void> _sendLocationFromGpsEvent(Location location) async {
    if (_isSendingLocation) {
      return;
    }

    _isSendingLocation = true;
    try {
      await _locationRepository.sendLocationModel(location);
    } catch (e) {
      state = state.applyState(
        error: 'Failed to sync location: ${e.toString()}',
      );
      notifyListeners();
    } finally {
      _isSendingLocation = false;
    }
  }

  @override
  void dispose() {
    unawaited(_friendLocationSubscription?.cancel());
    unawaited(_currentLocationSubscription?.cancel());
    unawaited(_locationRepository.dispose());
    super.dispose();
  }
}
