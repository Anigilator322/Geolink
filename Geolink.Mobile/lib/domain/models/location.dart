/// Географическая позиция пользователя в конкретный момент времени.
/// Используется как для своих координат, так и для координат друзей.
class Location {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  const Location({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });
}
