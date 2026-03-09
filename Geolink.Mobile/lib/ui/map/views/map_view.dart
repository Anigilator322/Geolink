import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/map_viewmodel.dart';
import '../../../domain/models/friend.dart';
import '../../../domain/models/location.dart';
import 'friend_location_sheet.dart';

// ── Viewport (MOCK: ограничивающий прямоугольник над Москвой) ─────────────────
const _centerLat = 55.7558;
const _centerLng = 37.6173;
const _range = 0.06;

/// Переводит географические координаты в дробные [0..1] координаты экрана.
Offset _toFractional(double lat, double lng) {
  final x = (lng - (_centerLng - _range)) / (2 * _range);
  final y = 1.0 - (lat - (_centerLat - _range)) / (2 * _range); // Y инвертирован
  return Offset(x.clamp(0.05, 0.95), y.clamp(0.05, 0.95));
}

// ── MapView ───────────────────────────────────────────────────────────────────

class MapView extends ConsumerWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapViewModelProvider);
    final vm = ref.read(mapViewModelProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Фоновый макет карты (MOCK)
            const SizedBox.expand(child: _MockMapBackground()),

            // ── Слой маркеров (друзья + текущий пользователь)
            _MarkersLayer(
              friends: state.friends,
              friendLocations: state.friendLocations,
              currentUser: state.currentUserLocation,
              onFriendTap: vm.onFriendMarkerTapped,
            ),

            // ── HUD: счётчик друзей на карте
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _MapHud(friendCount: state.friends.length),
            ),

            // ── Экран загрузки
            if (state.isLoading)
              const ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // ── Баннер ошибки
            if (state.error != null)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: _ErrorBanner(message: state.error!),
              ),

            // ── Карточка друга (слайд снизу)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
              child: state.selectedFriend != null
                  ? Align(
                      key: ValueKey(state.selectedFriend!.userId),
                      alignment: Alignment.bottomCenter,
                      child: FriendLocationSheet(
                        friend: state.selectedFriend!,
                        friendLocation: state.friendLocations[state.selectedFriend!.userId],
                        currentUserLocation: state.currentUserLocation,
                        onClose: vm.dismissFriendCard,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mock Map Background ───────────────────────────────────────────────────────

class _MockMapBackground extends StatelessWidget {
  const _MockMapBackground();

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _MockMapPainter(),
        child: const SizedBox.expand(),
      );
}

class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Подложка
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFEAF0EA),
    );

    final blockPaint = Paint()
      ..color = const Color(0xFFD7E3D8)
      ..style = PaintingStyle.fill;

    final streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5;

    // Кварталы
    final blockSize = size.width / 5;
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < 6; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              col * blockSize + 5,
              row * blockSize + 5,
              blockSize - 10,
              blockSize - 10,
            ),
            const Radius.circular(4),
          ),
          blockPaint,
        );
      }
    }

    // Улицы (линии сетки)
    for (var i = 0; i <= 5; i++) {
      final x = i * blockSize;
      final y = i * blockSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), streetPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), streetPaint);
    }

    // Парк в центре
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: blockSize - 10,
          height: blockSize - 10,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFC8E6C9),
    );

    // Подпись MOCK
    const style = TextStyle(color: Color(0xFFB0BEC5), fontSize: 11);
    final tp = TextPainter(
      text: const TextSpan(text: 'MOCK MAP — заменить на YandexMapWidget', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(8, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Markers Layer ─────────────────────────────────────────────────────────────

class _MarkersLayer extends StatelessWidget {
  final List<Friend> friends;
  final Map<String, Location> friendLocations;
  final Location? currentUser;
  final void Function(String userId) onFriendTap;

  const _MarkersLayer({
    required this.friends,
    required this.friendLocations,
    required this.currentUser,
    required this.onFriendTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final markers = <Widget>[];

        // Маркеры друзей (только те, для кого есть позиция от SignalR)
        for (final f in friends) {
          final loc = friendLocations[f.userId];
          if (loc == null || loc.latitude == 0) continue;
          final frac = _toFractional(loc.latitude, loc.longitude);
          markers.add(
            AnimatedPositioned(
              key: ValueKey(f.userId),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              left: frac.dx * w - 22,
              top: frac.dy * h - 52,
              child: _FriendMarker(
                friend: f,
                onTap: () => onFriendTap(f.userId),
              ),
            ),
          );
        }

        // Маркер текущего пользователя
        if (currentUser != null) {
          final frac = _toFractional(currentUser!.latitude, currentUser!.longitude);
          markers.add(
            AnimatedPositioned(
              key: const ValueKey('me'),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left: frac.dx * w - 14, // центрируем (14 = половина 28px)
              top: frac.dy * h - 14,
              child: const _CurrentUserMarker(),
            ),
          );
        }

        return Stack(children: markers);
      },
    );
  }
}

// ── Friend Marker ─────────────────────────────────────────────────────────────

class _FriendMarker extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  static const _palette = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
  ];

  const _FriendMarker({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _palette[friend.userId.hashCode.abs() % _palette.length];
    final initials = friend.displayName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Кружок с инициалами
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Треугольник-пин
          CustomPaint(
            painter: _PinPainter(color: color),
            size: const Size(10, 8),
          ),
        ],
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;
  const _PinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.color != color;
}

// ── Current User Marker (пульсирующая точка) ──────────────────────────────────

class _CurrentUserMarker extends StatefulWidget {
  const _CurrentUserMarker();

  @override
  State<_CurrentUserMarker> createState() => _CurrentUserMarkerState();
}

class _CurrentUserMarkerState extends State<_CurrentUserMarker>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Пульсирующее кольцо
            Transform.scale(
              scale: 1 + _controller.value * 1.5,
              child: Opacity(
                opacity: 1 - _controller.value,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Основная точка
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HUD ───────────────────────────────────────────────────────────────────────

class _MapHud extends StatelessWidget {
  final int friendCount;
  const _MapHud({required this.friendCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Друзья на карте: $friendCount',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
