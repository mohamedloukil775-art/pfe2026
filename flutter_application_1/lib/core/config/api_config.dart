class ApiConfig {
  // Change cette URL selon ton environnement
  // Émulateur Android: http://10.0.2.2:5000
  // iOS Simulator: http://localhost:5000
  // Appareil réel: http://192.168.x.x:5000 (IP de ton PC)
  static const String baseUrl = 'http://localhost:5000/api';
  
  static const Duration timeout = Duration(seconds: 30);
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String playersEndpoint = '/players';
  static const String teamsEndpoint = '/teams';
  static const String matchesEndpoint = '/matches';
  static const String standingsEndpoint = '/standings';
  static const String tournamentsEndpoint = '/tournaments';
  static const String clubsEndpoint = '/clubs';
}
