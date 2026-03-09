import 'package:flutter/material.dart';

import '../ui/map/views/map_view.dart';

class GeolinkApp extends StatelessWidget {
  const GeolinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geolink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapView(),
    );
  }
}
