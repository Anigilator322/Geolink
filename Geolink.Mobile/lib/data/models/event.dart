enum EventStatus { scheduled, active, completed, cancelled }

enum ParticipantStatus { pending, accepted, declined }

class EventSettings {
  final String startsAt;
  final String endsAt;
  final bool publicEvent;
  final int maxParticipants;
  final String previewUrl;
  final String description;
  final bool requireRegistration;
  final String address;
  final EventStatus status;

  const EventSettings({
    required this.startsAt,
    required this.endsAt,
    required this.publicEvent,
    required this.maxParticipants,
    required this.previewUrl,
    required this.description,
    required this.requireRegistration,
    required this.address,
    required this.status,
  });
}

class Event {
  final String id;
  final String creatorUserId;
  final double longitude;
  final double latitude;
  final String title;
  final String createdAt;
  final String updatedAt;
  final EventSettings settings;

  const Event({
    required this.id,
    required this.creatorUserId,
    required this.longitude,
    required this.latitude,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.settings,
  });
}
