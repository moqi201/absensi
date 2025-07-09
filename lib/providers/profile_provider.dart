// import 'package:absensi/data/models/batch_model.dart';
// import 'package:absensi/data/models/profile_model.dart';
// import 'package:absensi/data/models/training_model.dart';
// import 'package:absensi/data/service/api_service.dart';
// import 'package:flutter/material.dart';

// class ProfileProvider with ChangeNotifier {
//   final ApiService _apiService;

//   bool _isLoading = false;
//   Profile? _userProfile;
//   List<Batch>? _batches;
//   List<Training>? _trainings;
//   String? _errorMessage; // Tambahkan properti error message

//   ProfileProvider(this._apiService);

//   bool get isLoading => _isLoading;
//   Profile? get userProfile => _userProfile;
//   List<Batch>? get batches => _batches;
//   List<Training>? get trainings => _trainings;
//   String? get errorMessage => _errorMessage; // Getter untuk error message

//   // Metode untuk mengambil data profil pengguna
//   Future<void> fetchProfile() async {
//     _isLoading = true;
//     _errorMessage = null; // Reset error message
//     notifyListeners();
//     try {
//       final response = await _apiService.getProfile();
//       if (response != null &&
//           response.success == true &&
//           response.data != null) {
//         _userProfile = response.data;
//       } else {
//         _errorMessage = response?.message ?? 'Gagal memuat profil.';
//         print('Failed to fetch profile: $_errorMessage');
//       }
//     } catch (e) {
//       _errorMessage = 'Terjadi kesalahan saat mengambil profil: $e';
//       print('Error fetching profile: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Metode untuk mengambil daftar batch
//   Future<void> fetchBatches() async {
//     _isLoading = true;
//     _errorMessage = null; // Reset error message
//     notifyListeners();
//     try {
//       final response = await _apiService.getAllBatches();
//       if (response != null &&
//           response.success == true &&
//           response.data != null) {
//         _batches = response.data;
//       } else {
//         _errorMessage = response?.message ?? 'Gagal memuat daftar batch.';
//         print('Failed to fetch batches: $_errorMessage');
//       }
//     } catch (e) {
//       _errorMessage = 'Terjadi kesalahan saat mengambil daftar batch: $e';
//       print('Error fetching batches: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Metode untuk mengambil daftar pelatihan
//   Future<void> fetchTrainings() async {
//     _isLoading = true;
//     _errorMessage = null; // Reset error message
//     notifyListeners();
//     try {
//       final response = await _apiService.getAllTrainings();
//       if (response != null &&
//           response.success == true &&
//           response.data != null) {
//         _trainings = response.data;
//       } else {
//         _errorMessage = response?.message ?? 'Gagal memuat daftar pelatihan.';
//         print('Failed to fetch trainings: $_errorMessage');
//       }
//     } catch (e) {
//       _errorMessage = 'Terjadi kesalahan saat mengambil daftar pelatihan: $e';
//       print('Error fetching trainings: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Tambahkan metode updateProfile
//   Future<bool> updateProfile({
//     required String name,
//     required String email,
//     int? batchId,
//     int? trainingId,
//   }) async {
//     _isLoading = true;
//     _errorMessage = null; // Reset error message
//     notifyListeners();
//     try {
//       final response = await _apiService.editProfile(
//         name,
//         email,
//         batchId: batchId,
//         trainingId: trainingId,
//       );
//       if (response != null &&
//           response.success == true &&
//           response.data != null) {
//         // Update userProfile lokal setelah berhasil di API
//         _userProfile = response.data;
//         return true;
//       } else {
//         _errorMessage = response?.message ?? 'Gagal memperbarui profil.';
//         print('Failed to update profile: $_errorMessage');
//         return false;
//       }
//     } catch (e) {
//       _errorMessage = 'Terjadi kesalahan saat memperbarui profil: $e';
//       print('Error updating profile: $e');
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
