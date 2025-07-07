import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_model.g.dart';

@JsonSerializable()
class AuthData {
  final String? token;
  final User? user;

  AuthData({this.token, this.user});

  factory AuthData.fromJson(Map<String, dynamic> json) =>
      _$AuthDataFromJson(json);
  Map<String, dynamic> toJson() => _$AuthDataToJson(this);
}
