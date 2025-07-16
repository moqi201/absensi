import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/models/app_models.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:absensi/routes/app_router.dart';
import 'package:absensi/screens/auth/edit_profile_screen.dart';
import 'package:absensi/widgets/copy_right.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const ProfileScreen({super.key, required this.refreshNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService(); // Use ApiService
  User? _currentUser; // Holds the full user data (from API)
  bool _isLoading = false; // Add loading state

  final bool _notificationEnabled = true; // State for the notification switch

  @override
  void initState() {
    super.initState();
    _loadUserData();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      _loadUserData(); // Re-fetch user data on refresh signal
      widget.refreshNotifier.value = false; // Reset the notifier
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });

    final ApiResponse<User> response = await _apiService.getProfile();

    setState(() {
      _isLoading = false; // Set loading to false
    });

    if (response.statusCode == 200 && response.data != null) {
      setState(() {
        _currentUser = response.data;
        // You might also want to load the notification preference from the user model
        // if you store it there:
        // _notificationEnabled = user?.notificationPreference ?? true;
      });
    } else {
      print('Failed to load user profile: ${response.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${response.message}'),
          ),
        );
      }
      setState(() {
        _currentUser = null; // Ensure _currentUser is null on error
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use dialogContext to avoid conflicts
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
                _logout(context); // Lanjutkan proses logout
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    await ApiService.clearToken(); // Clear token using ApiService static method
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _navigateToEditProfile() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not loaded yet. Please wait.')),
      );
      return;
    }

    // Navigate to the EditProfileScreen, passing the current user data.
    // Await the result to know if data was updated.
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentUser: _currentUser!),
      ),
    );

    // If result is true, it means the profile was successfully updated in EditProfileScreen,
    // so refresh the data on this ProfileScreen.
    if (result == true) {
      _loadUserData(); // Refresh profile data
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provide default values if _currentUser is null (e.g., still loading or no user logged in)
    final String username =
        _currentUser?.name ?? 'Guest User'; // Use .name property
    final String email = _currentUser?.email ?? 'guest@example.com';
    final String jenisKelamin = // Re-enabled for the new card
        _currentUser?.jenis_kelamin == 'L'
            ? 'Laki-laki'
            : _currentUser?.jenis_kelamin == 'P'
            ? 'Perempuan'
            : 'N/A';
    // Changed: profilePhotoUrl will now hold the URL/path from the API
    final String profilePhotoUrl = _currentUser?.profile_photo ?? '';

    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.inputFill,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0, // No shadow for app ba
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(), // Show loading indicator
              )
              : RefreshIndicator(
                onRefresh: _loadUserData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                  ), // Padding for the whole list
                  children: [
                    // Profile Section (Avatar, Name, Email, Edit Profile Button) - Kept from previous request
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileAvatar(profilePhotoUrl),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30), // Space after profile section
                    // User Details Card (from image_c9db7c.png)
                    _buildUserDetailsCard(
                      _currentUser?.training_title ?? 'N/A',
                      _currentUser?.batch_ke, // Pass batch_ke
                      jenisKelamin, // Pass jenisKelamin
                    ),
                    const SizedBox(height: 20), // Space between cards
                    // Edit Profile Card (from image_c9db7c.png)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        color: Colors.white,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(
                            Icons.settings,
                            color: AppColors.primary,
                          ),
                          title: const Text(
                            'Edit Profil',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: AppColors.textLight,
                          ),
                          onTap: _navigateToEditProfile,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ), // Small space between these cards
                    // Logout Card (from image_c9db7c.png)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        color: Colors.white,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: AppColors.error,
                          ),
                          title: const Text(
                            'Keluar',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 16,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: AppColors.textLight,
                          ),
                          onTap:
                              () => _confirmLogout(
                                context,
                              ), // Panggil fungsi konfirmasi logout
                        ),
                      ),
                    ),
                    const SizedBox(height: 280), // Spacing after logout card
                    // --- START ADDITION: Copyright Text ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: CopyrightText(), // Adjust padding as needed
                    ),

                    // --- END ADDITION ---
                    const SizedBox(
                      height: 20,
                    ), // Bottom spacing for the ListView
                  ],
                ),
              ),
    );
  }

  // Helper widget for the profile avatar with camera icon (retained)
  Widget _buildProfileAvatar(String profilePhotoPath) {
    ImageProvider<Object>? imageProvider;

    if (profilePhotoPath.isNotEmpty) {
      final String fullImageUrl =
          profilePhotoPath.startsWith('http')
              ? profilePhotoPath
              : 'https://appabsensi.mobileprojp.com/public/$profilePhotoPath';
      imageProvider = NetworkImage(fullImageUrl);
    } else {
      // BAGIAN INI YANG AKAN MENERAPKAN LOGIKA JENIS KELAMIN
      // Saat profilePhotoPath KOSONG, gunakan default berdasarkan jenis kelamin
      if (_currentUser?.jenis_kelamin == 'P') {
        // Perbaikan: Gunakan _currentUser?.jenis_kelamin
        // Asumsi 'P' untuk Perempuan
        imageProvider = const NetworkImage(
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTePvPIcfgyTA_2uby6QSsAG7PDe0Ai1Pv9x6cpYZYRGyxKSufwKmkibEpGZDw1fw5JUSs&usqp=CAU',
        );
      } else {
        imageProvider = const NetworkImage(
          'https://avatar.iran.liara.run/public/boy?username=Ash',
        ); // Untuk Laki-laki atau default
      }
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary, // Placeholder background
          backgroundImage: imageProvider,
          child:
              imageProvider == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  // Reintroduced and adapted for the first card in image_c9db7c.png
  Widget _buildUserDetailsCard(
    String training,
    String? batchKe, // Added batchKe parameter
    String jenisKelamin, // Added jenisKelamin parameter
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: Colors.white, // Changed to white background for cards
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ), // Consistent rounded corners
        elevation: 1, // Subtle elevation
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildDetailRow(
                Icons.assignment_ind_rounded,
                'Pelatihan',
                training,
              ), // Added icon
              if (batchKe != null) ...[
                // Conditionally add batch info
                const Divider(color: AppColors.border, height: 20),
                _buildDetailRow(Icons.group, 'Angkatan', batchKe), // Added icon
              ],
              const Divider(color: AppColors.border, height: 20),
              _buildDetailRow(
                Icons.person_outline, // Added icon
                'Jenis Kelamin',
                jenisKelamin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reintroduced and adapted for the rows within the first card
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20), // Icon for each detail
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textLight, // Using AppColors for consistency
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDark, // Using AppColors for consistency
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
