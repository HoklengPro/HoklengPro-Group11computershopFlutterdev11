import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL for the Drogon C++ backend.
///
/// Override at build/run time:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8848`
abstract final class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) {
      return _override;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8848';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8848';
    }
    return 'http://127.0.0.1:8848';
  }

  static Uri uri(String path) => Uri.parse('$baseUrl$path');
}
