import 'dart:async';

import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/models/app_models.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
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

  late Future<void>
  _reportDataFuture; // Changed to void as we update state directly
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  // Summary counts for the selected month - Initialized directly to avoid LateInitializationError
  int _presentCount = 0;
  int _absentCount =
      0; // Will now include all non-regular attendance types (izin)
  int _lateInCount = 0; // Mapped from total_absen in AbsenceStats
  int _totalWorkingDaysInMonth =
      0; // Will be derived from presentCount for simplicity
  String _totalWorkingHours = '0hr';

  // Data for Pie Chart (will be repurposed for progress bars or removed if not needed)
  List<PieChartSectionData> _pieChartSections = [];

  // New state variables for Progress section (mock data for now)
  final double _taskProgress = 0.8; // 80%
  final double _completedTaskProgress = 0.6; // 60%
  final double _hoursProgress = 0.75; // 75%

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

  // Fetches attendance data and calculates monthly summaries
  Future<void> _fetchAndCalculateMonthlyReports() async {
    try {
      // 1. Fetch Absence Stats for summary counts
      final ApiResponse<AbsenceStats> statsResponse =
          await _apiService.getAbsenceStats();
      if (statsResponse.statusCode == 200 && statsResponse.data != null) {
        final AbsenceStats stats = statsResponse.data!;
        setState(() {
          _presentCount = stats.totalMasuk;
          _absentCount =
              stats
                  .totalIzin; // Assuming total_izin covers all types of absences/leaves
          _lateInCount =
              stats.totalAbsen; // Assuming total_absen covers late entries
          _totalWorkingDaysInMonth =
              stats
                  .totalMasuk; // Simplified: Total working days = total present days
        });
      } else {
        print('Failed to get absence stats: ${statsResponse.message}');
        _updateSummaryCounts(0, 0, 0, 0, '0hr'); // Reset counts on error
        _updatePieChartData(0, 0, 0); // Reset pie chart data on error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load summary: ${statsResponse.message}'),
            ),
          );
        }
        return; // Exit if stats fetching fails
      }

      // 2. Fetch Absence History for total working hours calculation
      final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
      final String endDate = DateFormat('yyyy-MM-dd').format(
        DateTime(
          _selectedMonth.year,
          _selectedMonth.month + 1,
          0,
        ), // Last day of the month
      );

      final ApiResponse<List<Absence>> historyResponse = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      Duration totalWorkingDuration = Duration.zero;
      if (historyResponse.statusCode == 200 && historyResponse.data != null) {
        for (var absence in historyResponse.data!) {
          // Only count working hours for 'masuk' entries that have both checkIn and checkOut
          if (absence.status?.toLowerCase() ==
                  'masuk' && // Safely call toLowerCase
              absence.checkIn != null && // Added null check for checkIn
              absence.checkOut != null) {
            totalWorkingDuration += absence.checkOut!.difference(
              absence.checkIn!, // Added null assertion for checkIn
            );
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

      // Update pie chart data after all counts are finalized
      _updatePieChartData(_presentCount, _absentCount, _lateInCount);
    } catch (e) {
      print('Error fetching and calculating monthly reports: $e');
      _updateSummaryCounts(0, 0, 0, 0, '0hr'); // Reset counts on error
      _updatePieChartData(0, 0, 0); // Reset pie chart data on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred loading reports: $e')),
        );
      }
    }
  }

  // Updates the state variables for summary counts
  void _updateSummaryCounts(
    int present,
    int absent,
    int late,
    int totalWorkingDays,
    String totalHrs,
  ) {
    setState(() {
      _presentCount = present;
      _absentCount = absent;
      _lateInCount = late;
      _totalWorkingDaysInMonth = totalWorkingDays;
      _totalWorkingHours = totalHrs;
    });
  }

  // New method to update pie chart data (will be adapted or removed if no pie chart)
  void _updatePieChartData(int presentCount, int absentCount, int lateInCount) {
    // This method might not be directly used if we are not displaying a pie chart.
    // However, keeping it for now in case pie chart is re-introduced or data is needed.
    final total = presentCount + absentCount + lateInCount;
    if (total == 0) {
      setState(() {
        _pieChartSections = [];
      });
      return;
    }

    const Color presentColor = Colors.green;
    const Color absentColor = Colors.red;
    const Color lateColor = Colors.orange;

    setState(() {
      _pieChartSections = [
        if (presentCount > 0)
          PieChartSectionData(
            color: presentColor,
            value: presentCount.toDouble(),
            title: '${(presentCount / total * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _buildBadge('Present', presentColor),
            badgePositionPercentageOffset: .98,
          ),
        if (absentCount > 0)
          PieChartSectionData(
            color: absentColor,
            value: absentCount.toDouble(),
            title: '${(absentCount / total * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _buildBadge('Absent', absentColor),
            badgePositionPercentageOffset: .98,
          ),
        if (lateInCount > 0)
          PieChartSectionData(
            color: lateColor,
            value: lateInCount.toDouble(),
            title: '${(lateInCount / total * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _buildBadge('Late', lateColor),
            badgePositionPercentageOffset: .98,
          ),
      ];
    });
  }

  // Helper for PieChart badges (labels) - will be removed if no pie chart
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Method to show month picker (only month and year)
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2101, 12, 31),
      initialDatePickerMode: DatePickerMode.year, // Start with year selection
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
          _reportDataFuture =
              _fetchAndCalculateMonthlyReports(); // Trigger re-fetch
        });
      }
    }
  }

  // Helper widget to build summary cards (adapted for the new design)
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

  // Helper widget for progress bars
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
        title: const Text('Analytics'), // Changed title to Analytics
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          // Add back button
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
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

          // Data is loaded, build the UI
          return SingleChildScrollView(
            // Use SingleChildScrollView for overall scrollability
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
                // Overview Cards
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
                        title: 'Late',
                        value:
                            '$_lateInCount Hour', // Assuming lateInCount is in hours or can be converted
                        color: AppColors.accentRed,
                        icon: Icons.access_time,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Progress Section
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
                              // Handle View All for Progress
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
                        label: 'Task',
                        progress: _taskProgress,
                        color: AppColors.primary,
                      ),
                      _buildProgressBar(
                        label: 'Completed Task',
                        progress: _completedTaskProgress,
                        color: AppColors.accentGreen,
                      ),
                      _buildProgressBar(
                        label: 'Hours',
                        progress: _hoursProgress,
                        color: AppColors.accentRed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Total Working Hour (Bottom Section)
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
                                    DateFormat('EEE').format(
                                      DateTime.now(),
                                    ), // Current day of week
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd').format(
                                      DateTime.now(),
                                    ), // Current day number
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
                                    _totalWorkingHours, // Re-using total working hours for "Productive Time"
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
                                    _totalWorkingHours, // Re-using total working hours for "Time at work"
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
                const SizedBox(height: 20), // Add some bottom padding
              ],
            ),
          );
        },
      ),
    );
  }
}
