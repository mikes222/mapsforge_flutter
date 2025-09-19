import 'package:complete_example/models/app_models.dart';
import 'package:flutter/material.dart';

class CurrentConfigurationCard extends StatelessWidget {
  final AppConfiguration _currentConfiguration;

  const CurrentConfigurationCard({super.key, required AppConfiguration currentConfiguration}) : _currentConfiguration = currentConfiguration;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Configuration', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Renderer', _currentConfiguration.rendererType.displayName),
            if (_currentConfiguration.renderTheme != null) _buildInfoRow(context, 'Theme', _currentConfiguration.renderTheme!.displayName),
            _buildInfoRow(context, 'Location', _currentConfiguration.location.toString()),
            _buildInfoRow(context, 'Map File', _currentConfiguration.location.url),
            _buildInfoRow(
              context,
              'Coordinates',
              '${_currentConfiguration.location.centerLatitude.toStringAsFixed(4)}, ${_currentConfiguration.location.centerLongitude.toStringAsFixed(4)}',
            ),
            //            Text(_currentConfiguration!.configurationSummary),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
