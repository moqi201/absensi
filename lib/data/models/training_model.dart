import 'package:json_annotation/json_annotation.dart';

part 'training_model.g.dart';

@JsonSerializable()
class Training {
  final int? id;
  final String? title;
  final String? description;
  @JsonKey(name: 'participant_count')
  final int? participantCount;
  final String? standard;
  final String? duration;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<dynamic>? units; // Adjust if unit model is defined
  final List<dynamic>? activities; // Adjust if activity model is defined

  Training({
    this.id,
    this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
    this.units,
    this.activities,
  });

  factory Training.fromJson(Map<String, dynamic> json) =>
      _$TrainingFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingToJson(this);
}
