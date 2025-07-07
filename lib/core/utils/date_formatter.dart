import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(
    DateTime dateTime, {
    String format = 'dd MMMM yyyy, HH:mm',
  }) {
    return DateFormat(
      format,
      'id_ID',
    ).format(dateTime); // Use Indonesian locale
  }

  static String formatDate(
    DateTime dateTime, {
    String format = 'dd MMMM yyyy',
  }) {
    return DateFormat(format, 'id_ID').format(dateTime);
  }

  static String formatTime(DateTime dateTime, {String format = 'HH:mm'}) {
    return DateFormat(format).format(dateTime);
  }
}
