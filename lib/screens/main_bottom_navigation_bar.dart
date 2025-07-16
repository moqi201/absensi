import 'package:absensi/screens/attendance/attendance_list_screen.dart'; // Digunakan untuk item "Documents"
import 'package:absensi/screens/auth/profile_screen.dart'; // Digunakan untuk item "Notifications"
import 'package:absensi/screens/home_screen.dart'; // Digunakan untuk item "Tools/Utilities"
import 'package:absensi/screens/reports/person_report_screen.dart';
import 'package:absensi/widgets/custom_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class MainBottomNavigationBar extends StatefulWidget {
  const MainBottomNavigationBar({super.key});

  // FIX: Declare ValueNotifiers as static final members of the StatefulWidget itself
  // This makes them globally accessible using MainBottomNavigationBar.notifierName
  static final ValueNotifier<bool> refreshHomeNotifier = ValueNotifier<bool>(
    false,
  );
  static final ValueNotifier<bool> refreshAttendanceNotifier =
      ValueNotifier<bool>(false); // Akan digunakan untuk item "Documents"
  // static final ValueNotifier<bool> refreshReportsNotifier = ValueNotifier<bool>(
  //   false,
  // ); // Akan digunakan untuk item "Tools/Utilities"
  static final ValueNotifier<bool> refreshSettingsNotifier =
      ValueNotifier<bool>(false); // Akan digunakan untuk item "Notifications"

  @override
  State<MainBottomNavigationBar> createState() =>
      _MainBottomNavigationBarState();
}

class _MainBottomNavigationBarState extends State<MainBottomNavigationBar> {
  // _selectedIndex akan merepresentasikan indeks layar yang ditampilkan di IndexedStack.
  // 0: Home
  // 1: Documents (AttendanceListScreen) - Sesuai dengan Icons.calendar_today di CustomBottomNavigationBar
  // 2: Notifications (ProfileScreen) - Sesuai dengan Icons.person di CustomBottomNavigationBar
  int _selectedIndex = 0; // Mulai dengan tab Home (indeks 0)

  // _isRequestScreenOpen dan logika terkait FloatingActionButton dihapus

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // Index 0: Home
      HomeScreen(refreshNotifier: MainBottomNavigationBar.refreshHomeNotifier),
      // Index 1: Documents (AttendanceListScreen)
      AttendanceListScreen(
        refreshNotifier: MainBottomNavigationBar.refreshAttendanceNotifier,
      ),
      // PersonReportScreen(
      //   refreshNotifier: MainBottomNavigationBar.refreshReportsNotifier,
      // ),

      // Index 2: Notifications (ProfileScreen)
      ProfileScreen(
        refreshNotifier: MainBottomNavigationBar.refreshSettingsNotifier,
      ),

      // PersonReportScreen (sebelumnya Index 1) dihapus dari navigasi bawah
    ];
  }

  /// Menangani event tap pada BottomNavigationBarItem.
  ///
  /// Memperbarui [_selectedIndex] untuk mengganti layar yang ditampilkan di IndexedStack.
  void _onItemTapped(int index) {
    // `index` yang diterima di sini adalah indeks visual dari CustomBottomNavigationBar (0, 1, 2).
    // Ini langsung cocok dengan indeks di `_widgetOptions` yang baru.
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    // Penanganan khusus untuk menyegarkan layar
    if (index == 0) {
      MainBottomNavigationBar.refreshHomeNotifier.value = true;
    } else if (index == 1) {
      // Documents (sekarang di indeks 1)
      MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
    } else if (index == 2) {
      // Notifications (sekarang di indeks 2)
      MainBottomNavigationBar.refreshSettingsNotifier.value = true;
    }
    // Logika untuk index 3 (sebelumnya PersonReportScreen) dihapus
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      // FloatingActionButton dan floatingActionButtonLocation dihapus
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex:
            _selectedIndex, // Meneruskan indeks layar yang sedang aktif
        onTap: _onItemTapped, // Meneruskan callback untuk menangani tap tab
      ),
    );
  }
}
