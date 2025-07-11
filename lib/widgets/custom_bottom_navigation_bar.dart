import 'package:absensi/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// A customizable and reusable BottomNavigationBar widget.
///
/// This widget provides a standard bottom navigation bar layout
/// with predefined items for Home, Analytics, Leave (custom), Leave (apply), and Settings.
/// It takes `currentIndex` and an `onTap` callback to manage
/// its state and handle navigation.
class CustomBottomNavigationBar extends StatelessWidget {
  /// The index of the currently selected tab.
  final int currentIndex;

  /// Callback function invoked when a tab is tapped.
  /// The integer parameter `index` represents the index of the tapped tab.
  final Function(int) onTap;

  /// Creates a [CustomBottomNavigationBar].
  ///
  /// [currentIndex] is required and determines which icon is highlighted.
  /// [onTap] is required and is called when a navigation item is tapped.
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      // selectedItemColor: AppColors.primary, // Color for selected icon/label - will handle custom
      unselectedItemColor: Colors.grey, // Color for unselected icons/labels
      backgroundColor: Colors.white, // Background color of the navigation bar
      type:
          BottomNavigationBarType
              .fixed, // Ensures all labels are always visible
      items: <BottomNavigationBarItem>[
        // Home
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home,
            color: currentIndex == 0 ? AppColors.primary : Colors.grey,
          ),
          label: 'Home',
        ),
        // Analytics (previously Reports)
        BottomNavigationBarItem(
          icon: Icon(
            Icons.bar_chart,
            color: currentIndex == 1 ? AppColors.primary : Colors.grey,
          ),
          label: 'Analytics',
        ),
        // Custom Leave/Attendance button (the one with the green circle)
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(10), // Adjust padding as needed
            decoration: BoxDecoration(
              color:
                  currentIndex == 2
                      ? AppColors.primary
                      : Colors.grey.withOpacity(
                        0.2,
                      ), // Green when selected, light grey when unselected
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons
                  .format_list_bulleted, // Ikon mirip daftar, atau ikon yang paling mendekati di gambar
              color: Colors.white, // Icon always white for this custom button
            ),
          ),
          label: 'Leave', // Label for this custom button
        ),
        // Leave (Up arrow icon) - previously Profile
        BottomNavigationBarItem(
          icon: Icon(
            Icons.arrow_upward,
            color: currentIndex == 3 ? AppColors.primary : Colors.grey,
          ),
          label: 'Leave', // Label for the second leave button
        ),
        // Settings (previously empty slot)
        BottomNavigationBarItem(
          icon: Icon(
            Icons.settings,
            color: currentIndex == 4 ? AppColors.primary : Colors.grey,
          ),
          label: 'Settings',
        ),
      ],
    );
  }
}
