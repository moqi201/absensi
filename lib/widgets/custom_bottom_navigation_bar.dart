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
    return ClipRRect( // Menggunakan ClipRRect untuk memberikan sudut bulat pada seluruh BottomAppBar
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(25), // Sudut atas yang bulat
        bottom: Radius.circular(25), // Sudut bawah yang bulat
      ),
      child: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(), // Hanya lekukan untuk FAB
        notchMargin: 6.0, // Jarak antara FAB dan BottomAppBar
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Home (Index 0)
            _buildNavItem(0, Icons.home, 'Home'),
            // Profile (Index 1) - Menggunakan Icons.person sebagai contoh
            _buildNavItem(1, Icons.person, 'Profile'),
            // Placeholder for the FAB (center item) - tidak ada item di sini, hanya SizedBox
            const SizedBox(width: 48), // Memberikan ruang untuk FAB
            // Heart (Index 2) - Menggunakan Icons.favorite_border sebagai contoh
            _buildNavItem(2, Icons.favorite_border, 'Likes'), // Indeks visual 2
            // Notifications (Index 3) - Menggunakan Icons.notifications sebagai contoh
            _buildNavItem(3, Icons.notifications, 'Notifs'), // Indeks visual 3
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    // `index` di sini adalah indeks visual item di BottomAppBar (0, 1, 2, 3).
    // `currentIndex` adalah `_selectedIndex` dari MainBottomNavigationBar.
    // Item disorot jika indeks visualnya cocok dengan `_selectedIndex`.
    bool isSelected = (currentIndex == index);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index), // Meneruskan indeks visual (0,1,2,3)
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.pink : Colors.grey, // Warna ikon disesuaikan
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.pink : Colors.grey, // Warna teks disesuaikan
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis, // Memastikan teks dipotong dengan elipsis jika terlalu panjang
                  maxLines: 1, // Membatasi teks hanya pada satu baris
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
