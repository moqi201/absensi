import 'package:absensi/data/models/user_model.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:flutter/material.dart';


class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._apiService) {
    _loadCurrentUserAndToken();
  }

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  Future<void> _loadCurrentUserAndToken() async {
    _token = await ApiService.getToken();
    _currentUser = await ApiService.getCurrentUser();
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required int batchId,
    required int trainingId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.register(
      name,
      email,
      password,
      batchId,
      trainingId,
    );
    _isLoading = false;

    if (response != null && response.success == true) {
      _token = response.data?.token;
      _currentUser = response.data?.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response?.message ?? 'Registrasi gagal';
      if (response?.errors != null) {
        _errorMessage = (response!.errors!.values.expand((e) => e).join('\n'));
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.login(email, password);
    _isLoading = false;

    if (response != null && response.success == true) {
      _token = response.data?.token;
      _currentUser = response.data?.user;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response?.message ?? 'Login gagal';
      if (response?.errors != null) {
        _errorMessage = (response!.errors!.values.expand((e) => e).join('\n'));
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _apiService.logout();
    _token = null;
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
