// lib/screens/home_screen.dart

import 'dart:async';

import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/models/app_models.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:absensi/screens/attendance/request_screen.dart';
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
      widget.refreshNotifier.value = false; // Reset notifier setelah ditangani
    }
  }

  Future<void> _loadUserData() async {
    final ApiResponse<User> response = await _apiService.getProfile();
    if (response.statusCode == 200 && response.data != null) {
      setState(() {
        _userName = response.data!.name;
      });
    } else {
      debugPrint('Failed to load user profile: ${response.message}');
      setState(() {
        _userName = 'User'; // Default jika profil gagal dimuat
      });
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _currentDate = DateFormat('EEEE, dd MMMM yyyy').format(now);
      _currentTime = DateFormat('HH:mm:ss').format(now);
    });
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
                                  const Text(
                                    'Good Morning,',
                                    style: TextStyle(
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_none,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _currentDate, // Tanggal saat ini
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
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
                    const SizedBox(height: 10),
                    // Kartu Check In dan Check Out (dua kolom)
                    Row(
                      children: [
                        _buildCheckInOutCard(
                          icon: Icons.check_circle_outline,
                          label: 'Check In',
                          time:
                              _todayAbsence?.jamMasuk != null
                                  ? DateFormat(
                                    'HH:mm',
                                  ).format(_todayAbsence!.jamMasuk!)
                                  : '--:--',
                          statusText: hasCheckedIn ? 'Early' : 'Not Checked In',
                          statusColor:
                              hasCheckedIn ? Colors.green : Colors.grey,
                          onTap:
                              hasCheckedIn
                                  ? null
                                  : _handleCheckIn, // Hanya bisa check in jika belum check in
                          isEnabled: !hasCheckedIn && !_isCheckingInOrOut,
                        ),
                        const SizedBox(width: 16),
                        _buildCheckInOutCard(
                          icon: Icons.logout_outlined,
                          label: 'Check Out',
                          time:
                              _todayAbsence?.jamKeluar != null
                                  ? DateFormat(
                                    'HH:mm',
                                  ).format(_todayAbsence!.jamKeluar!)
                                  : '--:--',
                          statusText:
                              hasCheckedOut ? 'Done' : 'Not Checked Out',
                          statusColor:
                              hasCheckedOut ? Colors.grey : Colors.grey,
                          onTap:
                              hasCheckedIn && !hasCheckedOut
                                  ? _handleCheckOut
                                  : null, // Hanya bisa check out jika sudah check in dan belum check out
                          isEnabled:
                              hasCheckedIn &&
                              !hasCheckedOut &&
                              !_isCheckingInOrOut,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Kartu Statistik Kecil (Absence dan Total Attended)
                    Row(
                      children: [
                        _buildSmallStatCard(
                          title: 'Absence',
                          value: _absenceStats?.totalIzin.toString() ?? '0',
                          subtitle: DateFormat('MMMM').format(DateTime.now()),
                          icon: Icons.person_remove_alt_1,
                          iconColor: AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildSmallStatCard(
                          title: 'Total Attended',
                          value: _absenceStats?.totalMasuk.toString() ?? '0',
                          subtitle: DateFormat('MMMM').format(DateTime.now()),
                          icon: Icons.check_circle_outline,
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
                        TextButton(
                          onPressed: () {
                            // Ini akan memicu refresh di AttendanceListScreen melalui Bottom Nav Bar
                            MainBottomNavigationBar
                                .refreshAttendanceNotifier
                                .value = true;
                          },
                          child: const Text(
                            'See More',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
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
          // Tombol Request di bagian bawah
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestScreen()),
                  );
                  if (result == true) {
                    _fetchAttendanceData();
                    _fetchAttendanceHistory(); // Refresh history setelah request
                    MainBottomNavigationBar.refreshAttendanceNotifier.value =
                        true;
                  }
                },
                icon: const Icon(Icons.add_task, color: AppColors.primary),
                label: const Text(
                  'Request',
                  style: TextStyle(color: AppColors.primary, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk kartu Check In/Check Out
  Widget _buildCheckInOutCard({
    required IconData icon,
    required String label,
    required String time,
    required String statusText,
    required Color statusColor,
    VoidCallback? onTap,
    required bool isEnabled,
  }) {
    return Expanded(
      child: Card(
        color: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: statusColor, size: 24),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget baru untuk kartu statistik kecil (Absence, Total Attended)
  Widget _buildSmallStatCard({
    required String title,
    required String value,
    required String subtitle,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
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
    Color cardColor = AppColors.primary.withOpacity(0.1);
    Color textColor = AppColors.primary;
    IconData statusIcon = Icons.check_circle_outline; // Default icon

    // Cek jika status adalah 'izin'
    if (absence.status == 'izin') {
      cardColor = Colors.orange.withOpacity(0.1); // Warna oranye untuk cuti
      textColor = Colors.orange;
      statusIcon = Icons.event_busy_outlined; // Ikon cuti
    }

    String day =
        absence.attendanceDate != null
            ? DateFormat('dd').format(absence.attendanceDate!)
            : '--';
    String dayOfWeek =
        absence.attendanceDate != null
            ? DateFormat('EEE').format(absence.attendanceDate!)
            : '---';
    String locationText = absence.checkInAddress ?? 'Unknown Location';

    return Card(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cardColor, // Menggunakan warna dinamis
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor, // Menggunakan warna dinamis
                    ),
                  ),
                  Text(
                    dayOfWeek,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor, // Menggunakan warna dinamis
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kondisional untuk menampilkan detail berdasarkan status
                  if (absence.status == 'izin')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              statusIcon,
                              size: 18,
                              color: textColor,
                            ), // Ikon status
                            const SizedBox(width: 5),
                            Text(
                              absence.status?.toUpperCase() ?? 'N/A',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
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
                                  ),
                                ),
                              ],
                            ),
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
                                locationText,
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
          ],
        ),
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
