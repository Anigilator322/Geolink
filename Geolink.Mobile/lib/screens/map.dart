import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon, TextStyle, Animation;
import 'package:yandex_maps_mapkit/yandex_map.dart';
import 'package:yandex_maps_mapkit/mapkit_factory.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit_anim;
import 'profile.dart'; 
import 'friend.dart'; 
import 'events.dart'; 
import 'favor.dart'; 


enum ActiveSheet { none, events, favor, friends, profile }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  MapWindow? _mapWindow;
  int _selectedIndex = 0;
  Timer? _zoomTimer;
  final double _sheetHeight = 600;
  
  ActiveSheet _activeSheet = ActiveSheet.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _zoomTimer?.cancel(); 
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _moveZoom(double step) {
    if (_mapWindow != null) {
      final current = _mapWindow!.map.cameraPosition;
      _mapWindow?.map.move(
        CameraPosition(
          current.target,
          zoom: current.zoom + step,
          azimuth: current.azimuth,
          tilt: current.tilt,
        ),
        animation: mapkit_anim.Animation(
          type: AnimationType.Linear,
          duration: 0.1, 
        ),
      );
    }
  }

  void _startZooming(double step) {
    _moveZoom(step); 
    _zoomTimer?.cancel();
    _zoomTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _moveZoom(step);
    });
  }

  void _stopZooming() {
    _zoomTimer?.cancel();
  }

  void _closeAllSheets() {
    setState(() {
      _activeSheet = ActiveSheet.none;
      _selectedIndex = 0;
    });
  }

  void _onNavItemTap(int index) {
  setState(() {
     _selectedIndex = index; 
      switch (index) {
      case 1: _activeSheet = ActiveSheet.events; break;
      case 2: _activeSheet = ActiveSheet.favor; break;
      case 3: _activeSheet = ActiveSheet.friends; break;
      case 4: _activeSheet = ActiveSheet.profile; break;
      default: _activeSheet = ActiveSheet.none;
    }
  });
}

  Widget _buildNavItem(String assetPath, int index) {
    final bool isSelected = _selectedIndex == index;
    final Color iconColor = isSelected ? const Color(0xFF2E7D32) : Colors.black;

    return GestureDetector(
      onTap: () => _onNavItemTap(index),
      child: SvgPicture.asset(
        assetPath,
        width: 60,
        height: 60,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, double step) {
    return GestureDetector(
      onTapDown: (_) => _startZooming(step),
      onTapUp: (_) => _stopZooming(),
      onTapCancel: () => _stopZooming(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: (mapWindow) {
              _mapWindow = mapWindow;
              mapkit.onStart();
              _mapWindow?.map.move(
                CameraPosition(
                  const Point(latitude: 56.4977, longitude: 84.9744),
                  zoom: 12.0,
                  azimuth: 0.0,
                  tilt: 0.0,
                ),
              );
            },
          ),

          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildZoomButton(Icons.add, 0.5),
                  const SizedBox(height: 12),
                  _buildZoomButton(Icons.remove, -0.5),
                ],
              ),
            ),
          ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut, 
              left: 0,
              right: 0,
              bottom: _activeSheet == ActiveSheet.friends ? 60 : -_sheetHeight,
              child: SizedBox(
                height: _sheetHeight,
                child: FriendsSheet(onClose: _closeAllSheets),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: _activeSheet == ActiveSheet.favor ? 60 : -_sheetHeight,
              child: SizedBox(
                height: _sheetHeight,
                child: FavorSheet(onClose: _closeAllSheets),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: _activeSheet == ActiveSheet.events ? 60 : -_sheetHeight,
              child: SizedBox(
                height: _sheetHeight,
                child: EventsSheet(onClose: _closeAllSheets),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: _activeSheet == ActiveSheet.profile ? 60 : -_sheetHeight,
              child: SizedBox(
                height: _sheetHeight,
                child: ProfileSheet(onClose: _closeAllSheets),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem('assets/icon/мероприятия.svg', 1),
                    _buildNavItem('assets/icon/избр.svg', 2),
                    _buildNavItem('assets/icon/друзья.svg', 3),
                    _buildNavItem('assets/icon/профиль.svg', 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}