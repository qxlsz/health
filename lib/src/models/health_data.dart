import 'package:json_annotation/json_annotation.dart';

part 'health_data.g.dart';

/// Model for sleep stage data
@JsonSerializable()
class SleepStage {
  final String type; // 'REM', 'DEEP', 'LIGHT', 'AWAKE'
  final int duration; // Duration in minutes
  final DateTime startTime;
  final DateTime endTime;

  SleepStage({
    required this.type,
    required this.duration,
    required this.startTime,
    required this.endTime,
  });

  factory SleepStage.fromJson(Map<String, dynamic> json) =>
      _$SleepStageFromJson(json);
  Map<String, dynamic> toJson() => _$SleepStageToJson(this);
}

/// Model for complete sleep session
@JsonSerializable()
class SleepSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<SleepStage> stages;
  final double? efficiency; // Sleep efficiency percentage
  final int? totalSleepMinutes;
  final String? deviceId;
  final String? deviceType; // 'apple', 'android', 'whoop'

  SleepSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.stages,
    this.efficiency,
    this.totalSleepMinutes,
    this.deviceId,
    this.deviceType,
  });

  /// Calculate total sleep duration in minutes
  int get totalDuration {
    if (totalSleepMinutes != null) return totalSleepMinutes!;
    return stages.fold(0, (sum, stage) => sum + stage.duration);
  }

  /// Calculate sleep efficiency
  double calculateEfficiency() {
    if (efficiency != null) return efficiency!;
    final totalTime = endTime.difference(startTime).inMinutes;
    if (totalTime == 0) return 0.0;
    return (totalDuration / totalTime) * 100;
  }

  /// Get percentage of a specific sleep stage
  double getStagePercentage(String stageType) {
    if (totalDuration == 0) return 0.0;
    final stageDuration = stages
        .where((s) => s.type.toUpperCase() == stageType.toUpperCase())
        .fold(0, (sum, stage) => sum + stage.duration);
    return (stageDuration / totalDuration) * 100;
  }

  factory SleepSession.fromJson(Map<String, dynamic> json) =>
      _$SleepSessionFromJson(json);
  Map<String, dynamic> toJson() => _$SleepSessionToJson(this);
}

/// Model for device information
@JsonSerializable()
class Device {
  final String id;
  final String userId;
  final String type; // 'apple', 'android', 'whoop'
  final String? name;
  final DateTime? lastSyncAt;
  final DateTime createdAt;

  Device({
    required this.id,
    required this.userId,
    required this.type,
    this.name,
    this.lastSyncAt,
    required this.createdAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceToJson(this);

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    switch (type) {
      case 'apple':
        return 'Apple Watch';
      case 'android':
        return 'Android Wear';
      case 'whoop':
        return 'Whoop';
      default:
        return 'Unknown Device';
    }
  }
}
