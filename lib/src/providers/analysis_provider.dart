import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/src/services/analysis_service.dart';
import 'package:health_app/src/models/health_data.dart';
import 'package:health_app/src/providers/health_provider.dart';

/// Provider for analysis service
final analysisServiceProvider = Provider<AnalysisService>((ref) {
  return AnalysisService();
});

/// Provider for analyzing a single sleep session
final analyzeSessionProvider = FutureProvider.family<Map<String, dynamic>, SleepSession>((ref, session) async {
  final analysisService = ref.read(analysisServiceProvider);
  return await analysisService.analyzeSleepSession(session);
});

/// Provider for analyzing sleep trends
final analyzeTrendsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final sessionsAsync = await ref.watch(sleepSessionsProvider.future);
  final analysisService = ref.read(analysisServiceProvider);
  
  if (sessionsAsync.isEmpty) {
    return {
      'weekly_averages': {},
      'correlations': {},
      'recommendations': ['No sleep data available. Connect a device to start tracking.'],
    };
  }
  
  return await analysisService.analyzeSleepTrends(sessionsAsync);
});

/// Provider for checking analysis service availability
final analysisServiceAvailableProvider = FutureProvider<bool>((ref) async {
  final analysisService = ref.read(analysisServiceProvider);
  return await analysisService.isAvailable();
});

