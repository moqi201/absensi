// lib/screens/auth/forgot_password.dart

import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:absensi/routes/app_router.dart';
import 'package:absensi/widgets/custom_input_field.dart';
import 'package:absensi/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService(); // Instansiasi ApiService

  bool _isLoading = false;

  Future<void> _requestOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String email = _emailController.text.trim();
      // MEMANGGIL verifyOtp DENGAN OTP KOSONG SESUAI PERMINTAAN ANDA
      final response = await _apiService.forgotPassword(
        // <--- PERUBAHAN DI SINI
        email:
            email, // Mengirim OTP kosong/string kosong untuk memicu pengiriman
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'OTP berhasil dikirim.'),
            ),
          );
          // Navigasi ke layar Reset Password dengan email yang diinput
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.resetPassword,
            arguments: email, // Kirim email ke ResetPasswordScreen
          );
        }
      } else {
        String errorMessage = response.message ?? 'Gagal meminta OTP.';
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
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lupa Password"),
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
              const Text(
                "Masukkan email Anda untuk menerima kode verifikasi (OTP) untuk reset password.",
                style: TextStyle(fontSize: 16, color: AppColors.accentGreen),
              ),
              const SizedBox(height: 30),
              CustomInputField(
                controller: _emailController,
                hintText: 'Email',
                icon: Icons.email_outlined,
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                  : PrimaryButton(
                    label: 'Kirim Kode Verifikasi',
                    onPressed: _requestOtp,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
