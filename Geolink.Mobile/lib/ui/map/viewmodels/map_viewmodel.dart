import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/location_repository.dart';
import '../../../data/repositories/friendship_repository.dart';
import '../../../domain/models/location.dart';
import '../../../domain/models/friend.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class MapUiState {
  final Location? currentUserLocation;
  /// Метаданные друзей (имя, аватар, статус) — источник: REST API.
  final List<Friend> friends;
  /// Позиции друзей (координаты) — источник: SignalR.
  final Map<String, Location> friendLocations;
  final Friend? selectedFriend;
  final bool isLoading;
  final String? error;

  const MapUiState({
    this.currentUserLocation,
    this.friends = const [],
    this.friendLocations = const {},
    this.selectedFriend,
    this.isLoading = false,
    this.error,
  });

  MapUiState copyWith({
    Location? currentUserLocation,
    List<Friend>? friends,
    Map<String, Location>? friendLocations,
    Friend? Function()? selectedFriend,
    bool? isLoading,
    String? Function()? error,
  }) {
    return MapUiState(
      currentUserLocation: currentUserLocation ?? this.currentUserLocation,
      friends: friends ?? this.friends,
      friendLocations: friendLocations ?? this.friendLocations,
      selectedFriend: selectedFriend != null ? selectedFriend() : this.selectedFriend,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final mapViewModelProvider = NotifierProvider<MapViewModel, MapUiState>(
  MapViewModel.new,
);

// ── ViewModel ─────────────────────────────────────────────────────────────────

class MapViewModel extends Notifier<MapUiState> {
  StreamSubscription<Location>? _friendLocationSub;
  StreamSubscription<Location>? _ownLocationSub;

  LocationRepository get _locationRepo => ref.read(locationRepositoryProvider);
  FriendshipRepository get _friendshipRepo => ref.read(friendshipRepositoryProvider);

  @override
  MapUiState build() {
    ref.onDispose(_dispose);
    // Асинхронная инициализация после синхронного возврата начального состояния
    Future.microtask(_initialize);
    return const MapUiState(isLoading: true);
  }

  // ── Инициализация ──────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    try {
      // 1. Устанавливаем SignalR-соединение
      await _locationRepo.connect();

      // 2. Загружаем список друзей из REST API параллельно с получением позиции
      final results = await Future.wait([
        _friendshipRepo.getFriends(),
        _locationRepo.getCurrentUserLocationOnce(),
      ]);

      state = state.copyWith(
        friends: results[0] as List<Friend>,
        currentUserLocation: results[1] as Location,
        isLoading: false,
      );

      // 3. Подписываемся на real-time потоки
      _subscribeToFriendLocations();
      _subscribeToOwnLocation();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'Не удалось загрузить данные: $e',
      );
    }
  }

  void _subscribeToFriendLocations() {
    // Каждое событие из SignalR — обновление записи в Map по userId.
    _friendLocationSub = _locationRepo.getFriendLocationUpdates().listen((loc) {
      final updated = Map<String, Location>.from(state.friendLocations);
      updated[loc.userId] = loc;
      state = state.copyWith(friendLocations: updated);
    });
  }

  void _subscribeToOwnLocation() {
    _ownLocationSub = _locationRepo.getCurrentUserLocation().listen((loc) {
      state = state.copyWith(currentUserLocation: loc);
      // Бродкастим нашу позицию друзьям через SignalR
      _locationRepo.broadcastMyLocation(loc.latitude, loc.longitude);
    });
  }

  // ── Commands (вызываются из View) ──────────────────────────────────────────

  /// Пользователь нажал на маркер друга → показываем карточку.
  void onFriendMarkerTapped(String userId) {
    final friend = state.friends.firstWhere((f) => f.userId == userId);
    state = state.copyWith(selectedFriend: () => friend);
  }

  /// Пользователь закрыл карточку друга.
  void dismissFriendCard() {
    state = state.copyWith(selectedFriend: () => null);
  }

  void _dispose() {
    _friendLocationSub?.cancel();
    _ownLocationSub?.cancel();
  }
}
