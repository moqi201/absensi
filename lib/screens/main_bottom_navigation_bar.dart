import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/screens/attendance/attendance_list_screen.dart'; // Digunakan untuk item "Documents"
import 'package:absensi/screens/attendance/request_screen.dart'; // Digunakan untuk FAB tengah
import 'package:absensi/screens/auth/profile_screen.dart'; // Digunakan untuk item "Notifications"
import 'package:absensi/screens/home_screen.dart';
import 'package:absensi/screens/reports/person_report_screen.dart'; // Digunakan untuk item "Tools/Utilities"
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
  static final ValueNotifier<bool> refreshReportsNotifier = ValueNotifier<bool>(
    false,
  ); // Akan digunakan untuk item "Tools/Utilities"
  static final ValueNotifier<bool> refreshSettingsNotifier =
      ValueNotifier<bool>(false); // Akan digunakan untuk item "Notifications"

  @override
  State<MainBottomNavigationBar> createState() =>
      _MainBottomNavigationBarState();
}

class _MainBottomNavigationBarState extends State<MainBottomNavigationBar> {
  // _selectedIndex akan merepresentasikan indeks layar yang ditampilkan di IndexedStack.
  // 0: Home
  // 1: Tools/Utilities (PersonReportScreen)
  // 2: Documents (AttendanceListScreen)
  // 3: Notifications (ProfileScreen)
  int _selectedIndex = 0; // Mulai dengan tab Home (indeks 0)

  // State untuk mengontrol tampilan FAB (tambah atau silang)
  bool _isRequestScreenOpen = false;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // Index 0: Home
      HomeScreen(refreshNotifier: MainBottomNavigationBar.refreshHomeNotifier),
      // Index 1: Tools/Utilities (placeholder PersonReportScreen)
      PersonReportScreen(
        refreshNotifier: MainBottomNavigationBar.refreshReportsNotifier,
      ),
      // Index 2: Documents (placeholder AttendanceListScreen)
      AttendanceListScreen(
        refreshNotifier: MainBottomNavigationBar.refreshAttendanceNotifier,
      ),
      // Index 3: Notifications (placeholder ProfileScreen)
      ProfileScreen(
        refreshNotifier: MainBottomNavigationBar.refreshSettingsNotifier,
      ),
    ];
  }

  /// Menangani event tap pada BottomNavigationBarItem.
  ///
  /// Memperbarui [_selectedIndex] untuk mengganti layar yang ditampilkan di IndexedStack.
  void _onItemTapped(int index) {
    // `index` yang diterima di sini adalah indeks visual dari CustomBottomNavigationBar (0, 1, 2, 3).
    // Ini langsung cocok dengan indeks di `_widgetOptions`.
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    // Penanganan khusus untuk menyegarkan layar
    if (index == 0) {
      MainBottomNavigationBar.refreshHomeNotifier.value = true;
    } else if (index == 1) { // Tools
      MainBottomNavigationBar.refreshReportsNotifier.value = true;
    } else if (index == 2) { // Documents
      MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
    } else if (index == 3) { // Notifications
      MainBottomNavigationBar.refreshSettingsNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_isRequestScreenOpen) {
            // Jika RequestScreen terbuka, tutup
            Navigator.of(context).pop();
          } else {
            // Jika RequestScreen tidak terbuka, buka
            setState(() {
              _isRequestScreenOpen = true; // Set state FAB ke 'X'
            });
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RequestScreen()),
            ).then((_) {
              // Ketika RequestScreen ditutup, kembalikan state FAB ke '+'
              setState(() {
                _isRequestScreenOpen = false;
              });
            });
          }
        },
        backgroundColor: Colors.pink, // Warna FAB sesuai gambar
        shape: const CircleBorder(),
        child: Icon(
          _isRequestScreenOpen ? Icons.close : Icons.add, // Ikon FAB berubah
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex, // Meneruskan indeks layar yang sedang aktif
        onTap: _onItemTapped, // Meneruskan callback untuk menangani tap tab
      ),
    );
  }
}
