/// Google Maps SDK configuration notes.
///
/// Native API keys are required (the map widget does not read Dart-only keys).
///
/// **Android** — add to `android/local.properties`:
/// ```
/// GOOGLE_MAPS_API_KEY=AIzaSy...
/// ```
///
/// **iOS** — set the same key in `ios/Runner/AppDelegate.swift`:
/// `GMSServices.provideAPIKey("AIzaSy...")`
///
/// Enable in Google Cloud Console:
/// - Maps SDK for Android
/// - Maps SDK for iOS
abstract final class GoogleMapsConfig {
  /// Default map center when no store coordinates exist (Phnom Penh).
  static const double defaultLat = 11.5564;
  static const double defaultLng = 104.9282;
  static const double defaultZoom = 12.5;
}
