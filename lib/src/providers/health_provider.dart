import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/src/models/health_data.dart';
import 'package:health_app/src/services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for user's sleep sessions
final sleepSessionsProvider = FutureProvider<List<SleepSession>>((ref) async {
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    final response = await SupabaseService.client
        .from('health_metrics')
        .select('*, devices(*)')
        .eq('user_id', userId)
        .eq('type', 'sleep')
        .order('timestamp', ascending: false)
        .limit(30); // Last 30 sleep sessions

    return (response as List).map((item) {
      final data = item['data'] as Map<String, dynamic>;
      final device = item['devices'] as Map<String, dynamic>?;

      // Parse stages from JSONB data
      final stagesJson = data['stages'] as List? ?? [];
      final stages = stagesJson
          .map((s) => SleepStage.fromJson(s as Map<String, dynamic>))
          .toList();

      return SleepSession(
        id: item['id'] as String,
        startTime: DateTime.parse(data['start_time'] as String),
        endTime: DateTime.parse(data['end_time'] as String),
        stages: stages,
        efficiency: (data['efficiency'] as num?)?.toDouble(),
        totalSleepMinutes: data['total_sleep_minutes'] as int?,
        deviceId: item['device_id'] as String?,
        deviceType: device?['type'] as String?,
      );
    }).toList();
  } catch (e) {
    // Return empty list on error (will be handled by UI)
    return [];
  }
});

/// Provider for user's connected devices
final devicesProvider = FutureProvider<List<Device>>((ref) async {
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    final response = await SupabaseService.client
        .from('devices')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((item) {
      return Device(
        id: item['id'] as String,
        userId: item['user_id'] as String,
        type: item['type'] as String,
        name: item['name'] as String?,
        lastSyncAt: item['last_sync_at'] != null
            ? DateTime.parse(item['last_sync_at'] as String)
            : null,
        createdAt: DateTime.parse(item['created_at'] as String),
      );
    }).toList();
  } catch (e) {
    return [];
  }
});

/// Provider for sleep summary statistics
final sleepSummaryProvider = FutureProvider<SleepSummary>((ref) async {
  final sessionsAsync = await ref.watch(sleepSessionsProvider.future);
  return SleepSummary.fromSessions(sessionsAsync);
});

/// Summary statistics for sleep data
class SleepSummary {
  final double averageEfficiency;
  final int averageDuration; // minutes
  final double averageRemPercentage;
  final double averageDeepPercentage;
  final int totalSessions;
  final List<SleepSession> recentSessions;

  SleepSummary({
    required this.averageEfficiency,
    required this.averageDuration,
    required this.averageRemPercentage,
    required this.averageDeepPercentage,
    required this.totalSessions,
    required this.recentSessions,
  });

  factory SleepSummary.fromSessions(List<SleepSession> sessions) {
    if (sessions.isEmpty) {
      return SleepSummary(
        averageEfficiency: 0.0,
        averageDuration: 0,
        averageRemPercentage: 0.0,
        averageDeepPercentage: 0.0,
        totalSessions: 0,
        recentSessions: [],
      );
    }

    final totalEfficiency = sessions
        .map((s) => s.calculateEfficiency())
        .fold(0.0, (sum, eff) => sum + eff);
    final totalDuration =
        sessions.fold(0, (sum, s) => sum + s.totalDuration);
    final totalRem = sessions
        .map((s) => s.getStagePercentage('REM'))
        .fold(0.0, (sum, p) => sum + p);
    final totalDeep = sessions
        .map((s) => s.getStagePercentage('DEEP'))
        .fold(0.0, (sum, p) => sum + p);

    return SleepSummary(
      averageEfficiency: totalEfficiency / sessions.length,
      averageDuration: totalDuration ~/ sessions.length,
      averageRemPercentage: totalRem / sessions.length,
      averageDeepPercentage: totalDeep / sessions.length,
      totalSessions: sessions.length,
      recentSessions: sessions.take(7).toList(), // Last week
    );
  }
}

