/// Метаданные друга: кто это, как выглядит, какой статус.
/// Не содержит позицию — координаты хранятся отдельно в [Location].
class Friend {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String onlineStatus;

  const Friend({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.onlineStatus,
  });
}
