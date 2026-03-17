import '../models/friend.dart';
import '../models/incoming_friend_request.dart';
import '../services/api/friends_api_service.dart';

class FriendsRepository {
  FriendsRepository({FriendsApiService? apiService})
    : _apiService = apiService ?? FriendsApiService();

  final FriendsApiService _apiService;

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
