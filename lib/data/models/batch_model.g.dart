// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Batch _$BatchFromJson(Map<String, dynamic> json) => Batch(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  description: json['description'] as String?,
  startDate:
      json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
  endDate:
      json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  usersCount: (json['users_count'] as num?)?.toInt(),
  trainings:
      (json['trainings'] as List<dynamic>?)
          ?.map((e) => Training.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$BatchToJson(Batch instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'start_date': instance.startDate?.toIso8601String(),
  'end_date': instance.endDate?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'users_count': instance.usersCount,
  'trainings': instance.trainings,
};
