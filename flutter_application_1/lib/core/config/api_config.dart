import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  // Auto-detected: web & iOS → localhost, Android emulator → 10.0.2.2
  // For a real Android device, set _deviceHost below to your PC's local IP.
  static const String _deviceHost = '10.0.2.2'; // emulator; change to LAN IP for real phone

  static String get _host {
    if (kIsWeb) return 'localhost';
    if (defaultTargetPlatform == TargetPlatform.android) return _deviceHost;
    return 'localhost';
  }

  static String get baseUrl => 'http://$_host:5001/api';

  static const Duration timeout = Duration(seconds: 30);
  static String get storageUrl => '$baseUrl/storage';

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String playersEndpoint = '/players';
  static const String teamsEndpoint = '/teams';
  static const String matchesEndpoint = '/matches';
  static const String standingsEndpoint = '/standings';
  static const String tournamentsEndpoint = '/tournaments';
  static const String clubsEndpoint = '/clubs';
}
