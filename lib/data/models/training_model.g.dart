// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Training _$TrainingFromJson(Map<String, dynamic> json) => Training(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String?,
  description: json['description'] as String?,
  participantCount: (json['participant_count'] as num?)?.toInt(),
  standard: json['standard'] as String?,
  duration: json['duration'] as String?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  units: json['units'] as List<dynamic>?,
  activities: json['activities'] as List<dynamic>?,
);

Map<String, dynamic> _$TrainingToJson(Training instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'participant_count': instance.participantCount,
  'standard': instance.standard,
  'duration': instance.duration,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'units': instance.units,
  'activities': instance.activities,
};
