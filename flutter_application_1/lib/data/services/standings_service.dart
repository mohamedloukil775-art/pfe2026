import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/domain.dart';
import '../../core/config/api_config.dart';
import '../../core/storage/request_cache.dart';
import '../../core/storage/token_storage.dart';
import '../../core/exceptions/api_exceptions.dart';

class StandingsService {
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<PlayerStanding>> getStandings() async {
    try {
      final cached = RequestCache.get<List<PlayerStanding>>('standings:players');
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.standingsEndpoint}/players'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final standings = data.map((json) => PlayerStanding.fromJson(json)).toList();
        RequestCache.set('standings:players', standings, ttl: const Duration(seconds: 20));
        stopwatch.stop();
        debugPrint('Loaded standings in ${stopwatch.elapsedMilliseconds}ms');
        return standings;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement du classement', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger le classement: $e');
    }
  }

  Future<List<Reward>> getMonthlyTop3() async {
    try {
      final cached = RequestCache.get<List<Reward>>('standings:monthly-top3');
      if (cached != null) return cached;

      final stopwatch = Stopwatch()..start();
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.standingsEndpoint}/monthly-top3'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final rewards = data.map((json) => Reward.fromJson(json)).toList();
        RequestCache.set('standings:monthly-top3', rewards, ttl: const Duration(seconds: 20));
        stopwatch.stop();
        debugPrint('Loaded monthly top 3 in ${stopwatch.elapsedMilliseconds}ms');
        return rewards;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException();
      } else {
        throw ApiException('Erreur lors du chargement du top 3', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Impossible de charger le top 3: $e');
    }
  }
}
