import 'package:json_annotation/json_annotation.dart';
import 'training_model.dart'; // Assuming Batch can contain Training data

part 'batch_model.g.dart';

@JsonSerializable()
class Batch {
  final int? id;
  final String? name;
  final String? description;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'users_count')
  final int? usersCount;
  final List<Training>?
  trainings; // List of trainings associated with the batch

  Batch({
    this.id,
    this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.usersCount,
    this.trainings,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => _$BatchFromJson(json);
  Map<String, dynamic> toJson() => _$BatchToJson(this);
}
