class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ServerException({required this.message, this.statusCode, this.errors});

  @override
  String toString() {
    return 'ServerException: $message (Status: $statusCode, Errors: $errors)';
  }
}

class CacheException implements Exception {
  final String message;

  CacheException({required this.message});

  @override
  String toString() {
    return 'CacheException: $message';
  }
}
