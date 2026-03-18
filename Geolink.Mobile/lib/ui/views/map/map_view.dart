import 'dart:async';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon, Animation;
import 'package:yandex_maps_mapkit/yandex_map.dart';
import 'package:yandex_maps_mapkit/mapkit_factory.dart';
import 'package:yandex_maps_mapkit/image.dart' as mapkiti;
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit_anim;

import '../../view_models/map/map_view_model.dart';
import '../../view_models/profile/profile_view_model.dart';
import '../../view_models/events/events_view_model.dart';
import '../../view_models/events/favor_view_model.dart';
import '../../view_models/friends/friends_view_model.dart';

import '../profile/profile_sheet.dart';
import '../events/events_sheet.dart';
import '../events/favor_sheet.dart';
import '../friends/friends_sheet.dart';
import 'widgets/friend_card.dart';
import 'widgets/event_detail_card.dart';

enum _ActiveSheet { none, events, favor, friends, profile }

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with WidgetsBindingObserver {
  MapWindow? _mapWindow;
  Timer? _zoomTimer;
  EventItem? _selectedEvent;

  _ActiveSheet _activeSheet = _ActiveSheet.none;
  int _selectedIndex = 0;
  static const double _sheetHeight = 600;

  late final MapViewModel _mapViewModel;
  late final EventsViewModel _eventsViewModel;
  late final FavorViewModel _favorViewModel;
  late final FriendsViewModel _friendsViewModel;
  late final ProfileViewModel _profileViewModel;

  MapObjectCollection? _friendPlacemarks;
  MapObjectCollection? _eventPlacemarks;
  MapObjectCollection? _currentUserPlacemark;
  bool _hasLocationPermission = false;

  late final _friendPinImage = mapkiti.ImageProvider.fromImageProvider(
    const AssetImage('assets/icon/pin.png'),
  );
  late final _eventPinImage = mapkiti.ImageProvider.fromImageProvider(
    const AssetImage('assets/icon/pin2.png'),
  );
  late final _currentUserPinImage = mapkiti.ImageProvider.fromImageProvider(
    const AssetImage('assets/icon/icon.png'),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initViewModels();
    unawaited(_initializeMapViewModel());
    unawaited(_initializeScreen());
  }
  Future<void> _initializeScreen() async {
    await Future.wait([_initializeMapViewModel(), _profileViewModel.loadProfile(),]);
  }
  void _initViewModels() {
    _mapViewModel = MapViewModel();
    _eventsViewModel = EventsViewModel();
    _favorViewModel = FavorViewModel();
    _friendsViewModel = FriendsViewModel();
    _profileViewModel = ProfileViewModel();
  }

  Future<void> _initializeMapViewModel() async {
    final permissionStatus = await _requestLocationPermissionIfNeeded();
    final hasLocationPermission = _isLocationPermissionGranted(
      permissionStatus,
    );
    _hasLocationPermission = hasLocationPermission;

    await _mapViewModel.initialize(
      enableCurrentLocationTracking: hasLocationPermission,
    );

    if (!mounted) return;
    if (!hasLocationPermission) {
      _showLocationPermissionSnackbar(permissionStatus);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncLocationPermissionAfterResume());
    }
  }

  Future<void> _syncLocationPermissionAfterResume() async {
    final status = await Permission.location.status;
    final isGranted = _isLocationPermissionGranted(status);
    if (isGranted == _hasLocationPermission) {
      return;
    }

    _hasLocationPermission = isGranted;

    if (isGranted) {
      await _mapViewModel.enableCurrentUserLocationTracking();
      return;
    }

    await _mapViewModel.disableCurrentUserLocationTracking();
    if (!mounted) return;
    _showLocationPermissionSnackbar(status);
  }

  Future<PermissionStatus> _requestLocationPermissionIfNeeded() async {
    final status = await Permission.location.status;
    if (_isLocationPermissionGranted(status) || status.isPermanentlyDenied) {
      return status;
    }

    if (status.isDenied) {
      return Permission.location.request();
    }

    return status;
  }

  bool _isLocationPermissionGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }

  void _showLocationPermissionSnackbar(PermissionStatus status) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Location access is disabled. Your marker and centering are unavailable.',
        ),
        action: SnackBarAction(
          label: status.isPermanentlyDenied ? 'Settings' : 'Allow',
          onPressed: status.isPermanentlyDenied
              ? openAppSettings
              : () => unawaited(_retryLocationPermission()),
        ),
      ),
    );
  }

  Future<void> _retryLocationPermission() async {
    final status = await Permission.location.request();
    final isGranted = _isLocationPermissionGranted(status);
    _hasLocationPermission = isGranted;

    if (isGranted) {
      await _mapViewModel.enableCurrentUserLocationTracking();
      return;
    }

    if (!mounted) return;
    _showLocationPermissionSnackbar(status);
  }

  void _onEventMarkerTapped(EventItem event) {
    setState(() {
      _selectedEvent = event;
      _activeSheet = _ActiveSheet.none;
    });
  }

  void _dismissEventCard() {
    setState(() => _selectedEvent = null);
  }

  @override
  void dispose() {
    _eventsViewModel.removeListener(_renderEventPlacemarks);
    _mapViewModel.removeListener(_syncMapWithState);
    _zoomTimer?.cancel();
    _mapViewModel.dispose();
    _eventsViewModel.dispose();
    _favorViewModel.dispose();
    _friendsViewModel.dispose();
    _profileViewModel.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncMapWithState() {
    _updateFriendPlacemarks();
    _updateCurrentUserPlacemark();
  }

  void _moveZoom(double step) {
    if (_mapWindow == null) return;
    final current = _mapWindow!.map.cameraPosition;
    _mapWindow!.map.move(
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

  void _centerOnCurrentUser() {
    if (_mapWindow == null) return;

    final currentLocation = _mapViewModel.state.currentUserLocation;
    if (currentLocation == null) return;

    final currentCamera = _mapWindow!.map.cameraPosition;
    _mapWindow!.map.move(
      CameraPosition(
        Point(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
        ),
        zoom: currentCamera.zoom,
        azimuth: currentCamera.azimuth,
        tilt: currentCamera.tilt,
      ),
      animation: mapkit_anim.Animation(
        type: AnimationType.Linear,
        duration: 0.25,
      ),
    );
  }

  void _startZooming(double step) {
    _moveZoom(step);
    _zoomTimer?.cancel();
    _zoomTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _moveZoom(step),
    );
  }

  void _stopZooming() => _zoomTimer?.cancel();

  void _onNavItemTap(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 1:
          _activeSheet = _ActiveSheet.events;
          break;
        case 2:
          _activeSheet = _ActiveSheet.favor;
          break;
        case 3:
          _activeSheet = _ActiveSheet.friends;
          break;
        case 4:
          _activeSheet = _ActiveSheet.profile;
          break;
        default:
          _activeSheet = _ActiveSheet.none;
      }
    });
      if (index == 4) {unawaited(_profileViewModel.loadProfile());}
  }

  void _closeAllSheets() {
    setState(() {
      _activeSheet = _ActiveSheet.none;
      _selectedIndex = 0;
    });
  }

  void _updateFriendPlacemarks() {
    if (_mapWindow == null) return;

    _friendPlacemarks ??= _mapWindow!.map.mapObjects.addCollection();
    _friendPlacemarks!.clear();

    for (final loc in _mapViewModel.state.friendLocations) {
      final friend = _mapViewModel.state.friends
          .where((f) => f.userId == loc.userId)
          .firstOrNull;

      final placemark = _friendPlacemarks!.addPlacemark()
        ..geometry = Point(latitude: loc.latitude, longitude: loc.longitude)
        ..setIcon(_friendPinImage)
        ..setIconStyle(
          IconStyle(anchor: math.Point(0.5, 1.0), scale: 2.5, zIndex: 10.0),
        );

      if (friend != null) {
        placemark.setText(friend.displayName);
        placemark.setTextStyle(
          mapkit_anim.TextStyle(
            placement: mapkit_anim.TextStylePlacement.Top,
            outlineColor: Colors.white,
            outlineWidth: 1.0,
            offset: 4.0,
          ),
        );
      }

      placemark.addTapListener(
        _PlacemarkTapListener(
          userId: loc.userId,
          onTap: _mapViewModel.onFriendMarkerTapped,
        ),
      );
    }
  }

  void _renderEventPlacemarks() {
    if (_mapWindow == null) return;

    _eventPlacemarks ??= _mapWindow!.map.mapObjects.addCollection();
    _eventPlacemarks!.clear();

    for (final event in _eventsViewModel.events) {
      final placemark = _eventPlacemarks!.addPlacemark()
        ..geometry = Point(latitude: event.latitude, longitude: event.longitude)
        ..setIcon(_eventPinImage)
        ..setIconStyle(
          IconStyle(anchor: math.Point(0.5, 1.0), scale: 2.5, zIndex: 5.0),
        );

      placemark.setText(event.name);
      placemark.setTextStyle(
        mapkit_anim.TextStyle(
          placement: mapkit_anim.TextStylePlacement.Top,
          outlineColor: Colors.white,
          outlineWidth: 1.0,
          offset: 4.0,
        ),
      );

      placemark.addTapListener(
        _EventTapListener(onTap: () => _onEventMarkerTapped(event)),
      );
    }
  }

  void _updateCurrentUserPlacemark() {
    if (_mapWindow == null) return;

    _currentUserPlacemark ??= _mapWindow!.map.mapObjects.addCollection();
    _currentUserPlacemark!.clear();

    final currentLocation = _mapViewModel.state.currentUserLocation;
    if (currentLocation == null) {
      return;
    }

    final placemark = _currentUserPlacemark!.addPlacemark()
      ..geometry = Point(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
      )
      ..setIcon(_currentUserPinImage)
      ..setIconStyle(
        IconStyle(anchor: math.Point(0.5, 0.5), scale: 2, zIndex: 20.0),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildMap(),
          _buildZoomControls(),
          _buildCurrentUserCenterButton(),
          _buildFriendCard(),
          if (_selectedEvent != null) _buildEventCard(_selectedEvent!),
          _buildSheet(_ActiveSheet.events),
          _buildSheet(_ActiveSheet.favor),
          _buildSheet(_ActiveSheet.friends),
          _buildSheet(_ActiveSheet.profile),
          _buildNavBar(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return YandexMap(
      onMapCreated: (mapWindow) {
        _mapWindow = mapWindow;
        mapkit.onStart();
        _mapWindow!.map.move(
          CameraPosition(
            const Point(latitude: 56.4977, longitude: 84.9744),
            zoom: 12.0,
            azimuth: 0.0,
            tilt: 0.0,
          ),
        );
        _renderEventPlacemarks();
        _eventsViewModel.addListener(_renderEventPlacemarks);
        _mapViewModel.addListener(_syncMapWithState);
        _syncMapWithState();
      },
    );
  }

  Widget _buildEventCard(EventItem event) {
    final screenHeight = MediaQuery.of(context).size.height;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
        child: EventDetailCard(
          event: event,
          onClose: _dismissEventCard,
          onShowOnMap: _dismissEventCard,
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ZoomButton(
              icon: Icons.add,
              onTapDown: () => _startZooming(0.5),
              onTapUp: _stopZooming,
            ),
            const SizedBox(height: 12),
            _ZoomButton(
              icon: Icons.remove,
              onTapDown: () => _startZooming(-0.5),
              onTapUp: _stopZooming,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserCenterButton() {
    return Positioned(
      right: 16,
      bottom: 76,
      child: ListenableBuilder(
        listenable: _mapViewModel,
        builder: (context, _) {
          final hasLocation = _mapViewModel.state.currentUserLocation != null;
          return GestureDetector(
            onTap: hasLocation ? _centerOnCurrentUser : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.my_location,
                color: hasLocation ? Colors.black87 : Colors.black38,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendCard() {
    return ListenableBuilder(
      listenable: _mapViewModel,
      builder: (context, _) {
        final selected = _mapViewModel.state.selectedFriend;
        if (selected == null) return const SizedBox.shrink();
        return Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: FriendCard(
            friend: selected,
            onDismiss: _mapViewModel.dismissFriendCard,
          ),
        );
      },
    );
  }

  Widget _buildSheet(_ActiveSheet sheet) {
    final isVisible = _activeSheet == sheet;

    Widget child;
    switch (sheet) {
      case _ActiveSheet.events:
        child = EventsSheet(
          onClose: () => setState(() => _activeSheet = _ActiveSheet.none),
          viewModel: _eventsViewModel,
          onEventTap: (event) {
            setState(() {
              _activeSheet = _ActiveSheet.none;
              _selectedEvent = event;
            });
          },
        );
        break;
      case _ActiveSheet.favor:
        child = FavorSheet(
          onClose: _closeAllSheets,
          viewModel: _favorViewModel,
        );
        break;
      case _ActiveSheet.friends:
        child = FriendsSheet(
          onClose: _closeAllSheets,
          viewModel: _friendsViewModel,
        );
        break;
      case _ActiveSheet.profile:
        child = ProfileSheet(
          onClose: _closeAllSheets,
          viewModel: _profileViewModel,
        );
        break;
      case _ActiveSheet.none:
        return const SizedBox.shrink();
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: isVisible ? 60 : -_sheetHeight,
      child: SizedBox(height: _sheetHeight, child: child),
    );
  }

  Widget _buildNavBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
              _NavItem(
                assetPath: 'assets/icon/мероприятия.svg',
                index: 1,
                selectedIndex: _selectedIndex,
                onTap: _onNavItemTap,
              ),
              _NavItem(
                assetPath: 'assets/icon/избр.svg',
                index: 2,
                selectedIndex: _selectedIndex,
                onTap: _onNavItemTap,
              ),
              _NavItem(
                assetPath: 'assets/icon/друзья.svg',
                index: 3,
                selectedIndex: _selectedIndex,
                onTap: _onNavItemTap,
              ),
              _NavItem(
                assetPath: 'assets/icon/профиль.svg',
                index: 4,
                selectedIndex: _selectedIndex,
                onTap: _onNavItemTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String assetPath;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.assetPath,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: SvgPicture.asset(
        assetPath,
        width: 60,
        height: 60,
        colorFilter: ColorFilter.mode(
          isSelected ? const Color(0xFF2E7D32) : Colors.black,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _ZoomButton({
    required this.icon,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }
}

class _PlacemarkTapListener implements MapObjectTapListener {
  final String userId;
  final void Function(String userId) onTap;

  _PlacemarkTapListener({required this.userId, required this.onTap});

  @override
  bool onMapObjectTap(MapObject mapObject, Point point) {
    onTap(userId);
    return true;
  }
}

class _EventTapListener implements MapObjectTapListener {
  final VoidCallback onTap;

  _EventTapListener({required this.onTap});

  @override
  bool onMapObjectTap(MapObject mapObject, Point point) {
    onTap();
    return true;
  }
}
