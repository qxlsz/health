import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:health_app/src/models/health_data.dart';

/// Service for managing local Hive storage for offline support
class HiveService {
  static const String sleepSessionsBox = 'sleep_sessions';
  static const String devicesBox = 'devices';
  static bool _initialized = false;

  /// Initialize Hive with local storage
  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    // Register adapters (will be generated in build step)
    // For now, we'll use JSON storage

    _initialized = true;
  }

  /// Get box for sleep sessions
  static Future<Box> getSleepSessionsBox() async {
    if (!_initialized) await initialize();
    return await Hive.openBox(sleepSessionsBox);
  }

  /// Get box for devices
  static Future<Box> getDevicesBox() async {
    if (!_initialized) await initialize();
    return await Hive.openBox(devicesBox);
  }

  /// Cache sleep session locally
  static Future<void> cacheSleepSession(SleepSession session) async {
    final box = await getSleepSessionsBox();
    await box.put(session.id, session.toJson());
  }

  /// Get cached sleep sessions
  static Future<List<SleepSession>> getCachedSleepSessions() async {
    final box = await getSleepSessionsBox();
    final sessions = <SleepSession>[];

    for (var key in box.keys) {
      try {
        final data = box.get(key) as Map<String, dynamic>;
        sessions.add(SleepSession.fromJson(data));
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }

    return sessions;
  }

  /// Clear cached sleep sessions
  static Future<void> clearSleepSessions() async {
    final box = await getSleepSessionsBox();
    await box.clear();
  }

  /// Cache device locally
  static Future<void> cacheDevice(Device device) async {
    final box = await getDevicesBox();
    await box.put(device.id, device.toJson());
  }

  /// Get cached devices
  static Future<List<Device>> getCachedDevices() async {
    final box = await getDevicesBox();
    final devices = <Device>[];

    for (var key in box.keys) {
      try {
        final data = box.get(key) as Map<String, dynamic>;
        devices.add(Device.fromJson(data));
      } catch (e) {
        continue;
      }
    }

    return devices;
  }
}

