import 'dart:async';

import 'package:absensi/data/models/app_models.dart'; // Make sure this import is correct and points to your actual models
import 'package:absensi/data/service/api_service.dart'; // Make sure this import is correct
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Placeholder for your AppColors (Adjust based on your actual colors) ---
// This should be in 'app_colors.dart'
class AppColors {
  static const Color primary = Color(0xFF4CAF50); // Green
  static const Color accentOrange = Color(0xFFFFA726); // Orange
  static const Color accentRed = Color(0xFFEF5350); // Red
  static const Color accentGreen = Color(0xFF66BB6A); // Green
  static const Color background = Color(0xFFF5F5F5); // Light grey
  static const Color lightOrangeBackground = Color(
    0xFFFFECB3,
  ); // Lighter orange
  static const Color textDark = Color(0xFF212121); // Dark grey text
  static const Color cardShadow = Color(0x20000000); // Shadow color
  static const Color error = Color(0xFFD32F2F); // Red for error
}

// --- Placeholder for your MainBottomNavigationBar (Adjust if needed) ---
// This should be in 'main_bottom_navigation_bar.dart'
class MainBottomNavigationBar extends StatelessWidget {
  static ValueNotifier<bool> refreshHomeNotifier = ValueNotifier<bool>(false);

  const MainBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder as it's not directly used in this file's UI
  }
}
// -------------------------------------------------------------------------

class AttendanceListScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const AttendanceListScreen({super.key, required this.refreshNotifier});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Absence>> _attendanceFuture;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _fetchAndFilterAttendances();
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
        'AttendanceListScreen: Refresh signal received, refreshing list...',
      );
      _refreshList();
      widget.refreshNotifier.value = false;
    }
  }

  Future<List<Absence>> _fetchAndFilterAttendances() async {
    final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
    final String endDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

    try {
      final ApiResponse<List<Absence>> response = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      if (response.statusCode == 200 && response.data != null) {
        final List<Absence> fetchedAbsences = response.data!;
        // Sort by created_at date in descending order (latest first)
        fetchedAbsences.sort((a, b) {
          final DateTime? aCreatedAt =
              a.createdAt != null
                  ? DateTime.tryParse(a.createdAt!.toIso8601String())
                  : null; // Ensure DateTime for sorting
          final DateTime? bCreatedAt =
              b.createdAt != null
                  ? DateTime.tryParse(b.createdAt!.toIso8601String())
                  : null; // Ensure DateTime for sorting

          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;
          return bCreatedAt.compareTo(aCreatedAt);
        });
        return fetchedAbsences;
      } else {
        throw Exception(response.message ?? 'Failed to load attendance data');
      }
    } catch (e) {
      print('Error fetching and filtering attendance list: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendance: $e')),
        );
      }
      return [];
    }
  }

  Future<void> _refreshList() async {
    setState(() {
      _attendanceFuture = _fetchAndFilterAttendances();
    });
  }

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
        });
        _refreshList();
      }
    }
  }

  String _calculateWorkingHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null) {
      return '00:00:00';
    }

    DateTime endDateTime = checkOut ?? DateTime.now();

    final Duration duration = endDateTime.difference(checkIn);

    if (duration.isNegative) {
      return '00:00:00';
    }

    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildAttendanceTile(Absence absence) {
    Color barColor;
    Color statusPillColor;
    Color cardBackgroundColor = AppColors.background;
    Color timeTextColor;

    bool isRequestType = absence.status?.toLowerCase() == 'izin';

    if (isRequestType) {
      barColor = AppColors.accentOrange;
      statusPillColor = AppColors.accentOrange;
      cardBackgroundColor = AppColors.lightOrangeBackground;
      timeTextColor = Colors.black;
    } else {
      if (absence.status?.toLowerCase() == 'late') {
        barColor = AppColors.accentRed;
        statusPillColor = AppColors.accentRed;
        timeTextColor = AppColors.accentRed;
      } else {
        barColor = AppColors.accentGreen;
        statusPillColor = AppColors.accentGreen;
        timeTextColor = AppColors.accentGreen;
      }
    }

    bool showCheckIcon = absence.status?.toLowerCase() == 'masuk';

    DateTime? displayDate;
    if (isRequestType) {
      try {
        if (absence.createdAt != null) {
          displayDate = absence.createdAt; // Use the already parsed DateTime
        }
      } catch (e) {
        print('Error handling createdAt for request: ${absence.createdAt}, $e');
      }
    } else {
      try {
        if (absence.attendanceDate != null) {
          displayDate = DateTime.tryParse(
            absence.attendanceDate!,
          ); // Parse string from model
        }
      } catch (e) {
        print('Error parsing attendanceDate: ${absence.attendanceDate}, $e');
      }
    }

    final String formattedDate =
        displayDate != null
            ? DateFormat('E, MMM d, yyyy').format(displayDate)
            : 'N/A';

    return Card(
      color: cardBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5.0,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isRequestType
                                    ? statusPillColor
                                    : statusPillColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              if (showCheckIcon)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              Text(
                                isRequestType
                                    ? 'IZIN'
                                    : absence.status?.toUpperCase() ?? 'N/A',
                                style: TextStyle(
                                  color:
                                      isRequestType
                                          ? Colors.white
                                          : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isRequestType)
                      Row(
                        children: [
                          _buildTimeColumn(
                            absence.checkInTime ?? 'N/A',
                            'Check In',
                            timeTextColor,
                          ),
                          const SizedBox(width: 20),
                          _buildTimeColumn(
                            absence.checkOutTime ?? 'N/A',
                            'Check Out',
                            timeTextColor,
                          ),
                          const SizedBox(width: 20),
                          _buildTimeColumn(
                            _calculateWorkingHours(
                              absence.checkIn,
                              absence.checkOut,
                            ),
                            'Working HR\'s',
                            timeTextColor,
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Reason: ${absence.alasanIzin?.split(':').last.trim() ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.grey.withOpacity(0.7)),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: AppColors.background,
                          title: const Text('Cancel Entry'),
                          content: const Text(
                            'Are you sure you want to cancel this entry?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'No',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Yes',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirmed == true) {
                    try {
                      // **START OF CORRECTION FOR 'int?' to 'int' ERROR**
                      // 1. Check if ID is null. If it is, we cannot proceed.
                      if (absence.id == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Error: Absence ID is missing. Cannot delete.',
                              ),
                            ),
                          );
                        }
                        return; // Exit the function
                      }

                      // 2. Assuming ApiService.deleteAbsence expects an 'int' ID.
                      //    We are providing a non-nullable int using '!' since we checked for null above.
                      //    If the error 'int?' to 'int' still persists with '!' here,
                      //    try: `await _apiService.deleteAbsence(absence.id as int);`
                      final ApiResponse<Absence> deleteResponse =
                          await _apiService.deleteAbsence(absence.id!);
                      // **END OF CORRECTION**

                      if (deleteResponse.statusCode == 200) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(deleteResponse.message)),
                        );
                        await _refreshList();
                        MainBottomNavigationBar.refreshHomeNotifier.value =
                            true;
                      } else {
                        String errorMessage = deleteResponse.message;
                        if (deleteResponse.errors != null) {
                          deleteResponse.errors!.forEach((key, value) {
                            errorMessage +=
                                '\n$key: ${(value as List).join(', ')}';
                          });
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to cancel entry: $errorMessage',
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'An error occurred during cancellation: $e',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String time, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Attendance Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              // Your existing AddTemporary navigation (if any)
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Monthly',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                            'MMM yyyy',
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshList,
              child: FutureBuilder<List<Absence>>(
                future: _attendanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final attendances = snapshot.data ?? [];

                  if (attendances.isEmpty) {
                    return Center(
                      child: Text(
                        'No attendance records found for ${DateFormat('MMMM yyyy').format(_selectedMonth)}.',
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: attendances.length,
                    itemBuilder: (context, index) {
                      return _buildAttendanceTile(attendances[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
