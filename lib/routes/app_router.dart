// Named routes config
class AppRoutes {
  static const initial = '/splash_screen';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';
  static const attendanceList = '/attendance/list';
  static const request = '/request';
  static const forgotPassword = '/forgot_password'; // Menambahkan rute ini
  static const resetPassword = '/reset_password'; // Menambahkan rute ini
  // The following routes are removed as they are now managed internally by MainScreen's IndexedStack
  // static const report = '/report';
  // static const profile = '/profile';
}
