class UserLocation {
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  const UserLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });
}
