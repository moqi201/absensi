import 'package:absensi/data/models/absen_model.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:flutter/material.dart';

class AttendanceProvider with ChangeNotifier {
  final ApiService _apiService;
  AbsenRecord? _todayAbsen;
  List<AbsenRecord>? _historyAbsen;
  AbsenStatistic? _absenStatistic;
  bool _isLoading = false;
  String? _errorMessage;

  AttendanceProvider(this._apiService);

  AbsenRecord? get todayAbsen => _todayAbsen;
  List<AbsenRecord>? get historyAbsen => _historyAbsen;
  AbsenStatistic? get absenStatistic => _absenStatistic;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTodayAbsen() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Beri tahu bahwa state loading dimulai

    try {
      final response = await _apiService.getAbsenToday();
      if (response != null && response.success == true) {
        _todayAbsen = response.data;
      } else {
        _errorMessage = response?.message ?? 'Gagal mengambil absen hari ini';
      }
    } catch (e) {
      _errorMessage = e.toString(); // Tangani exception jaringan/parsing
    } finally {
      _isLoading = false;
      notifyListeners(); // Beri tahu setelah semua state diperbarui (sukses/gagal)
    }
  }

  Future<bool> checkIn({
    required String lat,
    required String lng,
    required String address,
    required String status,
    String? alasanIzin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Beri tahu bahwa state loading dimulai

    try {
      final response = await _apiService.absenCheckIn(
        checkInLat: lat,
        checkInLng: lng,
        checkInAddress: address,
        status: status,
        alasanIzin: alasanIzin,
      );

      if (response != null && response.success == true) {
        _todayAbsen = response.data; // Perbarui absen hari ini
        // fetchAbsenStatistic() akan memanggil notifyListeners() sendiri
        // jadi tidak perlu memanggil notifyListeners() di sini lagi setelah itu
        await fetchAbsenStatistic();
        return true;
      } else {
        _errorMessage = response?.message ?? 'Absen masuk gagal';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // Beri tahu setelah semua state diperbarui
    }
  }

  Future<bool> checkOut({
    required String lat,
    required String lng,
    required String address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Beri tahu bahwa state loading dimulai

    try {
      final response = await _apiService.absenCheckOut(
        checkOutLat: lat,
        checkOutLng: lng,
        checkOutAddress: address,
      );

      if (response != null && response.success == true) {
        _todayAbsen = response.data; // Perbarui absen hari ini
        await fetchAbsenStatistic(); // Memperbarui statistik
        return true;
      } else {
        _errorMessage = response?.message ?? 'Absen pulang gagal';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // Beri tahu setelah semua state diperbarui
    }
  }

  Future<void> fetchHistoryAbsen() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Beri tahu bahwa state loading dimulai

    try {
      final response = await _apiService.getHistoryAbsen();
      if (response != null && response.success == true) {
        _historyAbsen = response.data;
      } else {
        _errorMessage = response?.message ?? 'Gagal mengambil riwayat absen';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Beri tahu setelah semua state diperbarui
    }
  }

  Future<void> fetchAbsenStatistic() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Beri tahu bahwa state loading dimulai

    try {
      final response = await _apiService.getAbsenStatistic();
      if (response != null && response.success == true) {
        _absenStatistic = response.data;
      } else {
        _errorMessage = response?.message ?? 'Gagal mengambil statistik absen';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Beri tahu setelah semua state diperbarui
    }
  }

  Future<bool> deleteAbsen(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Beri tahu bahwa state loading dimulai

    try {
      final response = await _apiService.deleteAbsen(id);
      if (response != null && response.success == true) {
        // Metode fetch di bawah ini sudah memanggil notifyListeners() sendiri
        await fetchHistoryAbsen();
        await fetchTodayAbsen();
        await fetchAbsenStatistic();
        return true;
      } else {
        _errorMessage = response?.message ?? 'Gagal menghapus absen';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // Beri tahu setelah semua state diperbarui
    }
  }
}
