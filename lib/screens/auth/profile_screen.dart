// lib/screens/profile/profile_screen.dart
import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/data/models/app_models.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:absensi/routes/app_router.dart';
import 'package:absensi/screens/auth/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Keep this import for DateFormat if you use it for displaying dates in UI

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

  bool _notificationEnabled = true; // State for the notification switch

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
    final String jenisKelamin =
        _currentUser?.jenis_kelamin == 'L'
            ? 'Laki-laki'
            : _currentUser?.jenis_kelamin == 'P'
            ? 'Perempuan'
            : 'N/A';
    // Changed: profilePhotoUrl will now hold the URL/path from the API
    final String profilePhotoUrl = _currentUser?.profile_photo ?? '';

    // Use training_title from API for designation
    final String designation = _currentUser?.training_title ?? 'Employee';

    // Format the joinedDate based on batch.start_date from User model
    String formattedJoinedDate = 'N/A';
    if (_currentUser?.batch?.startDate != null) {
      try {
        // Added null assertion (!) to startDate as DateTime.parse expects a non-nullable String
        final DateTime startDate = DateTime.parse(
          _currentUser!.batch!.startDate!,
        );
        formattedJoinedDate = DateFormat('MMM dd, yyyy').format(startDate);
      } catch (e) {
        print('Error parsing batch start date: $e');
        formattedJoinedDate = 'N/A';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Managed by MainBottomNavigationBar
      ),
      body: Stack(
        children: [
          // Background area at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180, // Slightly reduced height for a cleaner look
              decoration: const BoxDecoration(
                color:
                    AppColors.primary, // Solid primary color for a cleaner look
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(25), // Softer rounded bottom
                ),
              ),
              child: const Center(
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Slightly smaller font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Conditional rendering: Show CircularProgressIndicator while _isLoading is true
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(), // Show loading indicator
              )
              : RefreshIndicator(
                // Add RefreshIndicator for pull-to-refresh
                onRefresh: _loadUserData,
                child: ListView(
                  padding: const EdgeInsets.only(
                    top: 100,
                    bottom: 20,
                  ), // Adjust top padding to overlap with background
                  children: [
                    // Profile Header Section (Avatar, Name, Designation, Joined Date)
                    _buildProfileHeader(
                      username,
                      designation,
                      formattedJoinedDate, // Pass the correctly formatted date
                      profilePhotoUrl, // Pass URL/path string
                    ),
                    const SizedBox(height: 20), // Space between sections
                    // User Details Card
                    _buildUserDetailsCard(
                      email,
                      _currentUser?.batch_ke, // Pass batch_ke
                      jenisKelamin, // Pass jenisKelamin
                    ),
                    const SizedBox(height: 20),

                    // Settings and Logout Options
                    _buildActionOptions(),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    String username,
    String designation,
    String joinedDate, // This parameter correctly receives formattedJoinedDate
    String profilePhotoPath, // Changed to profilePhotoPath
  ) {
    ImageProvider<Object>? imageProvider;

    // Construct full URL based on whether it's already a full URL or a relative path
    if (profilePhotoPath.isNotEmpty) {
      final String fullImageUrl =
          profilePhotoPath.startsWith('http')
              ? profilePhotoPath
              : 'https://appabsensi.mobileprojp.com/public/$profilePhotoPath'; // Adjusted base path
      imageProvider = NetworkImage(fullImageUrl);
    }

    return Column(
      children: [
        // Profile Picture
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white, // White border around avatar
              width: 3, // Slightly thinner border
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15), // Softer shadow
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 55, // Slightly smaller radius for a balanced look
            backgroundColor: AppColors.primary, // Placeholder background
            backgroundImage: imageProvider, // Use the determined image provider
            child:
                imageProvider ==
                        null // Show icon only if no valid image provider
                    ? const Icon(
                      Icons
                          .person, // Fallback icon if no image URL or local file
                      size: 50, // Adjusted icon size
                      color: Colors.white,
                    )
                    : null, // No child if an image is loading
          ),
        ),
        const SizedBox(height: 15),
        // User Name
        Text(
          username,
          style: const TextStyle(
            fontSize: 24, // Adjusted font size
            fontWeight: FontWeight.w700, // Slightly less bold
            color: AppColors.textDark, // Dark text color
          ),
        ),
        const SizedBox(height: 4),
        // Designation and Joined Date
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              designation,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ), // Softer grey
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '•', // Menggunakan bullet point sebagai separator
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ), // Softer grey
              ),
            ),
            Text(
              'Joined $joinedDate', // Corrected: Use 'joinedDate' parameter here
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ), // Softer grey
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserDetailsCard(
    String email,
    String? batchKe, // Added batchKe parameter
    String jenisKelamin, // Added jenisKelamin parameter
  ) {
    return Card(
      color: Colors.white, // Changed to white background for cards
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2, // Reduced elevation for a flatter look
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(Icons.email, 'Email ID', email), // Added icon
            if (batchKe != null) ...[
              // Conditionally add batch info
              const Divider(color: AppColors.border, height: 20),
              _buildDetailRow(Icons.group, 'Batch', batchKe), // Added icon
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
    );
  }

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
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Notification Toggle
          Card(
            color: Colors.white, // Changed to white background
            margin: EdgeInsets.zero, // No extra margin for this card
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2, // Reduced elevation
            child: ListTile(
              leading: const Icon(
                Icons.notifications,
                color: AppColors.primary,
              ),
              title: const Text(
                'Notification',
                style: TextStyle(fontSize: 16, color: AppColors.textDark),
              ),
              trailing: Switch.adaptive(
                value: _notificationEnabled,
                onChanged: (bool newValue) {
                  setState(() {
                    _notificationEnabled = newValue;
                  });
                  // Add logic to save notification preference (e.g., to UserModel or SessionManager)
                },
                activeColor: AppColors.primary,
              ),
              onTap: () {
                // Toggling the switch directly is often enough, but you can add more logic here.
                setState(() {
                  _notificationEnabled = !_notificationEnabled;
                });
              },
            ),
          ),
          const SizedBox(height: 10), // Space between cards
          // Settings Option (now navigates to EditProfileScreen)
          Card(
            color: Colors.white, // Changed to white background
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2, // Reduced elevation
            child: ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text(
                'Edit Profile', // Changed text to Edit Profile
                style: TextStyle(fontSize: 16, color: AppColors.textDark),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppColors.textLight,
              ),
              onTap: _navigateToEditProfile, // Call the new navigation method
            ),
          ),
          const SizedBox(height: 10), // Space between cards
          // Logout Option
          Card(
            color: Colors.white, // Changed to white background
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2, // Reduced elevation
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                'Logout',
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppColors.textLight,
              ),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
