import 'dart:async';

import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/models/app_models.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PersonReportScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const PersonReportScreen({super.key, required this.refreshNotifier});

  @override
  State<PersonReportScreen> createState() => _PersonReportScreenState();
}

class _PersonReportScreenState extends State<PersonReportScreen> {
  final ApiService _apiService = ApiService();

  late Future<void> _reportDataFuture;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  int _presentCount = 0;
  int _absentCount = 0;
  int _lateInCount = 0;
  int _calculatedTotalBasisForAttendanceTimeOff =
      0; // Basis baru untuk Attendance dan Time Off
  String _totalWorkingHours = '0hr 0min';

  double _attendanceProgress = 0.0;
  double _timeOffProgress = 0.0;
  double _totalAbsenceLateProgress = 0.0; // Progres untuk total absen/terlambat

  @override
  void initState() {
    super.initState();
    _reportDataFuture = _fetchAndCalculateMonthlyReports();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      print(
        'PersonReportScreen: Refresh signal received, refreshing reports...',
      );
      setState(() {
        _reportDataFuture = _fetchAndCalculateMonthlyReports();
      });
      widget.refreshNotifier.value = false;
    }
  }

  Future<void> _fetchAndCalculateMonthlyReports() async {
    try {
      final ApiResponse<AbsenceStats> statsResponse =
          await _apiService.getAbsenceStats();
      if (statsResponse.statusCode == 200 && statsResponse.data != null) {
        final AbsenceStats stats = statsResponse.data!;
        setState(() {
          _presentCount = stats.totalMasuk;
          _absentCount = stats.totalIzin;
          _lateInCount = stats.totalAbsen;

          // Hitung basis untuk Attendance dan Time Off: hanya Hadir + Izin
          _calculatedTotalBasisForAttendanceTimeOff =
              _presentCount + _absentCount;

          // Perhitungan Progres untuk Attendance dan Time Off:
          // Dibagi hanya dari total hari Hadir dan Izin
          _attendanceProgress =
              _calculatedTotalBasisForAttendanceTimeOff > 0
                  ? _presentCount / _calculatedTotalBasisForAttendanceTimeOff
                  : 0.0;
          _timeOffProgress =
              _calculatedTotalBasisForAttendanceTimeOff > 0
                  ? _absentCount / _calculatedTotalBasisForAttendanceTimeOff
                  : 0.0;

          // Progress Bar "Absences/Late": selalu 100% jika ada absen, 0% jika tidak ada
          _totalAbsenceLateProgress = _lateInCount > 0 ? 1.0 : 0.0;
        });
      } else {
        print('Failed to get absence stats: ${statsResponse.message}');
        _updateSummaryCounts(0, 0, 0, '0hr 0min');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load summary: ${statsResponse.message}'),
            ),
          );
        }
      }

      // Bagian perhitungan Total Working Hours (tidak berubah)
      final lastDayOfMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      );
      final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
      final String endDate = DateFormat('yyyy-MM-dd').format(lastDayOfMonth);

      final ApiResponse<List<Absence>> historyResponse = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      Duration totalWorkingDuration = Duration.zero;
      if (historyResponse.statusCode == 200 && historyResponse.data != null) {
        for (var absence in historyResponse.data!) {
          if (absence.status?.toLowerCase() == 'masuk' &&
              absence.checkIn != null &&
              absence.checkOut != null) {
            try {
              final DateTime checkIn = absence.checkIn!;
              final DateTime checkOut = absence.checkOut!;

              Duration dailyDuration;
              if (checkOut.isBefore(checkIn)) {
                dailyDuration = checkOut
                    .add(const Duration(days: 1))
                    .difference(checkIn);
              } else {
                dailyDuration = checkOut.difference(checkIn);
              }
              totalWorkingDuration += dailyDuration;
            } catch (e) {
              print('Error calculating time for absence ID ${absence.id}: $e');
            }
          }
        }
      } else {
        print(
          'Failed to get absence history for working hours: ${historyResponse.message}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load working hours: ${historyResponse.message}',
              ),
            ),
          );
        }
      }

      final int totalHours = totalWorkingDuration.inHours;
      final int remainingMinutes = totalWorkingDuration.inMinutes.remainder(60);
      String formattedTotalWorkingHours =
          '${totalHours}hr ${remainingMinutes}min';

      setState(() {
        _totalWorkingHours = formattedTotalWorkingHours;
      });
    } catch (e) {
      print('Error fetching and calculating monthly reports: $e');
      _updateSummaryCounts(0, 0, 0, '0hr 0min');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred loading reports: $e')),
        );
      }
    }
  }

  // Parameter _actualTotalDays dihapus karena tidak lagi menjadi basis umum
  void _updateSummaryCounts(
    int present,
    int absent,
    int late,
    String totalHrs,
  ) {
    setState(() {
      _presentCount = present;
      _absentCount = absent;
      _lateInCount = late;
      _totalWorkingHours = totalHrs;

      // Hitung basis untuk Attendance dan Time Off: hanya Hadir + Izin
      _calculatedTotalBasisForAttendanceTimeOff = _presentCount + _absentCount;

      _attendanceProgress =
          _calculatedTotalBasisForAttendanceTimeOff > 0
              ? _presentCount / _calculatedTotalBasisForAttendanceTimeOff
              : 0.0;
      _timeOffProgress =
          _calculatedTotalBasisForAttendanceTimeOff > 0
              ? _absentCount / _calculatedTotalBasisForAttendanceTimeOff
              : 0.0;

      // Progress Bar "Absences/Late": selalu 100% jika ada absen, 0% jika tidak ada
      _totalAbsenceLateProgress = _lateInCount > 0 ? 1.0 : 0.0;
    });
  }

  // --- UI building methods (unchanged, kecuali bagian penjelasan) ---

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2101, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final DateTime newSelectedMonth = DateTime(picked.year, picked.month, 1);
      if (newSelectedMonth.year != _selectedMonth.year ||
          newSelectedMonth.month != _selectedMonth.month) {
        setState(() {
          _selectedMonth = newSelectedMonth;
          _reportDataFuture = _fetchAndCalculateMonthlyReports();
        });
      }
    }
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double progress,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<void>(
        future: _reportDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _selectMonth(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Text(
                                DateFormat(
                                  'MMMM yyyy',
                                ).format(_selectedMonth).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.textDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildOverviewCard(
                        title: 'Attendance',
                        value: '$_presentCount Day',
                        color: AppColors.primary,
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 10),
                      _buildOverviewCard(
                        title: 'Time Off',
                        value: '$_absentCount Day',
                        color: AppColors.accentOrange,
                        icon: Icons.event_busy_outlined,
                      ),
                      const SizedBox(width: 10),
                      _buildOverviewCard(
                        title: 'Total Absence',
                        value: '$_lateInCount Day',
                        color: AppColors.accentRed,
                        icon: Icons.access_time,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Implementasi View All untuk Progress jika diperlukan
                            },
                            child: const Text(
                              'View All',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildProgressBar(
                        label: 'Attendance',
                        progress: _attendanceProgress,
                        color: AppColors.primary,
                      ),
                      _buildProgressBar(
                        label: 'Time Off',
                        progress: _timeOffProgress,
                        color: AppColors.accentOrange,
                      ),
                      // Progress bar untuk Absences/Late
                      _buildProgressBar(
                        label: 'total absence',
                        progress: _totalAbsenceLateProgress,
                        color: AppColors.accentRed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Working Hour',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    DateFormat('EEE').format(DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd').format(DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Productive Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _totalWorkingHours,
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
                                    'Time at work',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _totalWorkingHours,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
