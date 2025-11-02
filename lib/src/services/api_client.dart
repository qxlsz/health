import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:health_app/src/models/health_data.dart';

/// API client for Whoop OAuth and data fetching
class WhoopApiClient {
  static const String baseUrl = 'https://api.prod.whoop.com';
  static const String authUrl = 'https://api.prod.whoop.com/oauth/token';

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  WhoopApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptor for automatic token refresh
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          // Token expired, try to refresh
          _refreshAccessToken().then((_) {
            // Retry the request
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $_accessToken';
            _dio.request(
              opts.path,
              options: Options(
                method: opts.method,
                headers: opts.headers,
              ),
              data: opts.data,
              queryParameters: opts.queryParameters,
            ).then((response) => handler.resolve(response));
          }).catchError((e) => handler.reject(error));
        } else {
          handler.next(error);
        }
      },
    ));
  }

  /// Get OAuth authorization URL
  String getAuthorizationUrl() {
    final clientId = dotenv.env['WHOOP_CLIENT_ID'] ?? '';
    final redirectUri = dotenv.env['WHOOP_REDIRECT_URI'] ?? 'http://localhost:8080/callback';
    
    return 'https://api.prod.whoop.com/oauth/authorize?'
        'client_id=$clientId&'
        'response_type=code&'
        'redirect_uri=$redirectUri&'
        'scope=read:workout read:recovery read:sleep';
  }

  /// Exchange authorization code for access token
  Future<void> exchangeCodeForToken(String code) async {
    final clientId = dotenv.env['WHOOP_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['WHOOP_CLIENT_SECRET'] ?? '';
    final redirectUri = dotenv.env['WHOOP_REDIRECT_URI'] ?? 'http://localhost:8080/callback';

    try {
      final response = await _dio.post(
        authUrl,
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': redirectUri,
        },
      );

      _accessToken = response.data['access_token'] as String;
      _refreshToken = response.data['refresh_token'] as String;
      final expiresIn = response.data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    } catch (e) {
      throw Exception('Failed to exchange code for token: $e');
    }
  }

  /// Refresh access token
  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final clientId = dotenv.env['WHOOP_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['WHOOP_CLIENT_SECRET'] ?? '';

    try {
      final response = await _dio.post(
        authUrl,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      _accessToken = response.data['access_token'] as String;
      _refreshToken = response.data['refresh_token'] as String;
      final expiresIn = response.data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
    }
  }

  /// Get current user ID
  Future<String> getCurrentUserId() async {
    try {
      final response = await _dio.get('/oauth/user/profile/basic');
      return response.data['user']['id'].toString();
    } catch (e) {
      throw Exception('Failed to get user ID: $e');
    }
  }

  /// Fetch sleep data from Whoop
  Future<List<SleepSession>> fetchSleepData({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated. Please complete OAuth flow first.');
    }

    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final response = await _dio.get(
        '/v1/user/$userId/sleep',
        queryParameters: {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      );

      final sleepData = response.data as List;
      return sleepData.map((data) => _parseWhoopSleepData(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch sleep data: $e');
    }
  }

  /// Parse Whoop sleep data into SleepSession
  SleepSession _parseWhoopSleepData(Map<String, dynamic> data) {
    final id = data['id'].toString();
    final startTime = DateTime.parse(data['start'] as String);
    final endTime = DateTime.parse(data['end'] as String);
    
    // Parse sleep stages from Whoop format
    final stages = <SleepStage>[];
    final cycles = data['cycles'] as List? ?? [];
    
    for (var cycle in cycles) {
      final stage = cycle['stage'] as String?;
      final duration = cycle['duration'] as int? ?? 0;
      
      String stageType = 'LIGHT';
      if (stage == 'awake') {
        stageType = 'AWAKE';
      } else if (stage == 'deep') {
        stageType = 'DEEP';
      } else if (stage == 'rem') {
        stageType = 'REM';
      }
      
      stages.add(SleepStage(
        type: stageType,
        duration: duration ~/ 60, // Convert seconds to minutes
        startTime: startTime.add(Duration(seconds: cycle['start'] as int? ?? 0)),
        endTime: startTime.add(Duration(seconds: (cycle['start'] as int? ?? 0) + duration)),
      ));
    }

    // Calculate total sleep (excluding awake time)
    final totalSleepMinutes = stages
        .where((s) => s.type != 'AWAKE')
        .fold(0, (sum, stage) => sum + stage.duration);

    final efficiency = data['score'] as num?;
    
    return SleepSession(
      id: id,
      startTime: startTime,
      endTime: endTime,
      stages: stages,
      efficiency: efficiency?.toDouble(),
      totalSleepMinutes: totalSleepMinutes,
      deviceType: 'whoop',
    );
  }

  /// Set access token directly (for storing/retrieving from secure storage)
  void setAccessToken(String token, String refreshToken, DateTime expiry) {
    _accessToken = token;
    _refreshToken = refreshToken;
    _tokenExpiry = expiry;
  }

  /// Check if token is expired
  bool get isTokenExpired {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }
}
