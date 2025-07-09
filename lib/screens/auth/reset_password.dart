// lib/screens/reset_password_screen.dart

import 'dart:async';
import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:absensi/routes/app_router.dart';
import 'package:absensi/widgets/custom_input_field.dart';
import 'package:absensi/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // --- Variabel untuk Timer ---
  Timer? _timer;
  final int _startMinutes = 10; // Durasi OTP dalam menit
  int _currentSeconds = 0; // Detik yang tersisa dari menit saat ini
  bool _otpExpired = false; // Status OTP kadaluarsa

  @override
  void initState() {
    super.initState();
    // Jika OTP sudah dikirim sebelum masuk layar ini, mulai timer.
    // Jika layar ini adalah tempat OTP pertama kali dikirim, Anda mungkin ingin
    // memicu _resendOtp() di sini juga. Tapi dari konteks, sepertinya OTP
    // sudah dikirim di ForgotPasswordScreen.
    _startTimer();
  }

  // --- Fungsi Timer ---
  void _startTimer() {
    _otpExpired = false; // Reset status kadaluarsa
    _currentSeconds = _startMinutes * 60; // Set total detik
    _timer?.cancel(); // Pastikan timer sebelumnya dibatalkan jika ada
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds <= 0) {
        timer.cancel();
        setState(() {
          _otpExpired = true; // Set OTP kadaluarsa
        });
      } else {
        setState(() {
          _currentSeconds--; // Kurangi detik setiap 1 detik
        });
      }
    });
  }

  // Mengubah detik menjadi format MM:SS
  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // --- FUNGSI UTAMA UNTUK TOMBOL RESET PASSWORD ---
  Future<void> _resetPasswordProcess() async {
    if (_formKey.currentState!.validate()) {
      if (_otpExpired) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP telah kadaluarsa. Silakan minta OTP baru.'),
            ),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final String email = widget.email;
      final String otp = _otpController.text.trim();
      final String newPassword = _newPasswordController.text.trim();
      final String confirmPassword = _confirmPasswordController.text.trim();

      // --- Panggil langsung API resetPassword ---
      final resetResponse = await _apiService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );

      setState(() {
        _isLoading = false;
      });

      if (resetResponse.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resetResponse.message ?? 'Password reset successfully!',
              ),
            ),
          );
          Navigator.popUntil(context, ModalRoute.withName(AppRoutes.login));
        }
      } else {
        // Handle error dari resetPassword API
        String errorMessage =
            resetResponse.message ?? 'Failed to reset password.';
        if (resetResponse.errors != null) {
          resetResponse.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    }
  }

  // --- FUNGSI UNTUK MENGIRIM ULANG OTP ---
  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
    });

    // Panggil API forgotPassword untuk meminta OTP ulang
    final response = await _apiService.forgotPassword(email: widget.email);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'OTP resent successfully!'),
          ),
        );
        _startTimer(); // Mulai ulang timer setelah OTP baru dikirim
      }
    } else {
      String errorMessage = response.message ?? 'Failed to resend OTP.';
      if (response.errors != null) {
        response.errors!.forEach((key, value) {
          errorMessage += '\n$key: ${(value as List).join(', ')}';
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kode verifikasi telah dikirim ke **${widget.email}**. Masukkan kode dan password baru Anda.",
                style: const TextStyle(fontSize: 16, color: AppColors.primary),
              ),
              const SizedBox(height: 10),

              // --- Tampilan Timer ---
              Center(
                child:
                    _otpExpired
                        ? Text(
                          'OTP Kadaluarsa. Silakan minta ulang.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : Text(
                          'OTP berlaku dalam: ${_formatDuration(_currentSeconds)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                _currentSeconds < 60
                                    ? AppColors.error
                                    : AppColors.primary,
                          ),
                        ),
              ),
              const SizedBox(height: 20),

              // --- Urutan Input Field Baru ---
              CustomInputField(
                controller: _otpController,
                hintText: 'Kode Verifikasi (OTP)',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'OTP tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'OTP minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomInputField(
                controller: _newPasswordController,
                hintText: 'Password Baru',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: !_isNewPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password baru tidak boleh kosong';
                  }
                  if (value.length < 8) {
                    return 'Password minimal 8 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomInputField(
                controller: _confirmPasswordController,
                hintText: 'Konfirmasi Password Baru',
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: !_isConfirmPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi password tidak boleh kosong';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              Center(
                child: GestureDetector(
                  onTap: _isLoading || !_otpExpired ? null : _resendOtp,
                  child: Text(
                    "Tidak menerima kode? Kirim ulang OTP",
                    style: TextStyle(
                      color:
                          _isLoading || !_otpExpired
                              ? AppColors.primary
                              : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                  : PrimaryButton(
                    label: 'Reset Password',
                    onPressed: _resetPasswordProcess,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
