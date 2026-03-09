import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/models/friend.dart';
import '../../../domain/models/location.dart';

/// Карточка друга, выезжающая снизу при нажатии на его маркер.
class FriendLocationSheet extends StatelessWidget {
  final Friend friend;
  /// Позиция друга — приходит из SignalR, может отсутствовать до первого обновления.
  final Location? friendLocation;
  final Location? currentUserLocation;
  final VoidCallback onClose;

  const FriendLocationSheet({
    super.key,
    required this.friend,
    this.friendLocation,
    required this.currentUserLocation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Заголовок: аватар + имя + статус + кнопка закрытия
          Row(
            children: [
              _Avatar(name: friend.displayName),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusDot(status: friend.onlineStatus),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel(friend.onlineStatus),
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Плитка с расстоянием и временем последнего обновления
          if (currentUserLocation != null && friendLocation != null)
            _DistanceTile(
              distanceKm: _haversineKm(currentUserLocation!, friendLocation!),
              updatedAt: friendLocation!.updatedAt,
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'online' => 'В сети',
        'away' => 'Отошёл',
        _ => 'Не в сети',
      };

  static double _haversineKm(Location a, Location b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(a.latitude)) * cos(_rad(b.latitude)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  static double _rad(double deg) => deg * pi / 180;
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    return CircleAvatar(
      radius: 30,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ── Status Dot ────────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'online' => Colors.green,
      'away' => Colors.orange,
      _ => Colors.grey,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Distance Tile ─────────────────────────────────────────────────────────────

class _DistanceTile extends StatelessWidget {
  final double distanceKm;
  final DateTime updatedAt;

  const _DistanceTile({required this.distanceKm, required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    final distanceText = distanceKm < 1
        ? '${(distanceKm * 1000).round()} м от вас'
        : '${distanceKm.toStringAsFixed(1)} км от вас';

    final minutes = DateTime.now().difference(updatedAt).inMinutes;
    final timeText = minutes == 0 ? 'только что' : '$minutes мин. назад';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(distanceText, style: const TextStyle(fontSize: 15)),
          ),
          Text(
            timeText,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
