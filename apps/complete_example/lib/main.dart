import 'package:complete_example/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MapsforgeOptimizedApp());
}

class MapsforgeOptimizedApp extends StatelessWidget {
  const MapsforgeOptimizedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapsforge Complete Example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: const MainNavigationScreen(),
    );
  }
}
