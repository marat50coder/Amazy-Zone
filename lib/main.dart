import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Immersive full-screen for the whole lifecycle (status/nav bar hidden).
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: const <SystemUiOverlay>[],
  );
  runApp(const AmazyZoneApp());
}

class AmazyZoneApp extends StatelessWidget {
  const AmazyZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amazy Zone',
      debugShowCheckedModeBanner: false,
      theme: AmazyTheme.themeData,
      home: const SplashScreen(),
    );
  }
}
