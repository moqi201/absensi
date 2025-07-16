import 'package:absensi/routes/app_router.dart';
import 'package:absensi/screens/attendance/request_screen.dart';
import 'package:absensi/screens/auth/forgot_password.dart';
import 'package:absensi/screens/auth/login_screen.dart';
import 'package:absensi/screens/auth/register_screen.dart';
import 'package:absensi/screens/auth/reset_password.dart';
import 'package:absensi/screens/main_bottom_navigation_bar.dart';
import 'package:absensi/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      initialRoute: AppRoutes.initial,
      routes: {
        AppRoutes.initial: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.main: (context) => MainBottomNavigationBar(),
        AppRoutes.request: (context) => RequestScreen(),
        // Menambahkan rute untuk forgotPassword
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        // Menambahkan rute untuk resetPassword
        AppRoutes.resetPassword: (context) {
          final String? email =
              ModalRoute.of(context)?.settings.arguments as String?;
          if (email != null) {
            return ResetPasswordScreen(email: email);
          }
          // Fallback jika email tidak disediakan (misalnya, navigasi langsung tanpa argumen)
          return const Text(
            'Error: Email tidak disediakan untuk reset password.',
          );
        },
        // AppRoutes.attendanceList: (context) => AttendanceListScreen(),
        // AppRoutes.report: (context) => const PersonReportScreen(),
        // AppRoutes.profile: (context) => const ProfileScreen(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}
