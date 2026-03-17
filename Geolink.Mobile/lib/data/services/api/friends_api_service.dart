import 'package:dio/dio.dart';

import '../../models/friend.dart';
import '../../models/incoming_friend_request.dart';
import 'api_client.dart';

class FriendsApiService {
  FriendsApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Friend>> getFriends() async {
    try {
      final response = await _apiClient.dio.post('/friends');
      final payload = _extractList(response.data);
      print("getFriends payload: $payload");
      return payload
          .map(_toStringKeyMap)
          .map(Friend.fromJson)
          .where((friend) => friend.userId.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(e, fallback: 'Failed to load friends list.'),
      );
    }
  }

  Future<List<IncomingFriendRequest>> getPendingRequests() async {
    try {
      final response = await _apiClient.dio.post(
        '/friends/get-pending-requests',
      );
      final payload = _extractList(response.data);
      print("getPendingRequests payload: $payload");

      return payload
          .map(_toStringKeyMap)
          .map(
            (json) => IncomingFriendRequest(
              id: (json['id'] ?? '').toString(),
              issuerId: (json['issuerId'] ?? '').toString(),
              issuerUsername: (json['issuerUsername'] ?? '').toString(),
            ),
          )
          .where(
            (request) => request.id.isNotEmpty && request.issuerId.isNotEmpty,
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(
          e,
          fallback: 'Failed to load pending friend requests.',
        ),
      );
    }
  }

  Future<void> sendFriendRequest({required String username}) async {
    try {
      await _apiClient.dio.post(
        '/friends/send-request',
        data: <String, dynamic>{'addresseeUsername': username},
      );
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(e, fallback: 'Failed to send friend request.'),
      );
    }
  }

  Future<void> acceptFriendRequest({required String friendshipId}) async {
    try {
      await _apiClient.dio.post('/friends/accept', data: '"$friendshipId"');
    } on DioException catch (e) {
      throw Exception(
        ApiClient.extractError(e, fallback: 'Failed to accept friend request.'),
      );
    }
  }

  List<Object?> _extractList(Object? payload) {
    if (payload is List) {
      return payload.cast<Object?>();
    }
    return const <Object?>[];
  }

  Map<String, dynamic> _toStringKeyMap(Object? payload) {
    if (payload is! Map) {
      return const <String, dynamic>{};
    }

    return payload.map((key, value) => MapEntry(key.toString(), value));
  }
}
