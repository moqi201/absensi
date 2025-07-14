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
    // Menggunakan Container untuk memberikan latar belakang berwarna dan sudut bulat
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 10.0, // Mengurangi margin horizontal agar lebih lebar
        vertical: 10.0,
      ), // Margin dari tepi layar
      decoration: BoxDecoration(
        color: AppColors.primary, // Latar belakang diubah menjadi merah
        borderRadius: BorderRadius.circular(30), // Sudut bulat penuh
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        // Memastikan konten di dalam juga mengikuti sudut bulat
        borderRadius: BorderRadius.circular(30),
        child: BottomAppBar(
          color:
              Colors
                  .transparent, // Jadikan BottomAppBar transparan karena Container sudah menangani warna
          elevation: 0, // Hilangkan bayangan default dari BottomAppBar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Item Home (Index 0)
              _buildNavItem(0, Icons.home, 'Home'),
              // Item Attendance (Index 1) - Menggunakan Icons.calendar_today
              _buildNavItem(
                1,
                Icons.calendar_today,
                '',
              ), // Tidak ada label untuk item ini
              // Item Report (Index 2) - Menggunakan Icons.bar_chart
              _buildNavItem(
                2,
                Icons.bar_chart, // Ikon untuk Report
                '',
              ), // Tidak ada label untuk item ini
              // Item Profile (Index 3) - Menggunakan Icons.person
              _buildNavItem(
                3,
                Icons.person,
                '',
              ), // Tidak ada label untuk item ini
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun item navigasi individu untuk BottomNavigationBar.
  ///
  /// [index] adalah indeks item navigasi.
  /// [icon] adalah ikon yang akan ditampilkan untuk item ini.
  /// [label] adalah teks label yang akan ditampilkan di bawah ikon.
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = (currentIndex == index);
    // Warna keemasan untuk latar belakang item yang dipilih
    // Color selectedItemColor = const Color(0xFFD4AF37); // Dihapus karena tidak digunakan untuk latar belakang

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index), // Meneruskan indeks yang ditekan
          borderRadius: BorderRadius.circular(25), // Sudut bulat untuk efek tap
          child: AnimatedContainer(
            // Menggunakan AnimatedContainer untuk transisi halus
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
              vertical: 18.0, // Ukuran vertikal tetap
              horizontal: 8.0, // Padding horizontal seragam untuk semua item
            ),
            // Dekorasi latar belakang kuning dihapus
            decoration: null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize:
                  MainAxisSize.min, // Menyusut agar sesuai dengan konten
              children: [
                Icon(
                  icon,
                  // Warna ikon: putih untuk yang dipilih, putih sedikit pudar untuk yang tidak dipilih
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 24,
                ),
                // Hanya tampilkan label jika item dipilih DAN label tidak kosong
                if (isSelected && label.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white, // Warna teks putih saat dipilih
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow:
                          TextOverflow
                              .ellipsis, // Potong teks jika terlalu panjang
                      maxLines: 1, // Batasi teks hanya pada satu baris
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
