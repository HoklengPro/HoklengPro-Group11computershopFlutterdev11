/// Map settings — free tiles, no Google API key or billing required.
abstract final class MapConfig {
  static const double defaultLat = 11.5564;
  static const double defaultLng = 104.9282;
  static const double defaultZoom = 13.5;

  /// Carto basemap (OpenStreetMap data). Works reliably in mobile apps without a key.
  static const String tileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const List<String> tileSubdomains = ['a', 'b', 'c', 'd'];
}
