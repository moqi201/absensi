import 'package:absensi/core/utils/date_formatter.dart';
import 'package:absensi/data/models/absen_model.dart';
import 'package:absensi/providers/attendance_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';



class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).fetchHistoryAbsen();
    });
  }

  void _showAbsenDetail(AbsenRecord absen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            LatLng? checkInLocation;
            if (absen.checkInLat != null && absen.checkInLng != null) {
              checkInLocation = LatLng(
                double.parse(absen.checkInLat!),
                double.parse(absen.checkInLng!),
              );
            }
            LatLng? checkOutLocation;
            if (absen.checkOutLat != null && absen.checkOutLng != null) {
              checkOutLocation = LatLng(
                double.parse(absen.checkOutLat!),
                double.parse(absen.checkOutLng!),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Text(
                      'Detail Absen',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildDetailRow(
                    'Tanggal',
                    absen.createdAt != null
                        ? DateFormatter.formatDate(absen.createdAt!)
                        : 'N/A',
                  ),
                  _buildDetailRow('Status', absen.status ?? 'N/A'),
                  if (absen.alasanIzin != null)
                    _buildDetailRow('Alasan Izin', absen.alasanIzin!),
                  Divider(),
                  Text(
                    'Waktu & Lokasi Masuk',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _buildDetailRow(
                    'Jam Masuk',
                    absen.checkInTime != null
                        ? DateFormatter.formatTime(absen.checkInTime!)
                        : 'N/A',
                  ),
                  _buildDetailRow(
                    'Alamat Masuk',
                    absen.checkInAddress ?? 'N/A',
                  ),
                  if (checkInLocation != null)
                    Container(
                      height: 200,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: checkInLocation,
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId('checkInLocation'),
                            position: checkInLocation,
                            infoWindow: InfoWindow(title: 'Lokasi Masuk'),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: false,
                      ),
                    ),
                  Divider(),
                  Text(
                    'Waktu & Lokasi Pulang',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _buildDetailRow(
                    'Jam Pulang',
                    absen.checkOutTime != null
                        ? DateFormatter.formatTime(absen.checkOutTime!)
                        : 'Belum absen pulang',
                  ),
                  _buildDetailRow(
                    'Alamat Pulang',
                    absen.checkOutAddress ?? 'Belum absen pulang',
                  ),
                  if (checkOutLocation != null)
                    Container(
                      height: 200,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: checkOutLocation,
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId('checkOutLocation'),
                            position: checkOutLocation,
                            infoWindow: InfoWindow(title: 'Lokasi Pulang'),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: false,
                      ),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _confirmDelete(absen.id!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(
                      'Hapus Absen',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  void _confirmDelete(int absenId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Konfirmasi Hapus'),
            content: Text('Anda yakin ingin menghapus riwayat absen ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final attendanceProvider = Provider.of<AttendanceProvider>(
                    context,
                    listen: false,
                  );
                  bool success = await attendanceProvider.deleteAbsen(absenId);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Riwayat absen berhasil dihapus!'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          attendanceProvider.errorMessage ??
                              'Gagal menghapus riwayat absen.',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Hapus', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Riwayat Absensi')),
      body:
          attendanceProvider.isLoading
              ? Center(child: CircularProgressIndicator())
              : (attendanceProvider.historyAbsen == null ||
                      attendanceProvider.historyAbsen!.isEmpty
                  ? Center(child: Text('Tidak ada riwayat absensi.'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: attendanceProvider.historyAbsen!.length,
                    itemBuilder: (context, index) {
                      final absen = attendanceProvider.historyAbsen![index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2,
                        child: ListTile(
                          onTap: () => _showAbsenDetail(absen),
                          leading: Icon(Icons.calendar_today),
                          title: Text(
                            'Tanggal: ${DateFormatter.formatDate(absen.createdAt!)}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${absen.status}'),
                              if (absen.checkInTime != null)
                                Text(
                                  'Masuk: ${DateFormatter.formatTime(absen.checkInTime!)}',
                                ),
                              if (absen.checkOutTime != null)
                                Text(
                                  'Pulang: ${DateFormatter.formatTime(absen.checkOutTime!)}',
                                ),
                              Text(
                                'Lokasi Masuk: ${absen.checkInAddress ?? 'N/A'}',
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                        ),
                      );
                    },
                  )),
    );
  }
}
