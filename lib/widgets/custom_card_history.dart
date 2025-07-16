import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/models/app_models.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Sesuaikan path ini

// Pastikan kelas ini adalah StatefulWidget jika ada logika internal yang perlu dipertahankan
class CustomCardHistory extends StatefulWidget {
  final Absence absence;
  final VoidCallback
  onDismissed; // Callback untuk memberi tahu parent bahwa item dihapus

  const CustomCardHistory({
    super.key,
    required this.absence,
    required this.onDismissed,
  });

  @override
  State<CustomCardHistory> createState() => _CustomCardHistoryState();
}

class _CustomCardHistoryState extends State<CustomCardHistory> {
  // ApiService hanya digunakan di sini untuk DELETE request
  // Data tampilan (absence) diterima dari parent
  final ApiService _apiService = ApiService();

  String _calculateWorkingHoursForHistory(Absence absence) {
    if (absence.checkIn == null || absence.checkOut == null) {
      return '00:00:00'; // Mengembalikan format HH:mm:ss
    }
    final Duration duration = absence.checkOut!.difference(absence.checkIn!);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(
      60,
    ); // Tambahkan perhitungan detik

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}'; // Format dengan detik
  }

  @override
  Widget build(BuildContext context) {
    // Warna dan ikon default untuk entri absensi biasa
    Color cardColor = AppColors.primary;
    Color textColor = Colors.white;
    IconData statusIcon = Icons.check_circle_outline;

    // Cek jika status adalah 'izin'
    if (widget.absence.status?.toLowerCase() == 'izin') {
      cardColor = Colors.orange;
      textColor = Colors.white;
      statusIcon = Icons.info_outline;
    }

    // Tentukan teks lokasi yang akan ditampilkan
    String locationText = 'Lokasi tidak tersedia';
    if (widget.absence.status?.toLowerCase() == 'izin') {
      locationText = widget.absence.alasanIzin ?? 'Tidak ada alasan';
    } else {
      locationText = widget.absence.checkInAddress ?? 'Alamat tidak diketahui';
    }

    // Tentukan hari dalam seminggu
    String dayOfWeek = '';
    if (widget.absence.attendanceDate != null) {
      dayOfWeek = DateFormat(
        'EEE',
        'id_ID',
      ).format(widget.absence.attendanceDate!);
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
                  DateFormat(
                    'dd',
                    'id_ID',
                  ).format(widget.absence.attendanceDate!), // Tanggal
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor, // Menggunakan warna dinamis
                  ),
                ),
                Text(
                  DateFormat(
                    'MMMM',
                    'id_ID',
                  ).format(widget.absence.attendanceDate!), // Bulan
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
                  if (widget.absence.status == 'izin')
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
                                  widget.absence.status?.toUpperCase() ?? 'N/A',
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
                          widget.absence.alasanIzin ??
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
                                'id_ID',
                              ).format(widget.absence.attendanceDate!),
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
                                  widget.absence.checkIn != null
                                      ? DateFormat(
                                        'HH:mm',
                                      ).format(widget.absence.checkIn!)
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
                                  widget.absence.checkOut != null
                                      ? DateFormat(
                                        'HH:mm',
                                      ).format(widget.absence.checkOut!)
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
                                  _calculateWorkingHoursForHistory(
                                    widget.absence,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed:
                                  () => _showDeleteConfirmationDialog(context),
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
                                widget.absence.checkInAddress ??
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

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.background,
            title: const Text('Batalkan Entri'),
            content: const Text(
              'Apakah Anda yakin ingin membatalkan entri ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Tidak',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Ya',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final ApiResponse<Absence> deleteResponse = await _apiService
            .deleteAbsence(widget.absence.id);

        if (deleteResponse.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(deleteResponse.message)));
          // Panggil callback onDismissed yang disediakan oleh parent
          widget.onDismissed();
          // Jika ada GlobalNotifier, aktifkan juga untuk refresh Home
          // MainBottomNavigationBar.refreshHomeNotifier.value = true;
        } else {
          String errorMessage = deleteResponse.message;
          if (deleteResponse.errors != null) {
            deleteResponse.errors!.forEach((key, value) {
              errorMessage += '\n$key: ${(value as List).join(', ')}';
            });
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal membatalkan entri: $errorMessage')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan saat pembatalan: $e')),
          );
        }
      }
    }
  }
}
