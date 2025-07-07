// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaseResponse<T> _$BaseResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => BaseResponse<T>(
  message: json['message'] as String?,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  errors: json['errors'] as Map<String, dynamic>?,
  success: json['success'] as bool?,
);

Map<String, dynamic> _$BaseResponseToJson<T>(
  BaseResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'message': instance.message,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
  'errors': instance.errors,
  'success': instance.success,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
