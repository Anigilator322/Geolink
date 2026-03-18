import 'package:geolink_mobile/data/services/realtime/geolink_hub_service.dart';

import '../models/friend.dart';
import '../models/incoming_friend_request.dart';
import '../services/api/friends_api_service.dart';

class FriendsRepository {
  FriendsRepository({FriendsApiService? apiService, GeolinkHubService? hubService})
    : _apiService = apiService ?? FriendsApiService(),
      _hubService = hubService ?? GeolinkHubService();

  final FriendsApiService _apiService;
  final GeolinkHubService _hubService;

  Stream<FriendRequestNotification> get friendRequestReceived =>
      _hubService.friendRequestReceived;

  Future<List<Friend>> getFriends() {
    return _apiService.getFriends();
  }

  Future<List<IncomingFriendRequest>> getPendingRequests() {
    return _apiService.getPendingRequests();
  }

  Future<void> sendFriendRequest({required String username}) {
    return _apiService.sendFriendRequest(username: username);
  }

  Future<void> acceptFriendRequest({required String friendshipId}) {
    return _apiService.acceptFriendRequest(friendshipId: friendshipId);
  }
}
