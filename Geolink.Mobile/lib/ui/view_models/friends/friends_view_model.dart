import 'package:flutter/foundation.dart';

class FriendListItem {
  final String userId;
  final String displayName;
  final String bio;

  const FriendListItem({
    required this.userId,
    required this.displayName,
    required this.bio,
  });
}

class FriendsViewModel extends ChangeNotifier {
  final List<FriendListItem> myFriends = const [
    FriendListItem(userId: '1', displayName: 'Анастасия', bio: ''),
    FriendListItem(userId: '2', displayName: 'Анатолий', bio: ''),
    FriendListItem(userId: '3', displayName: 'Борис', bio: ''),
  ];

  final List<FriendListItem> incomingRequests = const [
    FriendListItem(userId: '5', displayName: 'Дмитрий', bio: ''),
  ];

  final List<FriendListItem> _allUsers = const [
    FriendListItem(userId: '1', displayName: 'Анастасия', bio: ''),
    FriendListItem(userId: '2', displayName: 'Анатолий', bio: ''),
    FriendListItem(userId: '5', displayName: 'Дмитрий', bio: ''),
    FriendListItem(userId: '6', displayName: 'Елена', bio: ''),
  ];

  bool isSearching = false;
  List<FriendListItem> searchResults = [];

  void startSearch() {
    isSearching = true;
    notifyListeners();
  }

  void stopSearch() {
    isSearching = false;
    searchResults = [];
    notifyListeners();
  }

  void onSearch(String query) {
    searchResults = query.isEmpty
        ? []
        : _allUsers
            .where((u) => u.displayName.toLowerCase().startsWith(query.toLowerCase()))
            .toList();
    notifyListeners();
  }
}
