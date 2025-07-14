// lib/screens/home/home_screen.dart (path mungkin perlu disesuaikan)
import 'dart:async';

import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/models/app_models.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:absensi/screens/main_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart'; // Untuk reverse geocoding
import 'package:geolocator/geolocator.dart'; // Untuk geolocation
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;
  const HomeScreen({super.key, required this.refreshNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  String _userName = 'User';
  String _profilePhotoUrl = ''; // New state for profile photo URL
  String _location = 'Getting Location...';
  String _currentDate = '';
  String _currentTime = '';
  Timer? _timer;

  AbsenceToday? _todayAbsence;
  AbsenceStats? _absenceStats;

  Position? _currentPosition;
  bool _permissionGranted = false;
  bool _isCheckingInOrOut =
      false; // Untuk mencegah multiple taps saat panggilan API

  // State untuk riwayat absensi
  List<Absence> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _determinePosition(); // Mulai pengambilan lokasi
    _loadUserData();
    _fetchAttendanceData(); // Ambil data absensi awal
    _fetchAttendanceHistory(); // Ambil data riwayat absensi

    widget.refreshNotifier.addListener(_handleRefreshSignal);

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDateTime(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      _fetchAttendanceData();
      _fetchAttendanceHistory(); // Refresh riwayat juga saat ada sinyal refresh
      _loadUserData(); // Also refresh user data for profile image/name
      widget.refreshNotifier.value = false; // Reset notifier setelah ditangani
    }
  }

  Future<void> _loadUserData() async {
    final ApiResponse<User> response = await _apiService.getProfile();
    if (response.statusCode == 200 && response.data != null) {
      setState(() {
        _userName = response.data!.name;
        _profilePhotoUrl =
            response.data!.profile_photo ?? ''; // Get profile photo URL
      });
    } else {
      debugPrint('Failed to load user profile: ${response.message}');
      setState(() {
        _userName = 'User'; // Default jika profil gagal dimuat
        _profilePhotoUrl = ''; // Clear photo URL on error
      });
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      // Format tanggal sesuai gambar: "Oct 26, 2022 - Wednesday"
      _currentDate = DateFormat('MMM dd, yyyy - EEEE').format(now);
      // Format waktu sesuai gambar: "09:00 AM"
      _currentTime = DateFormat('hh:mm a').format(now);
    });
  }

  // New method to get dynamic greeting based on time
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 20) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Tes apakah layanan lokasi diaktifkan.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Layanan lokasi tidak diaktifkan, jangan lanjutkan
      // mengakses posisi dan minta pengguna
      // aplikasi untuk mengaktifkan layanan lokasi.
      if (mounted) {
        _showErrorDialog('Location services are disabled. Please enable them.');
      }
      setState(() {
        _location = 'Location services disabled';
        _permissionGranted = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Izin ditolak, lain kali Anda bisa mencoba
        // meminta izin lagi (ini juga tempat
        // Android's shouldShowRequestPermissionRationale
        // mengembalikan true. Menurut pedoman Android
        // aplikasi Anda harus menampilkan UI penjelasan sekarang.
        if (mounted) {
          _showErrorDialog(
            'Location permissions are denied. Please grant them in settings.',
          );
        }
        setState(() {
          _location = 'Location permissions denied';
          _permissionGranted = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Izin ditolak selamanya, tangani dengan tepat.
      if (mounted) {
        _showErrorDialog(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }
      setState(() {
        _location = 'Location permissions permanently denied';
        _permissionGranted = false;
      });
      return;
    }

    // Ketika kita mencapai di sini, izin diberikan dan kita bisa
    // terus mengakses posisi perangkat.
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _permissionGranted = true;
      });
      await _getAddressFromLatLng(position);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        _showErrorDialog('Failed to get current location: $e');
      }
      setState(() {
        _location = 'Failed to get location';
        _permissionGranted = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      // Menggunakan format yang lebih ringkas seperti di gambar: Sub-lokasi, Kota, Negara
      Placemark place = placemarks[0];
      setState(() {
        _location = "${place.subLocality}, ${place.locality}, ${place.country}";
      });
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      setState(() {
        _location = 'Address not found';
      });
    }
  }

  Future<void> _fetchAttendanceData() async {
    // Ambil catatan absensi hari ini
    final ApiResponse<AbsenceToday> todayAbsenceResponse =
        await _apiService.getAbsenceToday();
    if (todayAbsenceResponse.statusCode == 200 &&
        todayAbsenceResponse.data != null) {
      setState(() {
        _todayAbsence = todayAbsenceResponse.data;
      });
    } else {
      debugPrint(
        'Failed to get today\'s absence: ${todayAbsenceResponse.message}',
      );
      setState(() {
        _todayAbsence = null; // Reset jika tidak ada catatan atau error
      });
    }

    // Ambil statistik absensi
    final ApiResponse<AbsenceStats> statsResponse =
        await _apiService.getAbsenceStats();
    if (statsResponse.statusCode == 200 && statsResponse.data != null) {
      setState(() {
        _absenceStats = statsResponse.data;
      });
    } else {
      debugPrint('Failed to get absence stats: ${statsResponse.message}');
      setState(() {
        _absenceStats = null; // Reset jika tidak ada statistik atau error
      });
    }
  }

  // Method baru untuk mengambil riwayat absensi
  Future<void> _fetchAttendanceHistory() async {
    final ApiResponse<List<Absence>> historyResponse =
        await _apiService.getAbsenceHistory();
    if (historyResponse.statusCode == 200 && historyResponse.data != null) {
      setState(() {
        _attendanceHistory = historyResponse.data!;
      });
    } else {
      debugPrint(
        'Failed to get attendance history: ${historyResponse.message}',
      );
      setState(() {
        _attendanceHistory = [];
      });
    }
  }

  Future<void> _handleCheckIn() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog(
        'Location not available. Please ensure location services are enabled and permissions are granted.',
      );
      await _determinePosition(); // Coba dapatkan lokasi lagi
      return;
    }
    if (_isCheckingInOrOut) return; // Mencegah double tap

    setState(() {
      _isCheckingInOrOut = true;
    });

    try {
      final String formattedAttendanceDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      // Format waktu saat ini ke string 'HH:mm' untuk API
      final String formattedCheckInTime = DateFormat(
        'HH:mm',
      ).format(DateTime.now());

      final ApiResponse<Absence> response = await _apiService.checkIn(
        checkInLat: _currentPosition!.latitude,
        checkInLng: _currentPosition!.longitude,
        checkInAddress: _location,
        status: 'masuk', // Asumsi 'masuk' untuk check-in reguler
        attendanceDate: formattedAttendanceDate,
        checkInTime: formattedCheckInTime,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        _fetchAttendanceData(); // Refresh home setelah check-in
        _fetchAttendanceHistory(); // Refresh history setelah check-in
        MainBottomNavigationBar.refreshAttendanceNotifier.value =
            true; // Sinyal AttendanceListScreen
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          _showErrorDialog('Check In Failed: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred during check-in: $e');
      }
    } finally {
      setState(() {
        _isCheckingInOrOut = false;
      });
    }
  }

  Future<void> _handleCheckOut() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog(
        'Location not available. Please ensure location services are enabled and permissions are granted.',
      );
      await _determinePosition(); // Coba dapatkan lokasi lagi
      return;
    }
    if (_isCheckingInOrOut) return; // Mencegah double tap

    setState(() {
      _isCheckingInOrOut = true;
    });

    try {
      final String formattedAttendanceDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now());
      // Format waktu saat ini ke string 'HH:mm' untuk API
      final String formattedCheckOutTime = DateFormat(
        'HH:mm',
      ).format(DateTime.now());

      final ApiResponse<Absence> response = await _apiService.checkOut(
        checkOutLat: _currentPosition!.latitude,
        checkOutLng: _currentPosition!.longitude,
        checkOutAddress: _location,
        attendanceDate: formattedAttendanceDate,
        checkOutTime: formattedCheckOutTime,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        _fetchAttendanceData(); // Refresh home setelah check-out
        _fetchAttendanceHistory(); // Refresh history setelah check-out
        MainBottomNavigationBar.refreshAttendanceNotifier.value =
            true; // Sinyal AttendanceListScreen
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          _showErrorDialog('Check Out Failed: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred during check-out: $e');
      }
    } finally {
      setState(() {
        _isCheckingInOrOut = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.background,
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
    );
  }

  // Mengubah _calculateWorkingHours untuk menerima AbsenceToday
  String _calculateWorkingHours(AbsenceToday? absence) {
    if (absence == null || absence.jamMasuk == null) {
      return '00:00:00';
    }

    final DateTime checkInDateTime = absence.jamMasuk!;
    DateTime endDateTime;

    if (absence.jamKeluar != null) {
      endDateTime = absence.jamKeluar!;
    } else {
      endDateTime = DateTime.now();
    }

    final Duration duration = endDateTime.difference(checkInDateTime);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCheckedIn = _todayAbsence?.jamMasuk != null;
    final bool hasCheckedOut = _todayAbsence?.jamKeluar != null;

    // Tentukan status tombol utama
    String mainButtonText = '';
    IconData mainButtonIcon = Icons.fingerprint; // Ikon default
    Color mainButtonColor = AppColors.primary;
    VoidCallback? mainButtonOnTap;

    if (!hasCheckedIn) {
      mainButtonText = 'Check In';
      mainButtonIcon = Icons.fingerprint;
      mainButtonColor = AppColors.primary;
      mainButtonOnTap = _handleCheckIn;
    } else if (hasCheckedIn && !hasCheckedOut) {
      mainButtonText = 'Check Out';
      mainButtonIcon = Icons.fingerprint;
      mainButtonColor = AppColors.primary;
      mainButtonOnTap = _handleCheckOut;
    } else {
      mainButtonText = 'Done';
      mainButtonIcon = Icons.check_circle_outline;
      mainButtonColor = Colors.grey; // Abu-abu jika sudah check in dan out
      mainButtonOnTap = null;
    }

    // Nonaktifkan tombol jika sedang dalam proses check in/out
    if (_isCheckingInOrOut) {
      mainButtonOnTap = null;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Menggunakan CustomScrollView dan SliverAppBar untuk header yang dinamis
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200, // Ketinggian saat expanded
                floating: false,
                pinned: true, // AppBar tetap terlihat saat di-scroll ke atas
                automaticallyImplyLeading:
                    false, // Hilangkan tombol back default
                backgroundColor: AppColors.primary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20.0,
                        50.0,
                        20.0,
                        0.0,
                      ), // Sesuaikan padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getGreeting()},', // Updated: Dynamic greeting
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Updated: Display actual profile image
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.3),
                                  image:
                                      _profilePhotoUrl.isNotEmpty
                                          ? DecorationImage(
                                            image: NetworkImage(
                                              _profilePhotoUrl.startsWith(
                                                    'http',
                                                  )
                                                  ? _profilePhotoUrl
                                                  : 'https://appabsensi.mobileprojp.com/public/$_profilePhotoUrl',
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                          : const DecorationImage(
                                            image: NetworkImage(
                                              'https://placehold.co/50x50/ffffff/000000?text=P', // Placeholder if no image
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          // Waktu saat ini (besar) - Already correctly updating
                          Text(
                            _currentTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Tanggal saat ini - Already correctly updating
                          Text(
                            _currentDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _location, // Lokasi saat ini
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Isi konten di bawah AppBar
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20), // Jarak disesuaikan
                    // Tombol Check In/Out Utama (Lingkaran Besar)
                    Center(
                      child: GestureDetector(
                        onTap: mainButtonOnTap,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mainButtonColor.withOpacity(0.1),
                            border: Border.all(
                              color: mainButtonColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: mainButtonColor.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                mainButtonIcon,
                                color: mainButtonColor,
                                size: 60,
                              ),
                              const SizedBox(height: 10),
                              _isCheckingInOrOut
                                  ? const CircularProgressIndicator(
                                    color: AppColors.primary,
                                  )
                                  : Text(
                                    mainButtonText,
                                    style: TextStyle(
                                      color: mainButtonColor,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Tiga kartu statistik absensi kecil (Check In, Check Out, Total Hrs)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAttendanceStatCard(
                          title: 'Check In',
                          value:
                              _todayAbsence?.jamMasuk != null
                                  ? DateFormat(
                                    'HH:mm',
                                  ).format(_todayAbsence!.jamMasuk!)
                                  : '--:--',
                          icon: Icons.access_time,
                          iconColor: AppColors.primary,
                        ),
                        _buildAttendanceStatCard(
                          title: 'Check Out',
                          value:
                              _todayAbsence?.jamKeluar != null
                                  ? DateFormat(
                                    'HH:mm',
                                  ).format(_todayAbsence!.jamKeluar!)
                                  : '--:--',
                          icon: Icons.access_time_filled,
                          iconColor: AppColors.primary,
                        ),
                        _buildAttendanceStatCard(
                          title: 'Total Hrs',
                          value: _calculateWorkingHours(_todayAbsence),
                          icon: Icons.timelapse,
                          iconColor: AppColors.primary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    // Header Riwayat Absensi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Attendance History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        // TextButton(
                        //   onPressed: () {
                        //     // Ini akan memicu refresh di AttendanceListScreen melalui Bottom Nav Bar
                        //     MainBottomNavigationBar
                        //         .refreshAttendanceNotifier
                        //         .value = true;
                        //   },
                        //   child: const Text(
                        //     'See More',
                        //     style: TextStyle(color: AppColors.primary),
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Daftar Riwayat Absensi
                    if (_attendanceHistory.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No attendance history available.'),
                        ),
                      )
                    else
                      // Tampilkan 5 item terbaru dari riwayat absensi
                      ..._attendanceHistory.take(5).map((absence) {
                        return _buildAttendanceHistoryItem(absence);
                      }),
                    const SizedBox(
                      height: 80,
                    ), // Untuk memberikan ruang bagi tombol "Request"
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget baru untuk kartu statistik absensi kecil (Check In, Check Out, Total Hrs)
  Widget _buildAttendanceStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Card(
        color: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Pusatkan untuk kartu-kartu ini
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20, // Sedikit lebih kecil untuk ketiga ini
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk menampilkan item riwayat absensi
  Widget _buildAttendanceHistoryItem(Absence absence) {
    // Warna dan ikon default untuk entri absensi biasa
    Color cardColor = AppColors.primary; // Warna utama untuk kartu absensi
    Color textColor = Colors.white; // Teks putih di latar belakang berwarna
    IconData statusIcon = Icons.check_circle_outline; // Ikon default

    // Cek jika status adalah 'izin'
    if (absence.status == 'izin') {
      cardColor = Colors.orange; // Warna oranye untuk cuti
      textColor = Colors.white; // Teks putih untuk kartu izin
      statusIcon = Icons.info_outline; // Ikon untuk izin
    }

    // Tentukan teks lokasi yang akan ditampilkan
    String locationText = 'Lokasi tidak tersedia';
    if (absence.status == 'izin') {
      locationText = absence.alasanIzin ?? 'Tidak ada alasan';
    } else {
      locationText = absence.checkInAddress ?? 'Alamat tidak diketahui';
    }

    // Tentukan hari dalam seminggu
    String dayOfWeek = '';
    if (absence.attendanceDate != null) {
      dayOfWeek = DateFormat(
        'EEE',
      ).format(absence.attendanceDate!); // e.g., 'Sen'
    }

    return Card(
      color: AppColors.background, // Latar belakang kartu putih
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Tanggal dan Hari (dengan latar belakang berwarna)
          Container(
            width: 80, // Lebar tetap untuk tanggal
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              color: cardColor, // Menggunakan warna dinamis
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(10),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(absence.attendanceDate!), // Tanggal
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor, // Menggunakan warna dinamis
                  ),
                ),
                Text(
                  DateFormat('MMM').format(absence.attendanceDate!), // Bulan
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor, // Menggunakan warna dinamis
                  ),
                ),
                Text(
                  dayOfWeek,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor, // Menggunakan warna dinamis
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kondisional untuk menampilkan detail berdasarkan status
                  if (absence.status == 'izin')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 18,
                                  color: Colors.orange, // Warna ikon izin
                                ), // Ikon status
                                const SizedBox(width: 5),
                                Text(
                                  absence.status?.toUpperCase() ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange, // Warna teks izin
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ), // Ikon 'X'
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          absence.alasanIzin ??
                              'Tidak ada alasan', // Tampilkan alasan izin
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              DateFormat(
                                'dd MMMM yyyy',
                              ).format(absence.attendanceDate!),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    // Tampilan default untuk check-in/check-out
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Check In',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  absence.checkIn != null
                                      ? DateFormat(
                                        'HH:mm',
                                      ).format(absence.checkIn!)
                                      : '--:--',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Check Out',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  absence.checkOut != null
                                      ? DateFormat(
                                        'HH:mm',
                                      ).format(absence.checkOut!)
                                      : '--:--',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Hours',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _calculateWorkingHoursForHistory(absence),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ), // Ikon 'X'
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                absence.checkInAddress ??
                                    'Alamat tidak diketahui',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi baru untuk menghitung jam kerja dari model Absence (untuk riwayat)
  String _calculateWorkingHoursForHistory(Absence absence) {
    if (absence.checkIn == null || absence.checkOut == null) {
      return '00:00:00'; // Jika belum check-out atau data tidak lengkap
    }

    try {
      final Duration duration = absence.checkOut!.difference(absence.checkIn!);
      final int hours = duration.inHours;
      final int minutes = duration.inMinutes.remainder(60);
      final int seconds = duration.inSeconds.remainder(60);

      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('Error calculating working hours for history: $e');
      return 'N/A';
    }
  }
}
