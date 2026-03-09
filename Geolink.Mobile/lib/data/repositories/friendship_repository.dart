import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api/friend_api_service.dart';
import '../../domain/models/friend.dart';

final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  return FriendshipRepository(ref.read(friendApiServiceProvider));
});

/// Получает список друзей через REST API.
/// Возвращает только метаданные ([Имя], [аватар], [статус]).
/// Позиции друзей являются отдельным источником данных и приходят через [LocationRepository].
class FriendshipRepository {
  final FriendApiService _apiService;

  FriendshipRepository(this._apiService);

  Future<List<Friend>> getFriends() async {
    final dtos = await _apiService.getFriends();
    return dtos.map((dto) => Friend(
      userId: dto.userId,
      displayName: dto.displayName,
      avatarUrl: dto.avatarUrl,
      onlineStatus: dto.onlineStatus,
    )).toList();
  }
}
