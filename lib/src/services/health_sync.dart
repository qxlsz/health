import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health_app/src/models/health_data.dart';
import 'package:health_app/src/services/supabase_client.dart';
import 'package:health_app/src/services/hive_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for syncing health data from various sources to Supabase
class HealthSyncService {
  /// Sync sleep session to Supabase
  Future<void> syncSleepSession({
    required SleepSession session,
    required String deviceId,
  }) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Convert sleep session to JSONB format for Supabase
      final sleepData = {
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime.toIso8601String(),
        'stages': session.stages.map((s) => s.toJson()).toList(),
        'efficiency': session.calculateEfficiency(),
        'total_sleep_minutes': session.totalDuration,
        'rem_percentage': session.getStagePercentage('REM'),
        'deep_percentage': session.getStagePercentage('DEEP'),
        'light_percentage': session.getStagePercentage('LIGHT'),
      };

      // Upsert to Supabase (update if exists, insert if not)
      await SupabaseService.client.from('health_metrics').upsert({
        'id': session.id,
        'device_id': deviceId,
        'user_id': userId,
        'timestamp': session.startTime.toIso8601String(),
        'type': 'sleep',
        'data': sleepData,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Also cache locally for offline support
      await HiveService.cacheSleepSession(session);

      if (kDebugMode) {
        print('Successfully synced sleep session: ${session.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing sleep session: $e');
      }
      rethrow;
    }
  }

  /// Sync multiple sleep sessions in batch
  Future<void> syncMultipleSleepSessions({
    required List<SleepSession> sessions,
    required String deviceId,
  }) async {
    for (var session in sessions) {
      try {
        await syncSleepSession(session: session, deviceId: deviceId);
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        if (kDebugMode) {
          print('Error syncing session ${session.id}: $e');
        }
        // Continue with other sessions
      }
    }
  }

  /// Register or update device in Supabase
  Future<String> registerDevice({
    required String type,
    required String? name,
    String? token, // OAuth token or other auth token
  }) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if device already exists
      final existing = await SupabaseService.client
          .from('devices')
          .select()
          .eq('user_id', userId)
          .eq('type', type)
          .maybeSingle();

      String deviceId;
      if (existing != null) {
        // Update existing device
        deviceId = existing['id'] as String;
        await SupabaseService.client.from('devices').update({
          'name': name,
          'token': token, // In production, encrypt this
          'last_sync_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', deviceId);
      } else {
        // Create new device
        final response = await SupabaseService.client.from('devices').insert({
          'user_id': userId,
          'type': type,
          'name': name,
          'token': token, // In production, encrypt this
          'last_sync_at': DateTime.now().toIso8601String(),
        }).select();
        
        deviceId = response.first['id'] as String;
      }

      return deviceId;
    } catch (e) {
      if (kDebugMode) {
        print('Error registering device: $e');
      }
      rethrow;
    }
  }

  /// Sync data from HealthKit (iOS)
  Future<void> syncFromHealthKit({
    required List<SleepSession> sessions,
    String? deviceName,
  }) async {
    if (!Platform.isIOS) {
      throw UnsupportedError('HealthKit is only available on iOS');
    }

    try {
      // Register iOS device
      final deviceId = await registerDevice(
        type: 'apple',
        name: deviceName ?? 'Apple Watch',
      );

      // Sync all sessions
      await syncMultipleSleepSessions(
        sessions: sessions,
        deviceId: deviceId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sync data from Health Connect (Android)
  Future<void> syncFromHealthConnect({
    required List<SleepSession> sessions,
    String? deviceName,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Health Connect is only available on Android');
    }

    try {
      // Register Android device
      final deviceId = await registerDevice(
        type: 'android',
        name: deviceName ?? 'Android Wear',
      );

      // Sync all sessions
      await syncMultipleSleepSessions(
        sessions: sessions,
        deviceId: deviceId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sync data from Whoop
  Future<void> syncFromWhoop({
    required List<SleepSession> sessions,
    String? accessToken,
  }) async {
    try {
      // Register Whoop device
      final deviceId = await registerDevice(
        type: 'whoop',
        name: 'Whoop',
        token: accessToken,
      );

      // Sync all sessions
      await syncMultipleSleepSessions(
        sessions: sessions,
        deviceId: deviceId,
      );
    } catch (e) {
      rethrow;
    }
  }
}
