import 'package:flutter/foundation.dart';

import '../../../data/repositories/friends_repository.dart';

class FriendListItem {
  final String userId;
  final String displayName;
  final String bio;
  final String? friendshipRequestId;

  const FriendListItem({
    required this.userId,
    required this.displayName,
    required this.bio,
    this.friendshipRequestId,
  });
}

class FriendsViewModel extends ChangeNotifier {
  FriendsViewModel({FriendsRepository? repository})
    : _repository = repository ?? FriendsRepository();

  final FriendsRepository _repository;

  List<FriendListItem> myFriends = const [];
  List<FriendListItem> incomingRequests = const [];

  bool isLoading = false;
  bool isSendingRequest = false;
  bool isSearching = false;
  bool _isInitialized = false;

  String? errorMessage;

  List<FriendListItem> searchResults = [];

  Future<void> load({bool force = false}) async {
    if (isLoading) {
      return;
    }

    if (_isInitialized && !force) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final friends = await _repository.getFriends();
      final pendingRequests = await _repository.getPendingRequests();

      myFriends = friends
          .map(
            (friend) => FriendListItem(
              userId: friend.userId,
              displayName: friend.displayName,
              bio: friend.bio,
            ),
          )
          .toList();

      incomingRequests = pendingRequests
          .map(
            (request) => FriendListItem(
              userId: request.issuerId,
              displayName: request.issuerUsername,
              bio: '',
              friendshipRequestId: request.id,
            ),
          )
          .toList();

      _isInitialized = true;
      _syncSearchResults();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void startSearch() {
    isSearching = true;
    _syncSearchResults();
    notifyListeners();
  }

  void stopSearch() {
    isSearching = false;
    searchResults = [];
    notifyListeners();
  }

  void onSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }

    final candidates = [...myFriends, ...incomingRequests];
    searchResults = candidates
        .where((user) => user.displayName.toLowerCase().contains(normalized))
        .toList();
    notifyListeners();
  }

  Future<String?> sendFriendRequestByUsername(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      return 'Username is required.';
    }

    if (isSendingRequest) {
      return null;
    }

    isSendingRequest = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.sendFriendRequest(username: normalized);
      await load(force: true);
      return null;
    } catch (e) {
      final message = e.toString();
      errorMessage = message;
      return message;
    } finally {
      isSendingRequest = false;
      notifyListeners();
    }
  }

  Future<String?> acceptFriendRequest(FriendListItem request) async {
    final requestId = request.friendshipRequestId;
    if (requestId == null || requestId.isEmpty) {
      return 'Friend request id is missing.';
    }

    try {
      await _repository.acceptFriendRequest(friendshipId: requestId);
      incomingRequests = incomingRequests
          .where((item) => item.friendshipRequestId != requestId)
          .toList();
      _syncSearchResults();
      notifyListeners();
      await load(force: true);
      return null;
    } catch (e) {
      final message = e.toString();
      errorMessage = message;
      notifyListeners();
      return message;
    }
  }

  void dismissIncomingRequest(FriendListItem request) {
    final requestId = request.friendshipRequestId;
    if (requestId == null || requestId.isEmpty) {
      return;
    }

    incomingRequests = incomingRequests
        .where((item) => item.friendshipRequestId != requestId)
        .toList();
    _syncSearchResults();
    notifyListeners();
  }

  void _syncSearchResults() {
    if (!isSearching) {
      searchResults = [];
      return;
    }

    searchResults = [...myFriends, ...incomingRequests];
  }
}
