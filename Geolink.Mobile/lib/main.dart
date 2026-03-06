import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/email_screen.dart';
import 'screens/map.dart';
import 'package:yandex_maps_mapkit/init.dart' as init;

void main() async  {

  WidgetsFlutterBinding.ensureInitialized();

  await  init.initMapkit(
    apiKey: '2a1df122-2fe0-4b94-b143-313f1de7d81c',
    locale: 'ru_RU'
  ); 

  runApp(const GeoLinkApp());
}

class GeoLinkApp extends StatelessWidget {
  const GeoLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/email': (context) => const EmailAuthScreen(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}