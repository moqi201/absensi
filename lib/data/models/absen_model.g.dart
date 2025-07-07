// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'absen_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AbsenRecord _$AbsenRecordFromJson(Map<String, dynamic> json) => AbsenRecord(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['user_id'] as num?)?.toInt(),
  checkInLat: json['check_in_lat'] as String?,
  checkInLng: json['check_in_lng'] as String?,
  checkInAddress: json['check_in_address'] as String?,
  checkInTime:
      json['check_in_time'] == null
          ? null
          : DateTime.parse(json['check_in_time'] as String),
  checkOutLat: json['check_out_lat'] as String?,
  checkOutLng: json['check_out_lng'] as String?,
  checkOutAddress: json['check_out_address'] as String?,
  checkOutTime:
      json['check_out_time'] == null
          ? null
          : DateTime.parse(json['check_out_time'] as String),
  status: json['status'] as String?,
  alasanIzin: json['alasan_izin'] as String?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  user:
      json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AbsenRecordToJson(AbsenRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'check_in_lat': instance.checkInLat,
      'check_in_lng': instance.checkInLng,
      'check_in_address': instance.checkInAddress,
      'check_in_time': instance.checkInTime?.toIso8601String(),
      'check_out_lat': instance.checkOutLat,
      'check_out_lng': instance.checkOutLng,
      'check_out_address': instance.checkOutAddress,
      'check_out_time': instance.checkOutTime?.toIso8601String(),
      'status': instance.status,
      'alasan_izin': instance.alasanIzin,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'user': instance.user,
    };

AbsenStatistic _$AbsenStatisticFromJson(Map<String, dynamic> json) =>
    AbsenStatistic(
      totalHadir: (json['total_hadir'] as num?)?.toInt(),
      totalIzin: (json['total_izin'] as num?)?.toInt(),
      totalAlpha: (json['total_alpha'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AbsenStatisticToJson(AbsenStatistic instance) =>
    <String, dynamic>{
      'total_hadir': instance.totalHadir,
      'total_izin': instance.totalIzin,
      'total_alpha': instance.totalAlpha,
    };
