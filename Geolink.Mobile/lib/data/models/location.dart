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
