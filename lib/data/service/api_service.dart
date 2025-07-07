import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Import your models
import '../models/auth_model.dart';
import '../models/base_response_model.dart';
import '../models/user_model.dart';
import '../models/absen_model.dart';
import '../models/batch_model.dart';
import '../models/training_model.dart';
import '../models/profile_model.dart';

class ApiService {
  static const String baseUrl =
      'https://appabsensi.mobileprojp.com/api'; // Base URL
  static String? _token;
  static User? _currentUser;

  // --- Static methods for Token & User Management ---
  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  static Future<void> saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
    _currentUser = user;
  }

  static Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString('current_user');
    if (userJsonString != null) {
      _currentUser = User.fromJson(jsonDecode(userJsonString));
      return _currentUser;
    }
    return null;
  }

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
    _token = null;
    _currentUser = null;
  }

  // Helper for parsing responses and adding 'success' logic
  BaseResponse<T> _parseAndCreateBaseResponse<T>(
    http.Response response,
    T Function(Object? json) fromJsonT, {
    bool defaultSuccessOn2xx = true,
  }) {
    try {
      final jsonResponse = jsonDecode(response.body);

      final bool isSuccessDetermined;
      if (jsonResponse['success'] is bool) {
        isSuccessDetermined = jsonResponse['success'] as bool;
      } else {
        isSuccessDetermined =
            (defaultSuccessOn2xx &&
                (response.statusCode >= 200 && response.statusCode < 300));
      }

      T? data;
      if (isSuccessDetermined && jsonResponse['data'] != null) {
        try {
          data = fromJsonT(jsonResponse['data']);
        } catch (e) {
          print('[ApiService] Warning: Failed to parse data on success: $e');
          data = null;
        }
      }

      final String message =
          (jsonResponse['message'] as String?) ??
          (isSuccessDetermined ? 'Operasi berhasil.' : 'Operasi gagal.');

      return BaseResponse<T>(
        message: message,
        data: data,
        errors:
            (jsonResponse['errors'] is Map)
                ? Map<String, dynamic>.from(jsonResponse['errors'] as Map)
                : null,
        success: isSuccessDetermined,
      );
    } catch (e) {
      print(
        '[ApiService] Error parsing API response: $e. Response body: ${response.body}',
      );
      return BaseResponse<T>(
        message: 'Gagal memproses respons server: $e',
        success: false,
      );
    }
  }

  // --- Common HTTP Request Helper ---
  Future<http.Response> _sendRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (requiresAuth) {
      final token = await getToken();
      if (token == null) {
        throw Exception('Autentikasi diperlukan. Pengguna belum login.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    switch (method.toUpperCase()) {
      case 'POST':
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
        break;
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'PUT':
        response = await http.put(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
        break;
      case 'DELETE':
        response = await http.delete(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
        break;
      default:
        throw Exception('Metode HTTP tidak didukung: $method');
    }

    if (kDebugMode) {
      debugPrint('[ApiService] $method $url');
      debugPrint('[ApiService] Status Code: ${response.statusCode}');
      debugPrint('[ApiService] Response Body: ${response.body}');
    }

    // Handle redirects for non-2xx statuses (e.g., 302 for some errors)
    if (response.statusCode == 302 &&
        response.headers.containsKey('location')) {
      final redirectLocation = response.headers['location'];
      debugPrint(
        '!!! REDIRECT DETECTED (Status 302) !!! Redirecting to: $redirectLocation',
      );
      throw Exception(
        'Server melakukan pengalihan. Kemungkinan URL API salah atau konfigurasi server tidak tepat. Redirect ke: $redirectLocation',
      );
    }

    return response;
  }

  // --- AUTHENTICATION ---

  Future<BaseResponse<AuthData>?> register(
    String name,
    String email,
    String password,
    int batchId,
    int trainingId,
  ) async {
    try {
      final response = await _sendRequest(
        'POST',
        '/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'batch_id': batchId,
          'training_id': trainingId,
        },
        requiresAuth: false,
      );

      final BaseResponse<AuthData> authBaseResponse =
          _parseAndCreateBaseResponse(
            response,
            (json) => AuthData.fromJson(json as Map<String, dynamic>),
          );

      if (authBaseResponse.success == true &&
          authBaseResponse.data?.token != null &&
          authBaseResponse.data?.user != null) {
        await saveToken(authBaseResponse.data!.token!);
        await saveCurrentUser(authBaseResponse.data!.user!);
      }
      return authBaseResponse;
    } catch (e) {
      print('[ApiService] Error during register: $e');
      return BaseResponse<AuthData>(
        message: 'Terjadi kesalahan: $e',
        success: false,
      );
    }
  }

  Future<BaseResponse<AuthData>?> login(String email, String password) async {
    try {
      final response = await _sendRequest(
        'POST',
        '/login',
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      final BaseResponse<AuthData> authBaseResponse =
          _parseAndCreateBaseResponse(
            response,
            (json) => AuthData.fromJson(json as Map<String, dynamic>),
          );

      if (authBaseResponse.success == true &&
          authBaseResponse.data?.token != null &&
          authBaseResponse.data?.user != null) {
        await saveToken(authBaseResponse.data!.token!);
        await saveCurrentUser(authBaseResponse.data!.user!);
      }
      return authBaseResponse;
    } catch (e) {
      print('[ApiService] Error during login: $e');
      return BaseResponse<AuthData>(
        message: 'Terjadi kesalahan: $e',
        success: false,
      );
    }
  }

  Future<void> logout() async {
    // Though there's no explicit logout API, clearing local storage is sufficient for token-based auth
    await deleteToken();
    print('[ApiService] User logged out and token cleared.');
  }

  // --- DASHBOARD / ATTENDANCE ---

  Future<BaseResponse<AbsenRecord>?> absenCheckIn({
    required String checkInLat,
    required String checkInLng,
    required String checkInAddress,
    required String status,
    String? alasanIzin,
  }) async {
    try {
      final response = await _sendRequest(
        'POST',
        '/absen/check-in',
        body: {
          'check_in_lat': checkInLat,
          'check_in_lng': checkInLng,
          'check_in_address': checkInAddress,
          'status': status,
          if (alasanIzin != null) 'alasan_izin': alasanIzin,
        },
      );

      return _parseAndCreateBaseResponse(
        response,
        (json) => AbsenRecord.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('[ApiService] Error during check-in: $e');
      return BaseResponse<AbsenRecord>(
        message: 'Terjadi kesalahan saat absen masuk: $e',
        success: false,
      );
    }
  }

  Future<BaseResponse<AbsenRecord>?> absenCheckOut({
    required String checkOutLat,
    required String checkOutLng,
    required String checkOutAddress,
  }) async {
    try {
      final response = await _sendRequest(
        'POST',
        '/absen/check-out',
        body: {
          'check_out_lat': checkOutLat,
          'check_out_lng': checkOutLng,
          'check_out_address': checkOutAddress,
        },
      );

      return _parseAndCreateBaseResponse(
        response,
        (json) => AbsenRecord.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('[ApiService] Error during check-out: $e');
      return BaseResponse<AbsenRecord>(
        message: 'Terjadi kesalahan saat absen pulang: $e',
        success: false,
      );
    }
  }

  Future<BaseResponse<AbsenRecord>?> getAbsenToday() async {
    try {
      final response = await _sendRequest('GET', '/absen/today');
      return _parseAndCreateBaseResponse(
        response,
        (json) => AbsenRecord.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('[ApiService] Error getting today\'s attendance: $e');
      return BaseResponse<AbsenRecord>(
        message: 'Terjadi kesalahan saat mengambil absen hari ini: $e',
        success: false,
      );
    }
  }

  Future<BaseResponse<AbsenStatistic>?> getAbsenStatistic() async {
    try {
      final response = await _sendRequest('GET', '/absen/statistik');
      return _parseAndCreateBaseResponse(
        response,
        (json) => AbsenStatistic.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('[ApiService] Error getting attendance statistics: $e');
      return BaseResponse<AbsenStatistic>(
        message: 'Terjadi kesalahan saat mengambil statistik absen: $e',
        success: false,
      );
    }
  }

  // --- HISTORY ---

  Future<BaseResponse<List<AbsenRecord>>?> getHistoryAbsen() async {
    try {
      final response = await _sendRequest('GET', '/history-absen');
      return _parseAndCreateBaseResponse(
        response,
        (json) => List<AbsenRecord>.from(
          (json as List).map(
            (x) => AbsenRecord.fromJson(x as Map<String, dynamic>),
          ),
        ),
      );
    } catch (e) {
      print('[ApiService] Error getting attendance history: $e');
      return BaseResponse<List<AbsenRecord>>(
        message: 'Terjadi kesalahan saat mengambil riwayat absen: $e',
        success: false,
      );
    }
  }

  Future<BaseResponse<dynamic>?> deleteAbsen(int id) async {
    try {
      final response = await _sendRequest('DELETE', '/delete-absen?id=$id');
      // No data expected in return, so use a simple parser
      return _parseAndCreateBaseResponse(response, (json) => null);
    } catch (e) {
      print('[ApiService] Error deleting attendance record: $e');
      return BaseResponse<dynamic>(
        message: 'Terjadi kesalahan saat menghapus absen: $e',
        success: false,
      );
    }
  }

  // --- PROFILE ---

  Future<BaseResponse<Profile>?> getProfile() async {
    try {
      final response = await _sendRequest('GET', '/profile');
      return _parseAndCreateBaseResponse(
        response,
        (json) => Profile.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('[ApiService] Error getting profile: $e');
      return BaseResponse<Profile>(
        message: 'Terjadi kesalahan saat mengambil data profil: $e',
        success: false,
      );
    }
  }

  Future<BaseResponse<Profile>?> editProfile(
    String name,
    String email, {
    int? batchId,
    int? trainingId,
  }) async {
    try {
      final response = await _sendRequest(
        'PUT',
        '/edit-profile',
        body: {
          'name': name,
          'email': email,
          if (batchId != null) 'batch_id': batchId,
          if (trainingId != null) 'training_id': trainingId,
        },
      );
      return _parseAndCreateBaseResponse(
        response,
        (json) => Profile.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('[ApiService] Error editing profile: $e');
      return BaseResponse<Profile>(
        message: 'Terjadi kesalahan saat mengedit profil: $e',
        success: false,
      );
    }
  }

  // --- Master Data Endpoints (for Register page dropdowns) ---

  Future<BaseResponse<List<Batch>>?> getAllBatches() async {
    try {
      final response = await _sendRequest(
        'GET',
        '/batches',
        requiresAuth: true,
      ); // Check Postman: is this authenticated?
      return _parseAndCreateBaseResponse(
        response,
        (json) => List<Batch>.from(
          (json as List).map((x) => Batch.fromJson(x as Map<String, dynamic>)),
        ),
      );
    } catch (e) {
      print('[ApiService] Error getting all batches: $e');
      return BaseResponse<List<Batch>>(
        message: 'Terjadi kesalahan saat mengambil data batch: $e',
        success: false,
      );
    }
  }

  Future<BaseResponse<List<Training>>?> getAllTrainings() async {
    try {
      final response = await _sendRequest(
        'GET',
        '/trainings',
        requiresAuth: true,
      ); // Check Postman: is this authenticated?
      return _parseAndCreateBaseResponse(
        response,
        (json) => List<Training>.from(
          (json as List).map(
            (x) => Training.fromJson(x as Map<String, dynamic>),
          ),
        ),
      );
    } catch (e) {
      print('[ApiService] Error getting all trainings: $e');
      return BaseResponse<List<Training>>(
        message: 'Terjadi kesalahan saat mengambil data pelatihan: $e',
        success: false,
      );
    }
  }

  Future<BaseResponse<Training>?> getTrainingDetail(int id) async {
    try {
      final response = await _sendRequest(
        'GET',
        '/trainings/$id',
        requiresAuth: true,
      );
      return _parseAndCreateBaseResponse(
        response,
        (json) => Training.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      print('[ApiService] Error getting training detail: $e');
      return BaseResponse<Training>(
        message: 'Terjadi kesalahan saat mengambil detail pelatihan: $e',
        success: false,
      );
    }
  }
}
