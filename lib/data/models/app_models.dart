// lib/models/app_models.dart
import 'package:intl/intl.dart'; // <--- Tambahkan baris ini
// Helper function to safely parse int from dynamic (could be int or string)
int? _parseIntFromDynamic(dynamic value) {
  if (value is int) {
    return value;
  } else if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

// --- API Response Models ---
class ApiResponse<T> {
  final String message; // This is non-nullable
  final T? data;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  ApiResponse({required this.message, this.data, this.errors, this.statusCode});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    int? parsedStatusCode;
    if (json.containsKey('status_code')) {
      parsedStatusCode = _parseIntFromDynamic(json['status_code']);
    }

    // Safely get message, provide a default if it's null from API
    final String parsedMessage =
        json['message'] as String? ?? 'An unexpected error occurred.';

    return ApiResponse(
      message: parsedMessage, // Use the safely parsed message
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors'] as Map<String, dynamic>?,
      statusCode: parsedStatusCode,
    );
  }

  factory ApiResponse.fromError(
    String message, {
    int? statusCode,
    Map<String, dynamic>? errors,
  }) {
    return ApiResponse(
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

// --- Authentication Models ---
class AuthResponse {
  final String message;
  final AuthData? data;

  AuthResponse({required this.message, this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message:
          json['message'] as String? ??
          'Authentication response message missing.', // Added null-check
      data:
          json['data'] != null
              ? AuthData.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
  }
}

class AuthData {
  final String token;
  final User user;

  AuthData({required this.token, required this.user});

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }
}

// --- User Profile Models ---
class User {
  final int id;
  final String name;
  final String email;
  final String? batch_ke; // Added new field
  final String? training_title; // Added new field
  final String? jenis_kelamin; // Added new field
  final String? profile_photo; // Added new field
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt; // Made nullable
  final DateTime? updatedAt; // Made nullable
  final int? batchId;
  final int? trainingId;
  final Batch? batch; // Nested Batch object
  final Training? training; // Nested Training object

  User({
    required this.id,
    required this.name,
    required this.email,
    this.batch_ke, // Added to constructor
    this.training_title, // Added to constructor
    this.jenis_kelamin, // Added to constructor
    this.profile_photo, // Added to constructor
    this.emailVerifiedAt,
    this.createdAt, // Removed required
    this.updatedAt, // Removed required
    this.batchId,
    this.trainingId,
    this.batch,
    this.training,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id:
          _parseIntFromDynamic(json['id']) ??
          0, // Use helper, provide default for required id
      name:
          json['name'] as String? ??
          'Unknown Name', // Added null-aware cast and fallback
      email:
          json['email'] as String? ??
          'unknown@example.com', // Added null-aware cast and fallback
      batch_ke: json['batch_ke'] as String?, // Parse new field
      training_title: json['training_title'] as String?, // Parse new field
      jenis_kelamin: json['jenis_kelamin'] as String?, // Parse new field
      profile_photo: json['profile_photo'] as String?, // Parse new field
      emailVerifiedAt:
          json['email_verified_at'] != null
              ? DateTime.parse(json['email_verified_at'] as String)
              : null,
      createdAt:
          json['created_at'] !=
                  null // Added null-check before parsing
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] !=
                  null // Added null-check before parsing
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      batchId: _parseIntFromDynamic(json['batch_id']), // Use helper for batchId
      trainingId: _parseIntFromDynamic(
        json['training_id'],
      ), // Use helper for trainingId
      batch:
          json['batch'] != null
              ? Batch.fromJson(json['batch'] as Map<String, dynamic>)
              : null,
      training:
          json['training'] != null
              ? Training.fromJson(json['training'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'batch_ke': batch_ke, // Added to toJson
      'training_title': training_title, // Added to toJson
      'jenis_kelamin': jenis_kelamin, // Added to toJson
      'profile_photo': profile_photo, // Added to toJson
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'batch_id': batchId,
      'training_id': trainingId,
      'batch': batch?.toJson(),
      'training': training?.toJson(),
    };
  }
}

// --- Attendance Models ---
// lib/data/models/absence.dart (atau di mana pun model Absence Anda didefinisikan)


class Absence {
  final int? id;
  final String? userId;
  final String? attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInAddress;
  final String? checkOutAddress;
  final double? checkInLat;  // <--- UBAH KE double?
  final double? checkInLng;  // <--- UBAH KE double?
  final double? checkOutLat; // <--- UBAH KE double?
  final double? checkOutLng; // <--- UBAH KE double?
  final String? status;
  final String? alasanIzin;
  final String? tanggalIzin;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? checkIn;
  final DateTime? checkOut;

  Absence({
    this.id,
    this.userId,
    this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.checkInAddress,
    this.checkOutAddress,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.status,
    this.alasanIzin,
    this.tanggalIzin,
    this.createdAt,
    this.updatedAt,
    this.checkIn,
    this.checkOut,
  });
  factory Absence.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse time strings to DateTime
    DateTime? parseTime(String? dateStr, String? timeStr) {
      if (dateStr == null || timeStr == null) return null;
      try {
        // Gabungkan tanggal dan waktu untuk membuat DateTime lengkap
        return DateTime.parse('$dateStr $timeStr');
      } catch (e) {
        print('Error parsing date-time string: $e');
        return null;
      }
    }

    // Helper function to format DateTime to H:i string
    String? formatTimeToHi(String? dateTimeString) {
      if (dateTimeString == null) return null;
      try {
        final DateTime dateTime = DateTime.parse(dateTimeString);
        return DateFormat('H:mm').format(dateTime);
      } catch (e) {
        print('Error formatting time to H:mm: $e');
        return dateTimeString; // Return original if parsing fails
      }
    }

    // Asumsi API mengembalikan check_in_time dan check_out_time sebagai string,
    // atau Anda akan memformat dari objek DateTime jika API hanya memberikan itu.

    // Untuk parsing `checkIn` dan `checkOut` (tipe DateTime?):
    // Jika API memberikan 'check_in' dan 'check_out' sebagai DateTime ISO string, gunakan ini:
    DateTime? parsedCheckIn;
    DateTime? parsedCheckOut;
    try {
      parsedCheckIn =
          json['check_in'] != null ? DateTime.parse(json['check_in']) : null;
      parsedCheckOut =
          json['check_out'] != null ? DateTime.parse(json['check_out']) : null;
    } catch (e) {
      print('Error parsing check_in/check_out DateTime: $e');
    }

    // Mengambil string waktu langsung dari JSON jika tersedia,
    // atau memformat dari DateTime yang sudah ada jika tidak.
    String? checkInTimeString = json['check_in_time'] as String?;
    String? checkOutTimeString = json['check_out_time'] as String?;

    // Alternatif: Jika backend hanya memberikan `check_in` dan `check_out` sebagai DateTime,
    // Anda bisa menghasilkan `checkInTime` dan `checkOutTime` (string H:i) dari sana:
    if (checkInTimeString == null && parsedCheckIn != null) {
      checkInTimeString = DateFormat('H:mm').format(parsedCheckIn.toLocal());
    }
    if (checkOutTimeString == null && parsedCheckOut != null) {
      checkOutTimeString = DateFormat('H:mm').format(parsedCheckOut.toLocal());
    }

    return Absence(
    id: json['id'] as int?,
    userId: json['user_id'] as String?,
    attendanceDate: json['attendance_date'] as String?,
    checkInTime: checkInTimeString,
    checkOutTime: checkOutTimeString,
    checkInAddress: json['check_in_address'] as String?,
    checkOutAddress: json['check_out_address'] as String?,
    // Pastikan parsing ke double aman
    checkInLat: (json['check_in_lat'] as num?)?.toDouble(), // <--- UBAH CARA PARSING INI
    checkInLng: (json['check_in_lng'] as num?)?.toDouble(), // <--- UBAH CARA PARSING INI
    checkOutLat: (json['check_out_lat'] as num?)?.toDouble(), // <--- UBAH CARA PARSING INI
    checkOutLng: (json['check_out_lng'] as num?)?.toDouble(), // <--- UBAH CARA PARSING INI
    status: json['status'] as String?,
    alasanIzin: json['alasan_izin'] as String?,
    tanggalIzin: json['tanggal_izin'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    checkIn: parsedCheckIn,
    checkOut: parsedCheckOut,
  );
  }
}

class AbsenceToday {
  final String? tanggal;
  final DateTime? jamMasuk;
  final DateTime? jamKeluar;
  final String? alamatMasuk;
  final String? alamatKeluar;
  final String? status;
  final String? alasanIzin;

  AbsenceToday({
    this.tanggal,
    this.jamMasuk,
    this.jamKeluar,
    this.alamatMasuk,
    this.alamatKeluar,
    this.status,
    this.alasanIzin,
  });

  factory AbsenceToday.fromJson(Map<String, dynamic> json) {
    // Ambil data dari key 'data' jika ada, atau gunakan map itu sendiri
    // Ini berguna jika JSON dikirim dalam format { "message": "", "data": {...} }
    final Map<String, dynamic> data =
        json['data'] as Map<String, dynamic>? ?? json;

    // Untuk jamMasuk dan jamKeluar, kita perlu menggabungkan tanggal (attendance_date)
    // dengan waktu (check_in_time/check_out_time) untuk membuat objek DateTime.
    final String? attendanceDateStr = data['attendance_date'] as String?;

    DateTime? parsedJamMasuk;
    if (attendanceDateStr != null && data['check_in_time'] != null) {
      try {
        // Gabungkan tanggal dengan waktu masuk, tambahkan ':00' untuk detik
        parsedJamMasuk = DateTime.parse(
          '$attendanceDateStr ${data['check_in_time'] as String}:00',
        );
      } catch (e) {
        print('Error parsing jamMasuk: $e');
        parsedJamMasuk = null;
      }
    }

    DateTime? parsedJamKeluar;
    if (attendanceDateStr != null && data['check_out_time'] != null) {
      try {
        // Gabungkan tanggal dengan waktu keluar, tambahkan ':00' untuk detik
        parsedJamKeluar = DateTime.parse(
          '$attendanceDateStr ${data['check_out_time'] as String}:00',
        );
      } catch (e) {
        print('Error parsing jamKeluar: $e');
        parsedJamKeluar = null;
      }
    }

    return AbsenceToday(
      tanggal: data['attendance_date'] as String?,
      jamMasuk: parsedJamMasuk,
      jamKeluar: parsedJamKeluar,
      alamatMasuk: data['check_in_address'] as String?,
      alamatKeluar: data['check_out_address'] as String?,
      status: data['status'] as String?,
      alasanIzin: data['alasan_izin'] as String?,
    );
  }

  // Metode toJson (opsional, tambahkan jika Anda perlu mengonversi kembali ke JSON)
  Map<String, dynamic> toJson() {
    return {
      'attendance_date': tanggal,
      'check_in_time':
          jamMasuk != null ? DateFormat('HH:mm').format(jamMasuk!) : null,
      'check_out_time':
          jamKeluar != null ? DateFormat('HH:mm').format(jamKeluar!) : null,
      'check_in_address': alamatMasuk,
      'check_out_address': alamatKeluar,
      'status': status,
      'alasan_izin': alasanIzin,
    };
  }
}

class AbsenceStats {
  final int totalAbsen;
  final int totalMasuk;
  final int totalIzin;
  final bool sudahAbsenHariIni;

  AbsenceStats({
    required this.totalAbsen,
    required this.totalMasuk,
    required this.totalIzin,
    required this.sudahAbsenHariIni,
  });

  factory AbsenceStats.fromJson(Map<String, dynamic> json) {
    return AbsenceStats(
      totalAbsen: _parseIntFromDynamic(json['total_absen']) ?? 0, // Use helper
      totalMasuk: _parseIntFromDynamic(json['total_masuk']) ?? 0, // Use helper
      totalIzin: _parseIntFromDynamic(json['total_izin']) ?? 0, // Use helper
      sudahAbsenHariIni:
          json['sudah_absen_hari_ini'] as bool? ??
          false, // Added null-check and fallback
    );
  }
}

// --- Batch and Training Models ---
class Batch {
  final int id;
  final String batch_ke; // Corrected to match API response
  final String? startDate; // Made nullable
  final String? endDate; // Made nullable
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Training>? trainings; // Nested trainings from API response

  Batch({
    required this.id,
    required this.batch_ke,
    this.startDate, // Removed required
    this.endDate, // Removed required
    this.createdAt,
    this.updatedAt,
    this.trainings,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: _parseIntFromDynamic(json['id']) ?? 0, // Use helper
      batch_ke:
          json['batch_ke'] as String? ??
          'N/A', // Added null-aware cast and fallback
      startDate: json['start_date'] as String?, // Added null-aware cast
      endDate: json['end_date'] as String?, // Added null-aware cast
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      trainings:
          (json['trainings'] as List<dynamic>?)
              ?.map((e) => Training.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_ke': batch_ke,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'trainings': trainings?.map((e) => e.toJson()).toList(),
    };
  }
}

class Training {
  final int id;
  final String title;
  final String? description;
  final int? participantCount;
  final String? standard;
  final String? duration;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic>?
  units; // Assuming units and activities can be dynamic lists
  final List<dynamic>? activities;

  Training({
    required this.id,
    required this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
    this.units,
    this.activities,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: _parseIntFromDynamic(json['id']) ?? 0, // Use helper
      title:
          json['title'] as String? ??
          'N/A', // Added null-aware cast and fallback
      description: json['description'] as String?,
      participantCount: _parseIntFromDynamic(
        json['participant_count'],
      ), // Use helper
      standard: json['standard'] as String?,
      duration: json['duration'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      units: json['units'] as List<dynamic>?,
      activities: json['activities'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'participant_count': participantCount,
      'standard': standard,
      'duration': duration,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'units': units,
      'activities': activities,
    };
  }
}
