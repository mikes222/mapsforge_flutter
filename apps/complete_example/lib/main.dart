import 'package:flutter/material.dart';

import 'models/app_models.dart';
import 'screens/configuration_screen.dart';
import 'screens/map_view_screen.dart';

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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  AppConfiguration? _currentConfiguration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapsforge Complete Example'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mapsforge Flutter Showcase', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('This app demonstrates a complete mapsforge implementation:'),
                    const SizedBox(height: 8),
                    const Text('• Configurable offline/online renderers'),
                    const Text('• Multiple render themes for offline maps'),
                    const Text('• Location selection with corresponding map files'),
                    const Text('• Real-time performance monitoring'),
                    const Text('• Optimized geometric calculations with isolates'),
                    const Text('• Adaptive memory management'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_currentConfiguration != null) ...[CurrentConfigurationCard(currentConfiguration: _currentConfiguration), const SizedBox(height: 16)],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToConfiguration(),
                icon: const Icon(Icons.settings),
                label: Text(_currentConfiguration == null ? 'Configure Map Settings' : 'Change Configuration'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            if (_currentConfiguration != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToMapView(),
                  icon: const Icon(Icons.map),
                  label: const Text('Open Map View'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToConfiguration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfigurationScreen(
          initialConfiguration: _currentConfiguration,
          onConfigurationChanged: (config) {
            setState(() {
              _currentConfiguration = config;
            });
            _navigateToMapView();
          },
        ),
      ),
    );
  }

  void _navigateToMapView() {
    if (_currentConfiguration != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => MapViewScreen(configuration: _currentConfiguration!)));
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class CurrentConfigurationCard extends StatelessWidget {
  const CurrentConfigurationCard({super.key, required AppConfiguration? currentConfiguration}) : _currentConfiguration = currentConfiguration;

  final AppConfiguration? _currentConfiguration;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Configuration', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_currentConfiguration!.configurationSummary),
          ],
        ),
      ),
    );
  }
}
