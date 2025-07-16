import 'dart:async';

import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/models/app_models.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:absensi/widgets/copy_right.dart';
import 'package:absensi/widgets/custom_card_history.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  DateTime? _selectedDay;

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
        fetchedAbsences.sort((a, b) {
          if (a.attendanceDate == null && b.attendanceDate == null) return 0;
          if (a.attendanceDate == null) return 1;
          if (b.attendanceDate == null) return -1;
          return b.attendanceDate!.compareTo(a.attendanceDate!);
        });
        return fetchedAbsences;
      } else {
        throw Exception(response.message);
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
          _selectedDay = null;
        });
        _refreshList();
      }
    }
  }

  String _calculateWorkingHoursForHistory(Absence absence) {
    if (absence.checkIn == null || absence.checkOut == null) {
      return '00:00:00';
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
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'History Absen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.inputFill,
        elevation: 0,
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
                  'Ringkasan Bulan Ini',
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
                            'MMMM yyyy',
                            'id_ID',
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 7,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: AppColors.textDark,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                            1,
                          );
                          _selectedDay = null;
                        });
                        _refreshList();
                      },
                      splashRadius: 24.0,
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textDark,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                            1,
                          );
                          _selectedDay = null;
                        });
                        _refreshList();
                      },
                      splashRadius: 24.0,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final List<String> weekdays = [
                      'Min',
                      'Sen',
                      'Sel',
                      'Rab',
                      'Kam',
                      'Jum',
                      'Sab',
                    ];
                    return Expanded(
                      child: Center(
                        child: Text(
                          weekdays[index],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                (index == 0 || index == 6)
                                    ? AppColors.accentRed
                                    : AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const Divider(height: 20, thickness: 1.0, color: Colors.grey),
                FutureBuilder<List<Absence>>(
                  future: _attendanceFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading calendar: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final List<Absence> attendances = snapshot.data ?? [];
                    final Map<int, Absence> attendanceMap = {
                      for (var abs in attendances)
                        abs.attendanceDate?.day ?? 0: abs,
                    };

                    final int daysInMonth =
                        DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                          0,
                        ).day;

                    final int firstDayWeekday =
                        _selectedMonth.copyWith(day: 1).weekday % 7;

                    List<Widget> dayWidgets = [];

                    for (int i = 0; i < firstDayWeekday; i++) {
                      dayWidgets.add(Container());
                    }

                    for (int day = 1; day <= daysInMonth; day++) {
                      final DateTime currentDate = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month,
                        day,
                      );
                      final bool isToday =
                          currentDate.year == DateTime.now().year &&
                          currentDate.month == DateTime.now().month &&
                          currentDate.day == DateTime.now().day;
                      final bool isSelected =
                          _selectedDay != null &&
                          _selectedDay!.year == currentDate.year &&
                          _selectedDay!.month == currentDate.month &&
                          _selectedDay!.day == currentDate.day;
                      final Absence? dayAttendance = attendanceMap[day];

                      Color dayColor = AppColors.textDark;
                      Color dotColor = Colors.transparent;
                      FontWeight fontWeight = FontWeight.normal;

                      if (dayAttendance != null) {
                        if (dayAttendance.status?.toLowerCase() == 'izin') {
                          dotColor = AppColors.accentOrange;
                          fontWeight = FontWeight.w600;
                        } else if (dayAttendance.status?.toLowerCase() ==
                            'late') {
                          dotColor = AppColors.accentRed;
                          fontWeight = FontWeight.w600;
                        } else if (dayAttendance.status?.toLowerCase() ==
                            'masuk') {
                          dotColor = AppColors.accentGreen;
                          fontWeight = FontWeight.w600;
                        }
                      }

                      if (isToday) {
                        dayColor =
                            isSelected ? Colors.white : AppColors.primary;
                        fontWeight = FontWeight.bold;
                      }
                      if (isSelected) {
                        dayColor = Colors.white;
                      }
                      if (!isToday &&
                          !isSelected &&
                          (currentDate.weekday == DateTime.sunday ||
                              currentDate.weekday == DateTime.saturday)) {
                        dayColor = AppColors.accentRed;
                      }

                      dayWidgets.add(
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = currentDate;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : (isToday && !isSelected)
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  isToday && !isSelected
                                      ? Border.all(
                                        color: AppColors.primary,
                                        width: 1.0,
                                      )
                                      : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    color: dayColor,
                                    fontWeight: fontWeight,
                                    fontSize: 15,
                                  ),
                                ),
                                if (dotColor != Colors.transparent)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: dotColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 2.0,
                            mainAxisSpacing: 2.0,
                          ),
                      itemCount: dayWidgets.length,
                      itemBuilder: (context, index) {
                        return dayWidgets[index];
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              _selectedDay != null
                  ? 'Riwayat  ${DateFormat('E, MMM d, yyyy').format(_selectedDay!)}'
                  : 'Riwayat',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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
                  final List<Absence> filteredAttendances =
                      _selectedDay != null
                          ? attendances
                              .where(
                                (absence) =>
                                    absence.attendanceDate != null &&
                                    absence.attendanceDate!.year ==
                                        _selectedDay!.year &&
                                    absence.attendanceDate!.month ==
                                        _selectedDay!.month &&
                                    absence.attendanceDate!.day ==
                                        _selectedDay!.day,
                              )
                              .toList()
                          : attendances;

                  if (filteredAttendances.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedDay != null
                            ? 'Tidak ada absen ${DateFormat('E, MMM d, yyyy', 'id_ID').format(_selectedDay!)}.'
                            : 'Tidak ada absen ${DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth)}.',
                      ),
                    );
                  }

                  // Use Column to wrap ListView.builder and the CopyrightText
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredAttendances.length,
                          itemBuilder: (context, index) {
                            final absence = filteredAttendances[index];
                            return CustomCardHistory(
                              absence: absence,
                              onDismissed: () {
                                setState(() {
                                  filteredAttendances.removeAt(index);
                                });
                              },
                            );
                          },
                        ),
                      ),
                      // --- MENEMPATKAN COPYRIGHT DI BAWAH CARD ---
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 16.0,
                        ), // Beri padding atas dan bawah
                        child:
                            CopyrightText(), // Panggil widget CopyrightText di sini
                      ),
                      // --- AKHIR PENEMPATAN COPYRIGHT ---
                    ],
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
