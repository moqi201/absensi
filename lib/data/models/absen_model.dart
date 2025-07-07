import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'absen_model.g.dart';

@JsonSerializable()
class AbsenRecord {
  final int? id;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'check_in_lat')
  final String? checkInLat;
  @JsonKey(name: 'check_in_lng')
  final String? checkInLng;
  @JsonKey(name: 'check_in_address')
  final String? checkInAddress;
  @JsonKey(name: 'check_in_time')
  final DateTime? checkInTime;
  @JsonKey(name: 'check_out_lat')
  final String? checkOutLat;
  @JsonKey(name: 'check_out_lng')
  final String? checkOutLng;
  @JsonKey(name: 'check_out_address')
  final String? checkOutAddress;
  @JsonKey(name: 'check_out_time')
  final DateTime? checkOutTime;
  final String? status; // e.g., "masuk", "izin", "alpha"
  @JsonKey(name: 'alasan_izin')
  final String? alasanIzin; // reason for izin
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final User? user; // Optional: if user details are included in absen history

  AbsenRecord({
    this.id,
    this.userId,
    this.checkInLat,
    this.checkInLng,
    this.checkInAddress,
    this.checkInTime,
    this.checkOutLat,
    this.checkOutLng,
    this.checkOutAddress,
    this.checkOutTime,
    this.status,
    this.alasanIzin,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory AbsenRecord.fromJson(Map<String, dynamic> json) =>
      _$AbsenRecordFromJson(json);
  Map<String, dynamic> toJson() => _$AbsenRecordToJson(this);
}

@JsonSerializable()
class AbsenStatistic {
  @JsonKey(name: 'total_hadir')
  final int? totalHadir;
  @JsonKey(name: 'total_izin')
  final int? totalIzin;
  @JsonKey(name: 'total_alpha')
  final int? totalAlpha;

  AbsenStatistic({this.totalHadir, this.totalIzin, this.totalAlpha});

  factory AbsenStatistic.fromJson(Map<String, dynamic> json) =>
      _$AbsenStatisticFromJson(json);
  Map<String, dynamic> toJson() => _$AbsenStatisticToJson(this);
}
