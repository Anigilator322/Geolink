class User {
  final String id;
  final String email;
  final String userName;
  final String bio;
  final String avatarUrl;
  final String createdAt;
  final String updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.userName,
    required this.bio,
    required this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });
}
