import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:health_app/src/models/health_data.dart';

/// Service for calling sleep analysis API
class AnalysisService {
  late final Dio _dio;
  final String _analysisUrl;

  AnalysisService() : _analysisUrl = dotenv.env['PYTHON_SERVICE_URL'] ?? 'http://localhost:8000' {
    _dio = Dio(
      BaseOptions(
        baseUrl: _analysisUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  /// Analyze a single sleep session
  Future<Map<String, dynamic>> analyzeSleepSession(SleepSession session) async {
    try {
      final sleepData = {
        'stages': session.stages.map((s) => s.toJson()).toList(),
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime.toIso8601String(),
      };

      final response = await _dio.post(
        '/analyze',
        data: sleepData,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Return default analysis on error
      return _defaultAnalysis(session);
    }
  }

  /// Analyze multiple sleep sessions for trends
  Future<Map<String, dynamic>> analyzeSleepTrends(
    List<SleepSession> sessions,
    {int days = 30}
  ) async {
    try {
      final sessionsData = sessions.map((s) {
        return {
          'stages': s.stages.map((stage) => stage.toJson()).toList(),
          'start_time': s.startTime.toIso8601String(),
          'end_time': s.endTime.toIso8601String(),
        };
      }).toList();

      final response = await _dio.post(
        '/analyze/trends',
        data: {
          'sessions': sessionsData,
          'days': days,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {
        'error': e.toString(),
        'weekly_averages': {},
        'correlations': {},
        'recommendations': [],
      };
    }
  }

  /// Check if analysis service is available
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Default analysis when service is unavailable
  Map<String, dynamic> _defaultAnalysis(SleepSession session) {
    final totalSleep = session.totalDuration;
    final remPercent = session.getStagePercentage('REM');
    final deepPercent = session.getStagePercentage('DEEP');
    final efficiency = session.calculateEfficiency();

    // Simple sleep score calculation
    final sleepScore = (efficiency * 0.4) +
        (remPercent * 0.3) +
        (deepPercent * 0.2) +
        (totalSleep >= 420 && totalSleep <= 540 ? 10 : 0);

    return {
      'efficiency': efficiency,
      'total_sleep_duration': totalSleep,
      'rem_percentage': remPercent,
      'deep_sleep_percentage': deepPercent,
      'light_sleep_percentage': session.getStagePercentage('LIGHT'),
      'awake_percentage': session.getStagePercentage('AWAKE'),
      'sleep_score': sleepScore.clamp(0.0, 100.0),
      'note': 'Client-side analysis (service unavailable)',
    };
  }
}

