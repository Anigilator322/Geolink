import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../data/models/friend.dart';
import '../../../data/models/location.dart';
import '../../../data/repositories/location_repository.dart';
import 'map_state.dart';

class MapViewModel extends ChangeNotifier {
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

    state = state.applyState(
      friends: const [],
      friendLocations: const [],
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
      orElse: () => Friend(
        userId: userId,
        displayName: 'Friend ${_shortUserId(userId)}',
        avatarUrl: '',
        bio: '',
      ),
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

  String _shortUserId(String userId) {
    return userId.length > 8 ? userId.substring(0, 8) : userId;
  }

  @override
  void dispose() {
    unawaited(_friendLocationSubscription?.cancel());
    unawaited(_currentLocationSubscription?.cancel());
    unawaited(_locationRepository.dispose());
    super.dispose();
  }
}
