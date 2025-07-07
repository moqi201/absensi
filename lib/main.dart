// lib/main.dart
import 'package:absensi/presentation/page/auth/login_page.dart';
import 'package:absensi/presentation/page/auth/register_page.dart';
import 'package:absensi/presentation/page/dashboard/dashboard_page.dart';
import 'package:absensi/presentation/page/history/history_page.dart';
import 'package:absensi/presentation/page/profil/edit_profile_page.dart';
import 'package:absensi/presentation/page/profil/profile_page.dart'
    hide ProfileProvider;
import 'package:absensi/providers/profile_provider.dart'; // Jalur yang sudah benar
import 'package:absensi/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:absensi/data/service/api_service.dart';
// **PERBAIKAN JALUR IMPOR BERIKUT:**
import 'package:absensi/providers/auth_provider.dart'; // Jalur diperbaiki
import 'package:absensi/providers/attendance_provider.dart'; // Jalur diperbaiki
import 'package:absensi/providers/theme_provider.dart'; // Jalur diperbaiki // Pastikan jalur ini benar untuk AppConstants

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final prefs = await SharedPreferences.getInstance();
  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => apiService),
        ChangeNotifierProvider(
          create:
              (context) =>
                  AuthProvider(Provider.of<ApiService>(context, listen: false)),
        ),
        ChangeNotifierProvider(
          create:
              (context) => AttendanceProvider(
                Provider.of<ApiService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => ProfileProvider(
                Provider.of<ApiService>(context, listen: false),
              ),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: themeProvider.themeMode,
          initialRoute: AppConstants.loginRoute,
          routes: {
            AppConstants.loginRoute: (context) =>  LoginPage(),
            AppConstants.registerRoute: (context) =>  RegisterPage(),
            AppConstants.dashboardRoute: (context) =>  DashboardPage(),
            AppConstants.historyRoute: (context) =>  HistoryPage(),
            AppConstants.profileRoute: (context) =>  ProfilePage(),
            AppConstants.editProfileRoute: (context) =>  EditProfilePage(),
          },
        );
      },
    );
  }
}
