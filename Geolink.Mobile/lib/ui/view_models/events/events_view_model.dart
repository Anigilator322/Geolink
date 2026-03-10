import 'package:flutter/foundation.dart';

class EventItem {
  final String name;
  final String time;
  final String date;
  final double latitude;
  final double longitude;
  final String description;
  final String authorName;

  const EventItem({
    required this.name,
    required this.time,
    required this.date,
    required this.latitude,
    required this.longitude,
    this.description = '',
    this.authorName = '',
  });
}

class EventsViewModel extends ChangeNotifier {
  bool isAddingEvent = false;
  bool isPublic = true;

  final List<EventItem> events = const [
    EventItem(
      name: 'Выступление группы',
      time: '20:00 - 23:00',
      date: '18.02.2026',
      latitude: 56.4846,
      longitude: 84.9480,
      description: 'Живое выступление местной группы на центральной площади. Вход свободный, приходите с друзьями!',
      authorName: 'Николай Иванович',
    ),
  ];

  void showAddEvent() {
    isAddingEvent = true;
    notifyListeners();
  }

  void saveEvent() {
    isAddingEvent = false;
    notifyListeners();
  }

  void cancelAddEvent() {
    isAddingEvent = false;
    notifyListeners();
  }

  void setPublic(bool value) {
    isPublic = value;
    notifyListeners();
  }
}