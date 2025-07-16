import 'package:flutter/material.dart';

class CopyrightText extends StatelessWidget {
  const CopyrightText({super.key});

  @override
  Widget build(BuildContext context) {
    // Tahun saat ini didapatkan secara dinamis
    final int currentYear = DateTime.now().year;

    // Tentukan tahun awal copyright
    const int startYear = 2025; // Sesuai permintaan Anda

    // Buat string copyright
    String copyrightString;
    if (startYear == currentYear) {
      copyrightString =
          '© $currentYear NIKITA AIDINA HIDAYAT. All rights reserved.';
    } else {
      // Ini akan digunakan jika currentYear > 2025
      copyrightString =
          '© $startYear - $currentYear NIKITA AIDINA HIDAYAT. All rights reserved.';
    }

    return Text(
      copyrightString,
      style: TextStyle(
        fontSize: 12,
        color:
            Colors.grey[600], // Warna teks abu-abu agar tidak terlalu mencolok
      ),
      textAlign: TextAlign.center, // Pusatkan teks
    );
  }
}
