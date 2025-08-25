import 'package:flutter/material.dart';

import '../models/app_models.dart';

class ConfigurationScreen extends StatefulWidget {
  final AppConfiguration? initialConfiguration;
  final Function(AppConfiguration) onConfigurationChanged;

  const ConfigurationScreen({super.key, this.initialConfiguration, required this.onConfigurationChanged});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

//////////////////////////////////////////////////////////////////////////////

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  late RendererType _selectedRenderer;
  RenderTheme? _selectedTheme;
  late MapLocation _selectedLocation;

  @override
  void initState() {
    super.initState();
    _initializeConfiguration();
  }

  void _initializeConfiguration() {
    if (widget.initialConfiguration != null) {
      _selectedRenderer = widget.initialConfiguration!.rendererType;
      _selectedTheme = widget.initialConfiguration!.renderTheme;
      _selectedLocation = widget.initialConfiguration!.location;
    } else {
      _selectedRenderer = RendererType.offline;
      _selectedTheme = RenderTheme.defaultTheme;
      _selectedLocation = MapLocations.defaultLocation;
    }
  }

  void _updateConfiguration() {
    final config = AppConfiguration(
      rendererType: _selectedRenderer,
      renderTheme: _selectedRenderer.isOffline ? _selectedTheme : null,
      location: _selectedLocation,
    );

    if (config.isValid) {
      widget.onConfigurationChanged(config);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Configuration'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRendererSection(),
            const SizedBox(height: 24),
            if (_selectedRenderer.isOffline) ...[_buildRenderThemeSection(), const SizedBox(height: 24)],
            _buildLocationSection(),
            const SizedBox(height: 32),
            _buildConfigurationSummary(),
            const Spacer(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildRendererSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Renderer Type', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RendererType>(
              initialValue: _selectedRenderer,
              decoration: const InputDecoration(labelText: 'Select Renderer', border: OutlineInputBorder(), prefixIcon: Icon(Icons.map)),
              items: RendererType.values.map((renderer) {
                return DropdownMenuItem(
                  value: renderer,
                  child: Row(
                    children: [
                      Icon(renderer.isOffline ? Icons.offline_pin : Icons.cloud, size: 20, color: renderer.isOffline ? Colors.green : Colors.blue),
                      const SizedBox(width: 8),
                      Text(renderer.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (RendererType? value) {
                if (value != null) {
                  setState(() {
                    _selectedRenderer = value;
                    if (value.isOnline) {
                      _selectedTheme = null;
                    } else {
                      _selectedTheme ??= RenderTheme.defaultTheme;
                    }
                  });
                  _updateConfiguration();
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _selectedRenderer.isOffline ? 'Offline rendering uses local map files and themes' : 'Online rendering fetches tiles from remote servers',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenderThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Render Theme', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RenderTheme>(
              initialValue: _selectedTheme,
              decoration: const InputDecoration(labelText: 'Select Theme', border: OutlineInputBorder(), prefixIcon: Icon(Icons.color_lens)),
              items: RenderTheme.values.map((theme) {
                return DropdownMenuItem(
                  value: theme,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Text(theme.displayName),
                      Text(theme.fileName, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (RenderTheme? value) {
                if (value != null) {
                  setState(() {
                    _selectedTheme = value;
                  });
                  _updateConfiguration();
                }
              },
            ),
            const SizedBox(height: 8),
            Text('Themes control the visual appearance of offline maps', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Map Location', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MapLocation>(
              initialValue: _selectedLocation,
              decoration: const InputDecoration(labelText: 'Select Location', border: OutlineInputBorder(), prefixIcon: Icon(Icons.place)),
              items: MapLocations.availableLocations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Text('${location.name}, ${location.country}'),
                      Text(location.description, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (MapLocation? value) {
                if (value != null) {
                  setState(() {
                    _selectedLocation = value;
                  });
                  _updateConfiguration();
                }
              },
            ),
            const SizedBox(height: 8),
            Text('Map file: ${_selectedLocation.mapFileName}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
            const SizedBox(height: 4),
            Text(
              'Center: ${_selectedLocation.centerLatitude.toStringAsFixed(4)}, ${_selectedLocation.centerLongitude.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSummary() {
    final config = AppConfiguration(
      rendererType: _selectedRenderer,
      renderTheme: _selectedRenderer.isOffline ? _selectedTheme : null,
      location: _selectedLocation,
    );

    return Card(
      color: config.isValid ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  config.isValid ? Icons.check_circle : Icons.error,
                  color: config.isValid ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text('Configuration Summary', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(config.configurationSummary, style: Theme.of(context).textTheme.bodyMedium),
            if (!config.isValid) ...[
              const SizedBox(height: 8),
              Text(
                'Please select a render theme for offline rendering',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final config = AppConfiguration(
      rendererType: _selectedRenderer,
      renderTheme: _selectedRenderer.isOffline ? _selectedTheme : null,
      location: _selectedLocation,
    );

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: config.isValid
                ? () {
                    Navigator.of(context).pop();
                    widget.onConfigurationChanged(config);
                  }
                : null,
            icon: const Icon(Icons.map),
            label: const Text('Start Map View'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedRenderer = RendererType.offline;
                _selectedTheme = RenderTheme.defaultTheme;
                _selectedLocation = MapLocations.defaultLocation;
              });
              _updateConfiguration();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset to Defaults'),
          ),
        ),
      ],
    );
  }
}
