import 'user_location.dart';

class FriendLocation {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final UserLocation location;
  final String onlineStatus;

  const FriendLocation({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.location,
    required this.onlineStatus,
  });

  FriendLocation copyWith({UserLocation? location}) {
    return FriendLocation(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      location: location ?? this.location,
      onlineStatus: onlineStatus,
    );
  }
}
