// lib/services/api_service.dart
import 'dart:convert';

import 'package:absensi/data/models/app_models.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'https://appabsensi.mobileprojp.com/api';
  static String? _token;

  // Initialize token from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  // Save token to SharedPreferences
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _token = token;
  }

  // Clear token from SharedPreferences
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
  }

  // Helper to get token (for external use, e.g., SplashScreen)
  static String? getToken() {
    return _token;
  }

  // Helper to get headers with Authorization token
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- Auth Endpoints ---

  // Updated Register method to match new API structure
  Future<ApiResponse<AuthData>> register({
    required String name,
    required String email,
    required String password,
    required int batchId,
    required int trainingId,
    required String jenisKelamin,
  }) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'batch_id': batchId,
          'training_id': trainingId,
          'jenis_kelamin': jenisKelamin,
        }),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(responseBody);
        if (authResponse.data != null) {
          await _saveToken(authResponse.data!.token);
        }
        return ApiResponse(
          message: authResponse.message,
          data: authResponse.data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<AuthData>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(responseBody);
        if (authResponse.data != null) {
          await _saveToken(authResponse.data!.token);
        }
        return ApiResponse(
          message: authResponse.message,
          data: authResponse.data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Login failed',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // New: Request OTP for Forgot Password
  Future<ApiResponse<void>> forgotPassword({required String email}) async {
    final url = Uri.parse('$_baseUrl/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'] ?? 'OTP requested successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to request OTP',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // New: Verify OTP
  Future<ApiResponse<void>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse('$_baseUrl/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'] ?? 'OTP verified successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to verify OTP',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // New: Reset Password
  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final url = Uri.parse('$_baseUrl/reset-password');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': newPassword,
          'password_confirmation': newPasswordConfirmation,
        }),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'] ?? 'Password reset successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to reset password',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // --- Absence Endpoints ---

  // Modified checkIn to handle both 'masuk' and 'izin' statuses
  // Location parameters are now nullable as they are not needed for 'izin'
  Future<ApiResponse<Absence>> checkIn({
    double? checkInLat,
    double? checkInLng,
    String? checkInAddress,
    required String status, // "masuk" or "izin"
    String? alasanIzin, // Required if status is "izin"
    String? requestDate, // Required if status is "izin", format YYYY-MM-DD
  }) async {
    final url = Uri.parse(
      '$_baseUrl/absen/check-in',
    ); // Pastikan ini endpoint yang benar untuk keduanya
    try {
      final body = <String, dynamic>{'status': status};

      if (status == 'masuk') {
        final now = DateTime.now();
        final String attendanceDate = DateFormat('yyyy-MM-dd').format(now);
        final String checkInValue = DateFormat(
          'H:mm',
        ).format(now); // H:mm atau HH:mm jika backend butuh leading zero

        body['attendance_date'] = attendanceDate;
        body['check_in'] =
            checkInValue; // Sesuaikan dengan nama field di backend
        if (checkInLat != null) body['check_in_lat'] = checkInLat;
        if (checkInLng != null) body['check_in_lng'] = checkInLng;
        if (checkInAddress != null) body['check_in_address'] = checkInAddress;
        // Tidak perlu mengirim check_in_time jika field backendnya 'check_in'
      } else if (status == 'izin') {
        // --- PERUBAHAN UTAMA DI SINI ---
        // Sesuai JSON, hanya 'attendance_date', 'status', 'alasan_izin' yang dikirim
        // check_in_time, check_in_lat, check_in_lng, check_in_address TIDAK DIKIRIM (atau dikirim null jika API eksplisit butuh)

        final now =
            DateTime.now(); // Gunakan waktu saat ini untuk attendance_date
        final String attendanceDate = DateFormat('yyyy-MM-dd').format(now);

        body['attendance_date'] =
            attendanceDate; // Backend mengharapkan ini (sesuai JSON respons)
        if (alasanIzin != null)
          body['alasan_izin'] =
              alasanIzin; // Pastikan ini nama field yang benar

        // Jika Anda memiliki 'tanggal_izin' terpisah di backend untuk izin, tambahkan:
        if (requestDate != null) body['tanggal_izin'] = requestDate;

        // JANGAN MENGIRIM check_in, check_in_lat, check_in_lng, check_in_address UNTUK STATUS 'IZIN'
        // Jika API backend Anda *masih* memunculkan error "required" setelah ini,
        // itu berarti backend-nya memiliki validasi yang tidak konsisten, dan Anda mungkin perlu
        // mengirimkan mereka sebagai null secara eksplisit jika API menerimanya,
        // atau kosong ("") jika itu adalah string, tapi ini tidak ideal.
        // Contoh: body['check_in_lat'] = null;
        // Tapi berdasarkan JSON sukses, TIDAK DIKIRIM LEBIH BAIK.
      }

      final response = await http.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String apiMessage =
            responseBody['message'] as String? ??
            'Absence submitted successfully';

        if (responseBody['data'] is Map<String, dynamic>) {
          return ApiResponse(
            message: apiMessage,
            data: Absence.fromJson(responseBody['data']),
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse.fromError(
            '$apiMessage. Invalid data format from server for absence.',
            statusCode: response.statusCode,
          );
        }
      } else {
        String errorMessage =
            responseBody['message'] as String? ?? 'Absence submission failed';
        if (responseBody['errors'] != null) {
          errorMessage += '\nDetails: ${jsonEncode(responseBody['errors'])}';
        }
        return ApiResponse.fromError(
          errorMessage,
          statusCode: response.statusCode,
          errors: responseBody['errors'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      return ApiResponse.fromError(
        'An error occurred during absence submission: $e',
      );
    }
  }

  Future<ApiResponse<Absence>> checkOut({
    required double checkOutLat,
    required double checkOutLng,
    required String checkOutAddress,
  }) async {
    final url = Uri.parse('$_baseUrl/absen/check-out');
    try {
      // Ambil tanggal dan waktu saat ini untuk check-out
      final now = DateTime.now();
      final String attendanceDate = DateFormat('yyyy-MM-dd').format(now);
      // Asumsi format 'H:i' seperti yang diminta sebelumnya untuk check_in.
      // Jika backend Anda membutuhkan HH:mm atau HH:mm:ss untuk check_out, sesuaikan di sini.
      final String checkOutValue = DateFormat('H:mm').format(now);

      final response = await http.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'attendance_date': attendanceDate, // <--- TAMBAHKAN INI
          'check_out': checkOutValue, // <--- TAMBAHKAN INI
          'check_out_lat': checkOutLat,
          'check_out_lng': checkOutLng,
          'check_out_address': checkOutAddress,
        }),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String apiMessage =
            responseBody['message'] as String? ?? 'Check-out successful';

        if (responseBody['data'] is Map<String, dynamic>) {
          return ApiResponse(
            message: apiMessage,
            data: Absence.fromJson(responseBody['data']),
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse.fromError(
            '$apiMessage. Invalid data format from server for check-out.',
            statusCode: response.statusCode,
          );
        }
      } else {
        String errorMessage =
            responseBody['message'] as String? ?? 'Check-out failed';
        if (responseBody['errors'] != null) {
          errorMessage += '\nDetails: ${jsonEncode(responseBody['errors'])}';
        }
        return ApiResponse.fromError(
          errorMessage,
          statusCode: response.statusCode,
          errors: responseBody['errors'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred during check-out: $e');
    }
  }

  Future<ApiResponse<AbsenceToday>> getAbsenceToday() async {
    final url = Uri.parse('$_baseUrl/absen/today');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String apiMessage =
            responseBody['message'] as String? ??
            'Today\'s absence data fetched successfully';

        // Pastikan 'data' ada dan merupakan Map sebelum diparsing
        // Model AbsenceToday.fromJson sudah bisa menangani jika 'data' null
        // atau jika data absensi langsung di root JSON.
        // Namun, jika API selalu mengembalikan 'data' sebagai Map atau null,
        // validasi di sini memastikan bahwa yang kita kirim ke fromJson adalah Map atau null.
        if (responseBody['data'] is Map<String, dynamic> ||
            responseBody['data'] == null) {
          return ApiResponse(
            message: apiMessage,
            data:
                responseBody['data'] != null
                    ? AbsenceToday.fromJson(responseBody['data'])
                    : null, // Jika 'data' null, kirim null ke AbsenceToday
            statusCode: response.statusCode,
          );
        } else {
          // Jika 'data' ada tapi bukan Map<String, dynamic>
          return ApiResponse.fromError(
            '$apiMessage. Invalid data format for today\'s absence.',
            statusCode: response.statusCode,
          );
        }
      } else {
        // Jika status code bukan 200, berarti ada error
        String errorMessage =
            responseBody['message'] as String? ??
            'Failed to get today\'s absence data';
        if (responseBody['errors'] != null) {
          // Tambahkan detail error dari backend jika ada
          errorMessage += '\nDetails: ${jsonEncode(responseBody['errors'])}';
        }
        return ApiResponse.fromError(
          errorMessage,
          statusCode: response.statusCode,
          errors: responseBody['errors'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      // Tangani error jaringan atau parsing JSON
      return ApiResponse.fromError(
        'An error occurred while fetching today\'s absence data: $e',
      );
    }
  }

  Future<ApiResponse<AbsenceStats>> getAbsenceStats() async {
    final url = Uri.parse('$_baseUrl/absen/stats');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          data: AbsenceStats.fromJson(responseBody['data']),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get absence statistics',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<Absence>> deleteAbsence(int id) async {
    final url = Uri.parse('$_baseUrl/absen/$id');
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          data: Absence.fromJson(responseBody['data']),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to delete absence data',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<List<Absence>>> getAbsenceHistory({
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, String> queryParams = {};
    if (startDate != null) {
      queryParams['start'] = startDate;
    }
    if (endDate != null) {
      queryParams['end'] = endDate;
    }

    final url = Uri.parse(
      '$_baseUrl/absen/history',
    ).replace(queryParameters: queryParams);
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Absence> history =
            (responseBody['data'] as List)
                .map((e) => Absence.fromJson(e))
                .toList();
        return ApiResponse(
          message: responseBody['message'],
          data: history,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get absence history',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // --- User Profile Endpoints ---

  Future<ApiResponse<User>> getProfile() async {
    final url = Uri.parse('$_baseUrl/profile');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          data: User.fromJson(responseBody['data']),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get profile data',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // Modified: Update user name and gender
  Future<ApiResponse<User>> updateProfile({
    String? name, // Changed to optional
    String? jenisKelamin, // Changed to optional
  }) async {
    final url = Uri.parse('$_baseUrl/profile');
    try {
      final body = <String, dynamic>{};
      if (name != null) {
        body['name'] = name;
      }
      if (jenisKelamin != null) {
        body['jenis_kelamin'] = jenisKelamin;
      }

      final response = await http.put(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          data: User.fromJson(responseBody['data']),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to update profile',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // New: Update profile photo
  Future<ApiResponse<User>> updateProfilePhoto({
    required String profilePhoto, // Base64 string
  }) async {
    final url = Uri.parse('$_baseUrl/profile/photo');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({'profile_photo': profilePhoto}),
      );
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          data: User.fromJson(responseBody['data']),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to update profile photo',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<List<User>>> getAllUsers() async {
    final url = Uri.parse('$_baseUrl/users');
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(
          includeAuth: true,
        ), // Assuming this endpoint requires authentication
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<User> users =
            (responseBody['data'] as List)
                .map((e) => User.fromJson(e))
                .toList();
        return ApiResponse(
          message: responseBody['message'],
          data: users,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get all users',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // --- Training Endpoints ---

  Future<ApiResponse<List<Training>>> getTrainings() async {
    final url = Uri.parse('$_baseUrl/trainings');
    try {
      final response = await http.get(url, headers: _getHeaders());

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Training> trainings =
            (responseBody['data'] as List)
                .map((e) => Training.fromJson(e))
                .toList();
        return ApiResponse(
          message: responseBody['message'],
          data: trainings,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get trainings',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  Future<ApiResponse<Training>> getTrainingDetail(int id) async {
    final url = Uri.parse('$_baseUrl/trainings/$id');
    try {
      final response = await http.get(url, headers: _getHeaders());

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          message: responseBody['message'],
          data: Training.fromJson(responseBody['data']),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get training detail',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }

  // --- Batch Endpoints ---
  Future<ApiResponse<List<Batch>>> getBatches() async {
    final url = Uri.parse('$_baseUrl/batches');
    try {
      // The Postman collection shows this endpoint requires a token.
      // Adjust if your actual API allows public access.
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Batch> batches =
            (responseBody['data'] as List)
                .map((e) => Batch.fromJson(e))
                .toList();
        return ApiResponse(
          message: responseBody['message'],
          data: batches,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.fromError(
          responseBody['message'] ?? 'Failed to get batches',
          statusCode: response.statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      return ApiResponse.fromError('An error occurred: $e');
    }
  }
}
