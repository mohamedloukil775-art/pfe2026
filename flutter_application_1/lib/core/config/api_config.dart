import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  static const String _deviceHost = '192.168.1.21'; // IP du PC sur le WiFi

  static String get _host {
    if (kIsWeb) {
      // Utilise le même hôte que la page web :
      // PC (localhost:8080) → localhost:5001
      // Téléphone (192.168.1.116:8080) → 192.168.1.116:5001
      final pageHost = Uri.base.host;
      if (pageHost.isEmpty || pageHost == 'localhost' || pageHost == '127.0.0.1') {
        return 'localhost';
      }
      return pageHost;
    }
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
