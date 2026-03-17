class Friend {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final String bio;

  const Friend({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    final userId = (json['userId'] ?? json['id'] ?? '').toString();
    final displayName = (json['username'] ?? json['displayName'] ?? '')
        .toString();
    final avatarUrl = (json['avatarUrl'] ?? '').toString();
    final bio = (json['bio'] ?? '').toString();

    return Friend(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
    );
  }
}
