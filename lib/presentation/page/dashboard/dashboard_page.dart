import 'package:absensi/core/utils/date_formatter.dart';
import 'package:absensi/main.dart'; // Mungkin ini berisi AppConstants atau konfigurasi lain
import 'package:absensi/providers/attendance_provider.dart';
import 'package:absensi/providers/auth_provider.dart';
import 'package:absensi/providers/profile_provider.dart';
import 'package:absensi/providers/theme_provider.dart';
import 'package:absensi/routes/app_router.dart'; // Asumsi AppConstants ada di sini
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';// <--- TAMBAHKAN BARIS INI

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<void> _initDataFuture;
  Position? _currentPosition;
  String _currentAddress = "Mencari lokasi...";
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initDataFuture = _loadData();
  }

  Future<void> _loadData() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    await attendanceProvider.fetchTodayAbsen();
    await attendanceProvider.fetchAbsenStatistic();
    await profileProvider.fetchProfile();
    await _determinePosition(); // Get location after fetching absen status
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentAddress = "Layanan lokasi dinonaktifkan.";
      });
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentAddress = "Izin lokasi ditolak.";
        });
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentAddress = "Izin lokasi ditolak permanen.";
      });
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    setState(() {
      _currentAddress = "Mendapatkan lokasi...";
    });
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _getAddressFromLatLng(_currentPosition!);
    } catch (e) {
      setState(() {
        _currentAddress = "Gagal mendapatkan lokasi: $e";
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Gagal mendapatkan alamat: $e";
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
      _addMarker(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        'currentLocation',
        'Lokasi Anda',
      );
    }
  }

  void _addMarker(LatLng position, String markerId, String title) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: position,
          infoWindow: InfoWindow(title: title),
        ),
      );
    });
  }

  Future<void> _handleCheckIn({
    String status = 'masuk',
    String? alasanIzin,
  }) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lokasi belum tersedia. Mohon tunggu.')),
      );
      return;
    }

    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    bool success = await attendanceProvider.checkIn(
      lat: _currentPosition!.latitude.toString(),
      lng: _currentPosition!.longitude.toString(),
      address: _currentAddress,
      status: status,
      alasanIzin: alasanIzin,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Absen masuk berhasil!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attendanceProvider.errorMessage ?? 'Absen masuk gagal'),
        ),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lokasi belum tersedia. Mohon tunggu.')),
      );
      return;
    }

    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    bool success = await attendanceProvider.checkOut(
      lat: _currentPosition!.latitude.toString(),
      lng: _currentPosition!.longitude.toString(),
      address: _currentAddress,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Absen pulang berhasil!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            attendanceProvider.errorMessage ?? 'Absen pulang gagal',
          ),
        ),
      );
      // If error is "Sudah absen pulang", refresh data
      if (attendanceProvider.errorMessage?.contains("Sudah absen pulang") ??
          false) {
        await attendanceProvider.fetchTodayAbsen();
      }
    }
  }

  void _showIzinDialog() {
    final TextEditingController alasanController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Ajukan Izin'),
            content: TextField(
              controller: alasanController,
              decoration: InputDecoration(labelText: 'Alasan Izin'),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleCheckIn(
                    status: 'izin',
                    alasanIzin: alasanController.text,
                  );
                },
                child: Text('Ajukan'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    ); // ThemeProvider digunakan di sini

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Absensi'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.of(
                context,
              ).pushReplacementNamed(AppConstants.loginRoute);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                profileProvider.userProfile?.name ??
                    authProvider.currentUser?.name ??
                    'Pengguna',
              ), // Menggunakan profileProvider
              accountEmail: Text(
                profileProvider.userProfile?.email ??
                    authProvider.currentUser?.email ??
                    'email@example.com', // Menggunakan profileProvider
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (profileProvider.userProfile?.name ??
                              authProvider.currentUser?.name)
                          ?.substring(0, 1)
                          .toUpperCase() ??
                      'P',
                  style: TextStyle(fontSize: 40.0),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Riwayat Absensi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppConstants.historyRoute);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profil Pengguna'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppConstants.profileRoute);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await authProvider.logout();
                Navigator.of(
                  context,
                ).pushReplacementNamed(AppConstants.loginRoute);
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: _initDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${profileProvider.userProfile?.name ?? authProvider.currentUser?.name ?? 'Pengguna'}!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tanggal Hari Ini: ${DateFormatter.formatDate(DateTime.now())}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Absen Hari Ini',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          attendanceProvider.isLoading
                              ? Center(child: CircularProgressIndicator())
                              : (attendanceProvider.todayAbsen != null
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status: ${attendanceProvider.todayAbsen!.status}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      if (attendanceProvider
                                              .todayAbsen!
                                              .checkInTime !=
                                          null)
                                        Text(
                                          'Check-in: ${DateFormatter.formatTime(attendanceProvider.todayAbsen!.checkInTime!)}',
                                        ),
                                      if (attendanceProvider
                                              .todayAbsen!
                                              .checkInAddress !=
                                          null)
                                        Text(
                                          'Lokasi Masuk: ${attendanceProvider.todayAbsen!.checkInAddress!}',
                                        ),
                                      if (attendanceProvider
                                              .todayAbsen!
                                              .checkOutTime !=
                                          null)
                                        Text(
                                          'Check-out: ${DateFormatter.formatTime(attendanceProvider.todayAbsen!.checkOutTime!)}',
                                        ),
                                      if (attendanceProvider
                                              .todayAbsen!
                                              .checkOutAddress !=
                                          null)
                                        Text(
                                          'Lokasi Pulang: ${attendanceProvider.todayAbsen!.checkOutAddress!}',
                                        ),
                                      if (attendanceProvider
                                                  .todayAbsen!
                                                  .alasanIzin !=
                                              null &&
                                          attendanceProvider
                                                  .todayAbsen!
                                                  .status ==
                                              'izin')
                                        Text(
                                          'Alasan Izin: ${attendanceProvider.todayAbsen!.alasanIzin!}',
                                        ),
                                    ],
                                  )
                                  : Text('Belum ada absen hari ini.')),
                          SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton.icon(
                                onPressed:
                                    attendanceProvider
                                                .todayAbsen
                                                ?.checkInTime ==
                                            null
                                        ? () => _handleCheckIn(status: 'masuk')
                                        : null, // Disable if already checked in
                                icon: Icon(Icons.login),
                                label: Text('Absen Masuk'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed:
                                    attendanceProvider
                                                    .todayAbsen
                                                    ?.checkInTime !=
                                                null &&
                                            attendanceProvider
                                                    .todayAbsen
                                                    ?.checkOutTime ==
                                                null
                                        ? _handleCheckOut
                                        : null, // Enable only if checked in but not checked out
                                icon: Icon(Icons.logout),
                                label: Text('Absen Pulang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton.icon(
                              onPressed:
                                  attendanceProvider.todayAbsen?.checkInTime ==
                                              null &&
                                          attendanceProvider
                                                  .todayAbsen
                                                  ?.status !=
                                              'izin'
                                      ? _showIzinDialog
                                      : null, // Allow izin if not checked in or already izin
                              icon: Icon(Icons.note_add),
                              label: Text('Ajukan Izin'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statistik Absen',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          attendanceProvider.isLoading
                              ? Center(child: CircularProgressIndicator())
                              : (attendanceProvider.absenStatistic != null
                                  ? Column(
                                    children: [
                                      ListTile(
                                        leading: Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        title: Text('Hadir'),
                                        trailing: Text(
                                          '${attendanceProvider.absenStatistic!.totalHadir ?? 0}',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      ListTile(
                                        leading: Icon(
                                          Icons.info,
                                          color: Colors.orange,
                                        ),
                                        title: Text('Izin'),
                                        trailing: Text(
                                          '${attendanceProvider.absenStatistic!.totalIzin ?? 0}',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      ListTile(
                                        leading: Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                        title: Text('Alpha'),
                                        trailing: Text(
                                          '${attendanceProvider.absenStatistic!.totalAlpha ?? 0}',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ],
                                  )
                                  : Text('Statistik absen tidak tersedia.')),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Lokasi Saat Ini:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(_currentAddress, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child:
                        _currentPosition == null
                            ? Center(child: CircularProgressIndicator())
                            : GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                zoom: 15.0,
                              ),
                              markers: _markers,
                            ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
