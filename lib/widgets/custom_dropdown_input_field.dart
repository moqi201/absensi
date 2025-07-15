import 'package:absensi/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CustomDropdownInputField<T> extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double? menuMaxHeight;
  final String? Function(T?)? validator;

  const CustomDropdownInputField({
    super.key,
    required this.labelText,
    this.hintText,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.menuMaxHeight,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(
        hintText ?? 'Select ${labelText.toLowerCase()}',
        style: const TextStyle(
          color: AppColors.placeholder,
        ), // Warna placeholder
      ),
      items: items,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textDark, // Warna teks input saat dipilih
      ),
      decoration: InputDecoration(
        // labelText akan muncul di atas hintText saat input tidak fokus
        labelText: labelText,
        labelStyle: const TextStyle(
          color: AppColors.textLight, // Warna label saat tidak fokus
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary, // Warna label saat fokus
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            16,
          ), // Radius sudut yang konsisten
          borderSide: const BorderSide(
            color: AppColors.border,
          ), // Warna border default
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.border,
          ), // Warna border saat enabled
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2.0,
          ), // Warna border saat fokus, sedikit lebih tebal
        ),
        errorBorder: OutlineInputBorder(
          // Gaya border untuk error
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          // Gaya border untuk error saat fokus
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
        filled: true,
        fillColor: AppColors.inputFill, // Warna latar belakang input
        prefixIcon: Icon(
          icon,
          color: AppColors.primary, // Warna ikon prefix
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ), // Padding internal input
      ),
      menuMaxHeight: menuMaxHeight,
      validator: validator,
      isExpanded: true,
      icon: const Icon(
        // Mengatur ikon dropdown
        Icons.keyboard_arrow_down,
        color: AppColors.textLight, // Warna ikon panah dropdown
      ),
      dropdownColor: AppColors.background, // Warna latar belakang dropdown menu
    );
  }
}
