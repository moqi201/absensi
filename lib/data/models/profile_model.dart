import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class Profile {
  final int? id;
  final String? name;
  final String? email;
  @JsonKey(name: 'batch_id')
  final int? batchId;
  @JsonKey(name: 'training_id')
  final int? trainingId;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Profile({
    this.id,
    this.name,
    this.email,
    this.batchId,
    this.trainingId,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}
