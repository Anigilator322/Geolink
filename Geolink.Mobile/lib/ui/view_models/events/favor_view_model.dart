import 'package:flutter/foundation.dart';

class FavorViewModel extends ChangeNotifier {
  final List<dynamic> myEvents = [];
  final List<dynamic> invitations = [];
}
class InvitationItem {
  final String name;
  final String date;
  final bool accepted; 

  const InvitationItem({
    required this.name,
    required this.date,
    required this.accepted,
  });
}