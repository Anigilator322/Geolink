// MOCK — замените на реальные Dio-запросы с json_serializable.
//
// В продакшне метод getFriends будет выглядеть примерно так:
//   final response = await _apiClient.get('/api/friends');
//   return (response.data as List).map(FriendDto.fromJson).toList();
//
// JWT подставляется автоматически через interceptor в ApiClient —
// FriendApiService не знает о токене напрямую.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final friendApiServiceProvider = Provider<FriendApiService>((ref) {
  return FriendApiService(ref.read(apiClientProvider));
});

class FriendDto {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String onlineStatus;

  const FriendDto({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.onlineStatus,
  });
}

class FriendApiService {
  final ApiClient _apiClient;

  FriendApiService(this._apiClient);

  Future<List<FriendDto>> getFriends() async {
    // MOCK: вызов проходит через ApiClient, который логирует
    // Authorization: Bearer <token> — видно в консоли.
    await _apiClient.get('/api/friends');

    // MOCK: возвращаем захардкоженных друзей
    return const [
      FriendDto(userId: 'friend_1', displayName: 'Алексей Смирнов', onlineStatus: 'online'),
      FriendDto(userId: 'friend_2', displayName: 'Мария Иванова', onlineStatus: 'online'),
      FriendDto(userId: 'friend_3', displayName: 'Дмитрий Жуков', onlineStatus: 'away'),
    ];
  }
}
