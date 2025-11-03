// GENERATED CODE - DO NOT MODIFY BY HAND
// Run `flutter pub run build_runner build` to regenerate this file.

part of 'health_data.dart';

// Stub implementations - replace with generated code
SleepStage _$SleepStageFromJson(Map<String, dynamic> json) => SleepStage(
      type: json['type'] as String,
      duration: json['duration'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
    );

Map<String, dynamic> _$SleepStageToJson(SleepStage instance) => <String, dynamic>{
      'type': instance.type,
      'duration': instance.duration,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
    };

SleepSession _$SleepSessionFromJson(Map<String, dynamic> json) => SleepSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      stages: (json['stages'] as List<dynamic>)
          .map((e) => SleepStage.fromJson(e as Map<String, dynamic>))
          .toList(),
      efficiency: (json['efficiency'] as num?)?.toDouble(),
      totalSleepMinutes: json['totalSleepMinutes'] as int?,
      deviceId: json['deviceId'] as String?,
      deviceType: json['deviceType'] as String?,
    );

Map<String, dynamic> _$SleepSessionToJson(SleepSession instance) => <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'stages': instance.stages.map((e) => e.toJson()).toList(),
      'efficiency': instance.efficiency,
      'totalSleepMinutes': instance.totalSleepMinutes,
      'deviceId': instance.deviceId,
      'deviceType': instance.deviceType,
    };

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      name: json['name'] as String?,
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.parse(json['lastSyncAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'name': instance.name,
      'lastSyncAt': instance.lastSyncAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
