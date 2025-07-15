// lib/screens/profile/edit_profile_screen.dart
import 'dart:convert'; // For base64 encoding
import 'dart:io'; // For File operations

import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/models/app_models.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import for image picking

import '../../widgets/custom_input_field.dart'; // Your CustomInputField
import '../../widgets/primary_button.dart'; // Your PrimaryButton

class EditProfileScreen extends StatefulWidget {
  final User currentUser; // Changed type to User

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  File? _pickedImage; // State for newly picked profile photo file
  String? _profilePhotoBase64; // Base64 for the newly picked photo to upload
  String? _initialProfilePhotoUrl; // To store the original URL from currentUser

  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    // Initialize controller with current user's name
    _nameController = TextEditingController(
      text: widget.currentUser.name, // Use .name property
    );

    // Store the initial profile photo URL from the current user
    _initialProfilePhotoUrl = widget.currentUser.profile_photo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        // Convert image to base64 for upload
        List<int> imageBytes =
            _pickedImage!.readAsBytesSync(); // Menggunakan readAsBytesSync
        _profilePhotoBase64 = base64Encode(imageBytes);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true; // Set loading to true
      });

      final String newName = _nameController.text.trim();
      bool profileDetailsChanged = false;
      bool profilePhotoChanged = false;

      // 1. Check if name or gender has changed and update
      final bool nameChanged = newName != widget.currentUser.name;

      if (nameChanged) {
        try {
          final ApiResponse<User> response = await _apiService.updateProfile(
            name: newName,
          );

          if (response.statusCode == 200 && response.data != null) {
            profileDetailsChanged = true;
          } else {
            String errorMessage = response.message;
            if (response.errors != null) {
              response.errors!.forEach((key, value) {
                errorMessage += '\n$key: ${(value as List).join(', ')}';
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update profile details: $errorMessage',
                  ),
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return; // Stop if detail update fails
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred updating details: $e')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Check if a new profile photo has been selected and upload
      if (_pickedImage != null && _profilePhotoBase64 != null) {
        try {
          final ApiResponse<User> photoResponse = await _apiService
              .updateProfilePhoto(profilePhoto: _profilePhotoBase64!);

          if (photoResponse.statusCode == 200 && photoResponse.data != null) {
            profilePhotoChanged = true;
            // IMPORTANT: Update the initialProfilePhotoUrl with the new URL from the API response
            if (photoResponse.data!.profile_photo != null) {
              _initialProfilePhotoUrl = photoResponse.data!.profile_photo;
            }
            // Clear picked image and base64 as it's now saved and reflected by URL
            _pickedImage = null;
            _profilePhotoBase64 = null;
          } else {
            String errorMessage = photoResponse.message;
            if (photoResponse.errors != null) {
              photoResponse.errors!.forEach((key, value) {
                errorMessage += '\n$key: ${(value as List).join(', ')}';
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update profile photo: $errorMessage',
                  ),
                ),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return; // Stop if photo update fails
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred updating photo: $e')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;

      if (profileDetailsChanged || profilePhotoChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context, true); // Pop with true to signal refresh
      } else {
        // If no changes were made to either name/gender or photo
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No changes to save.")));
      }

      setState(() {
        _isLoading = false; // Set loading to false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construct full URL for existing profile photo
    ImageProvider<Object>? currentImageProvider;
    if (_pickedImage != null) {
      // If a new image is picked, use it
      currentImageProvider = FileImage(_pickedImage!);
    } else if (_initialProfilePhotoUrl != null &&
        _initialProfilePhotoUrl!.isNotEmpty) {
      // If no new image, but there's an initial URL, use NetworkImage
      // Check if the URL is already a full URL or a relative path
      final String fullImageUrl =
          _initialProfilePhotoUrl!.startsWith('http')
              ? _initialProfilePhotoUrl!
              : 'https://appabsensi.mobileprojp.com/public/${_initialProfilePhotoUrl!}'; // Adjust base path as needed
      currentImageProvider = NetworkImage(fullImageUrl);
    } else {
      // THIS IS THE NEW PART: If no picked image and no initial URL,
      // use a default image based on gender.
      String defaultImageUrl;
      // Assuming 'widget.currentUser.jenis_kelamin' is accessible here
      // and 'P' means female.
      if (widget.currentUser.jenis_kelamin == 'P') {
        defaultImageUrl =
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTePvPIcfgyTA_2uby6QSsAG7PDe0Ai1Pv9x6cpYZYRGyxKSufwKmkibEpGZDw1fw5JUSs&usqp=CAU'; // Female default image
      } else {
        defaultImageUrl =
            'https://avatar.iran.liara.run/public/boy?username=Ash'; // Male default image
      }
      currentImageProvider = NetworkImage(defaultImageUrl);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profil', // Mengganti teks AppBar
          style: TextStyle(
            fontWeight: FontWeight.bold, // Membuat teks lebih tebal
            color: Colors.white, // Warna teks putih
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Warna ikon kembali
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 32.0,
        ), // Padding lebih merata
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Membentangkan elemen
            children: [
              // Bagian Foto Profil
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 70, // Sedikit lebih besar
                      backgroundColor: AppColors.primary.withOpacity(
                        0.1,
                      ), // Warna background yang lembut
                      backgroundImage: currentImageProvider,
                      child:
                          currentImageProvider == null
                              ? Icon(
                                Icons.person,
                                size: 70, // Ukuran ikon disesuaikan
                                color: AppColors.textLight.withOpacity(
                                  0.6,
                                ), // Warna ikon lebih lembut
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary, // Warna tombol ubah foto
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 2,
                            ), // Border putih
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32), // Jarak lebih besar setelah foto
              // Bagian Informasi Profil
              const Text(
                'Informasi Pribadi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // Nama (Editable)
              CustomInputField(
                controller: _nameController,
                hintText: 'Nama Lengkap', // Hint yang lebih deskriptif
                labelText: 'Nama',
                icon: Icons.person_outline, // Ikon yang sedikit berbeda
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24), // Jarak antara input field dan tombol
              // Tombol Simpan
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                  : PrimaryButton(
                    label: 'Simpan Perubahan', // Teks tombol lebih jelas
                    onPressed: _saveProfile,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
