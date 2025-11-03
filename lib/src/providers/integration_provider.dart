import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app/src/services/healthkit_service.dart';
import 'package:health_app/src/services/health_connect_service.dart';
import 'package:health_app/src/services/api_client.dart';
import 'package:health_app/src/services/health_sync.dart';
import 'package:health_app/src/models/health_data.dart';
import 'package:health_app/src/providers/health_provider.dart';

/// Provider for HealthKit service
final healthKitServiceProvider = Provider<HealthKitService>((ref) {
  return HealthKitService();
});

/// Provider for Health Connect service
final healthConnectServiceProvider = Provider<HealthConnectService>((ref) {
  return HealthConnectService();
});

/// Provider for Whoop API client
final whoopApiClientProvider = Provider<WhoopApiClient>((ref) {
  return WhoopApiClient();
});

/// Provider for health sync service
final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  return HealthSyncService();
});

/// Provider for integration status
final integrationStatusProvider = StateNotifierProvider<IntegrationStatusNotifier, Map<String, bool>>((ref) {
  return IntegrationStatusNotifier();
});

class IntegrationStatusNotifier extends StateNotifier<Map<String, bool>> {
  IntegrationStatusNotifier() : super({
    'apple': false,
    'android': false,
    'whoop': false,
  });

  void setStatus(String type, bool connected) {
    state = {...state, type: connected};
  }
}

/// Provider for syncing Apple Watch data
final syncAppleWatchProvider = FutureProvider.autoDispose<void>((ref) async {
  final healthKit = ref.read(healthKitServiceProvider);
  final syncService = ref.read(healthSyncServiceProvider);

  // Request permissions
  final hasPermission = await healthKit.requestPermissions();
  if (!hasPermission) {
    throw Exception('HealthKit permissions not granted');
  }

  // Fetch sleep data
  final sessions = await healthKit.fetchSleepData();

  // Sync to Supabase
  await syncService.syncFromHealthKit(sessions: sessions);

  // Invalidate providers to refresh UI
  ref.invalidate(sleepSessionsProvider);
  ref.invalidate(devicesProvider);
});

/// Provider for syncing Android Wear data
final syncAndroidWearProvider = FutureProvider.autoDispose<void>((ref) async {
  final healthConnect = ref.read(healthConnectServiceProvider);
  final syncService = ref.read(healthSyncServiceProvider);

  // Request permissions
  final hasPermission = await healthConnect.requestPermissions();
  if (!hasPermission) {
    throw Exception('Health Connect permissions not granted');
  }

  // Fetch sleep data
  final sessions = await healthConnect.fetchSleepData();

  // Sync to Supabase
  await syncService.syncFromHealthConnect(sessions: sessions);

  // Invalidate providers to refresh UI
  ref.invalidate(sleepSessionsProvider);
  ref.invalidate(devicesProvider);
});

/// Provider for Whoop OAuth flow
final whoopOAuthProvider = FutureProvider.autoDispose<void>((ref) async {
  final whoopClient = ref.read(whoopApiClientProvider);
  final syncService = ref.read(healthSyncServiceProvider);

  // Get authorization URL
  final authUrl = whoopClient.getAuthorizationUrl();
  
  // In a real app, you'd open this URL in a webview/browser
  // and handle the callback to get the authorization code
  // For now, this is a placeholder
  throw UnimplementedError('Whoop OAuth flow needs to be implemented with webview');
});

