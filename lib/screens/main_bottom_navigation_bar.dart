import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/screens/attendance/request_screen.dart'; // Import RequestScreen
import 'package:absensi/screens/auth/profile_screen.dart';
import 'package:absensi/screens/home_screen.dart';
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
      ValueNotifier<bool>(false);
  // ValueNotifier for PersonReportScreen (now Analytics)
  static final ValueNotifier<bool> refreshReportsNotifier = ValueNotifier<bool>(
    false,
  );
  // NEW: ValueNotifier for Settings Screen
  static final ValueNotifier<bool> refreshSettingsNotifier =
      ValueNotifier<bool>(false);

  @override
  State<MainBottomNavigationBar> createState() =>
      _MainBottomNavigationBarState();
}

class _MainBottomNavigationBarState extends State<MainBottomNavigationBar> {
  int _selectedIndex = 0; // Start with Home tab (index 0)

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // HomeScreen (Index 0)
      HomeScreen(refreshNotifier: MainBottomNavigationBar.refreshHomeNotifier),
      // PersonReportScreen (now Analytics) (Index 1)
      PersonReportScreen(
        refreshNotifier: MainBottomNavigationBar.refreshReportsNotifier,
      ),
      // RequestScreen (Tombol tengah Floating Action Button) (Index 2)
      const RequestScreen(), // Mengganti AttendanceListScreen dengan RequestScreen
      // ProfileScreen for Settings (Index 3)
      ProfileScreen(
        refreshNotifier: MainBottomNavigationBar.refreshSettingsNotifier,
      ),
    ];
  }

  /// Handles the tap event on a BottomNavigationBarItem.
  ///
  /// Updates the [_selectedIndex] to switch the displayed screen in the IndexedStack.
  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    // Special handling for when navigating TO the Home tab (index 0)
    if (index == 0) {
      MainBottomNavigationBar.refreshHomeNotifier.value = true;
    }
    // Special handling for when navigating TO the Analytics tab (index 1)
    else if (index == 1) {
      MainBottomNavigationBar.refreshReportsNotifier.value = true;
    }
    // Special handling for when navigating TO the RequestScreen tab (index 2)
    // RequestScreen mungkin tidak memerlukan refreshNotifier jika datanya mandiri
    // atau di-refresh saat masuk. Jika memang perlu, Anda bisa menambahkan notifier khusus.
    // Untuk saat ini, kita asumsikan tidak memerlukan sinyal refresh dari sini.
    else if (index == 2) {
      // MainBottomNavigationBar.refreshAttendanceNotifier.value = true; // Tidak diperlukan untuk RequestScreen secara tipikal
    }
    // Special handling for when navigating TO the Settings tab (now index 3)
    else if (index == 3) {
      MainBottomNavigationBar.refreshSettingsNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => _onItemTapped(
              2,
            ), // Index untuk tombol tengah (sekarang RequestScreen)
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.format_list_bulleted, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex:
            _selectedIndex, // Pass the current selected index for highlighting
        onTap: _onItemTapped, // Pass the callback to handle tab taps
      ),
    );
  }
}
