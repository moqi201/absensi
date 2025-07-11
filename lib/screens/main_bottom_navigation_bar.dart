import 'package:absensi/screens/attendance/attendance_list_screen.dart';
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
  // NEW: ValueNotifier for the new 'Leave (up arrow)' screen.
  static final ValueNotifier<bool> refreshLeaveUpArrowNotifier =
      ValueNotifier<bool>(false);
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
      // HomeScreen
      HomeScreen(refreshNotifier: MainBottomNavigationBar.refreshHomeNotifier),
      // PersonReportScreen (now Analytics)
      PersonReportScreen(
        refreshNotifier: MainBottomNavigationBar.refreshReportsNotifier,
      ),
      // AttendanceListScreen (The custom "Leave" button in the middle)
      AttendanceListScreen(
        refreshNotifier: MainBottomNavigationBar.refreshAttendanceNotifier,
      ),
      // A new screen for the "Leave (up arrow)" button. You'll need to create this.
      // For now, I'll use ProfileScreen as a placeholder.
      ProfileScreen(
        refreshNotifier: MainBottomNavigationBar.refreshLeaveUpArrowNotifier,
      ),
      // A new screen for Settings. You'll need to create this.
      // For now, I'll use ProfileScreen as a placeholder.
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
    // Special handling for when navigating TO the custom Leave/Attendance tab (index 2)
    else if (index == 2) {
      MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
    }
    // Special handling for when navigating TO the Leave (up arrow) tab (index 3)
    else if (index == 3) {
      MainBottomNavigationBar.refreshLeaveUpArrowNotifier.value = true;
    }
    // Special handling for when navigating TO the Settings tab (index 4)
    else if (index == 4) {
      MainBottomNavigationBar.refreshSettingsNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex:
            _selectedIndex, // Pass the current selected index for highlighting
        onTap: _onItemTapped, // Pass the callback to handle tab taps
      ),
    );
  }
}
