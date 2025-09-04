/// Data models for the mapsforge complete example app

enum RendererType {
  offline('Mapfile Offline Renderer'),
  openStreetMap('OpenStreetMap Online Renderer'),
  arcGisMaps('ArcGis Online Renderer');

  const RendererType(this.displayName);
  final String displayName;

  bool get isOffline => this == RendererType.offline;
  bool get isOnline => !isOffline;
}

//////////////////////////////////////////////////////////////////////////////

enum RenderTheme {
  defaultTheme('Default Theme', 'assets/render_theme/defaultrender.xml'),
  darkTheme('Dark Theme', 'assets/render_theme/darkrender.xml'),
  mapsforgeTheme('Maspforge Default Theme', 'assets/render_theme/mapsforge_default.xml'),
  siziliaTheme('Sicilia Hillshading Theme', 'assets/render_theme/sicilia_oam.xml');

  const RenderTheme(this.displayName, this.fileName);
  final String displayName;
  final String fileName;
}

class MapLocation {
  final String name;
  final String description;
  final String url;
  final double centerLatitude;
  final double centerLongitude;
  final int defaultZoomLevel;
  final String country;

  const MapLocation({
    required this.name,
    required this.description,
    required this.url,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.defaultZoomLevel,
    required this.country,
  });

  @override
  String toString() => '$name, $country';

  String getLocalfilename() {
    return url.split('/').last;
  }
}

class AppConfiguration {
  final RendererType rendererType;
  final RenderTheme? renderTheme;
  final MapLocation location;

  const AppConfiguration({required this.rendererType, this.renderTheme, required this.location});

  AppConfiguration copyWith({RendererType? rendererType, RenderTheme? renderTheme, MapLocation? location}) {
    return AppConfiguration(rendererType: rendererType ?? this.rendererType, renderTheme: renderTheme ?? this.renderTheme, location: location ?? this.location);
  }

  bool get isValid {
    if (rendererType.isOffline && renderTheme == null) {
      return false;
    }
    return true;
  }

  String get configurationSummary {
    final buffer = StringBuffer();
    buffer.writeln('Renderer: ${rendererType.displayName}');
    if (renderTheme != null) {
      buffer.writeln('Theme: ${renderTheme!.displayName}');
    }
    buffer.writeln('Location: ${location.name}, ${location.country}');
    return buffer.toString();
  }

  static AppConfiguration getDefaultConfiguration() {
    return AppConfiguration(rendererType: RendererType.offline, location: MapLocations.defaultLocation, renderTheme: RenderTheme.defaultTheme);
  }
}

/// Predefined map locations with their corresponding map files
class MapLocations {
  static const List<MapLocation> availableLocations = [
    MapLocation(
      name: 'Monaco',
      description: 'Monaco city-state with detailed street mapping',
      url: 'https://dailyflightbuddy.com/mapsforge_examples/monaco2.map',
      centerLatitude: 43.7384,
      centerLongitude: 7.4246,
      defaultZoomLevel: 15,
      country: 'Monaco',
    ),
    MapLocation(
      name: 'Berlin',
      description: 'German capital with comprehensive urban mapping',
      url: 'berlin.map',
      centerLatitude: 52.5200,
      centerLongitude: 13.4050,
      defaultZoomLevel: 12,
      country: 'Germany',
    ),
    MapLocation(
      name: 'Paris',
      description: 'French capital with detailed metropolitan area',
      url: 'paris.map',
      centerLatitude: 48.8566,
      centerLongitude: 2.3522,
      defaultZoomLevel: 12,
      country: 'France',
    ),
    MapLocation(
      name: 'Austria',
      description: 'No kangoroos',
      url: 'https://dailyflightbuddy.com/mapsforge_examples/austria.map',
      centerLatitude: 48.089415,
      centerLongitude: 16.311374,
      defaultZoomLevel: 12,
      country: 'South of vienna',
    ),
    MapLocation(
      name: 'Chemnitz',
      description: 'Chemnitz Uni indoor map',
      url: 'https://dailyflightbuddy.com/mapsforge_examples/Chemnitz Uni.map',
      centerLatitude: 50.81348,
      centerLongitude: 12.92936,
      defaultZoomLevel: 18,
      country: 'Germany',
    ),
    MapLocation(
      name: 'Sachsen',
      description: 'Sachsen',
      url: 'https://dailyflightbuddy.com/mapsforge_examples/sachsen.map',
      centerLatitude: 50.81287701030895,
      centerLongitude: 12.94189453125,
      defaultZoomLevel: 12,
      country: 'Germany',
    ),
    MapLocation(
      name: 'Berlin',
      description: 'Berlin',
      url: 'https://dailyflightbuddy.com/mapsforge_examples/berlin.map',
      centerLatitude: 52.52278,
      centerLongitude: 13.38982,
      defaultZoomLevel: 17,
      country: 'Germany',
    ),
    MapLocation(
      name: 'Louvre',
      description: 'Louvre (indoor)',
      url: 'https://dailyflightbuddy.com/mapsforge_examples/Louvre.map',
      centerLatitude: 48.86085,
      centerLongitude: 2.33665,
      defaultZoomLevel: 16,
      country: 'France',
    ),
    MapLocation(
      name: 'Paris',
      description: 'ile-de-france',
      url: 'https://dailyflightbuddy.com/mapsforge_examples/ile-de-france.map',
      centerLatitude: 48.86085,
      centerLongitude: 2.33665,
      defaultZoomLevel: 12,
      country: 'France',
    ),
    MapLocation(
      name: 'Sizilia',
      description: 'Contour Sizilia (hillshading)',
      url: 'https://dailyflightbuddy.com/mapsforge_examples/sicilia_oam.zip',
      centerLatitude: 37.5,
      centerLongitude: 14.3,
      defaultZoomLevel: 15,
      country: 'Italy',
    ),
    MapLocation(
      name: 'World',
      description: 'Worldmap',
      url: 'https://dailyflightbuddy.com/mapsforge_examples/world.map',
      centerLatitude: 40,
      centerLongitude: 10,
      defaultZoomLevel: 4,
      country: 'World',
    ),
  ];

  static MapLocation get defaultLocation => availableLocations.first;

  static MapLocation? findByName(String name) {
    try {
      return availableLocations.firstWhere((location) => location.name == name);
    } catch (e) {
      return null;
    }
  }

  static List<MapLocation> getLocationsByCountry(String country) {
    return availableLocations.where((location) => location.country == country).toList();
  }

  static List<String> get availableCountries {
    return availableLocations.map((location) => location.country).toSet().toList()..sort();
  }
}
