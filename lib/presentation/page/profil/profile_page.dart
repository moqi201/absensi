import 'package:absensi/providers/auth_provider.dart';
import 'package:absensi/providers/profile_provider.dart';
import 'package:absensi/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../../../core/utils/date_formatter.dart'; // For formatting dates

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final authProvider = Provider.of<AuthProvider>(
      context,
    ); // Access AuthProvider for current user data

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Pengguna'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(AppConstants.editProfileRoute);
            },
          ),
        ],
      ),
      body:
          profileProvider.isLoading
              ? Center(child: CircularProgressIndicator())
              : (profileProvider.userProfile == null
                  ? Center(child: Text('Gagal memuat profil pengguna.'))
                  : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            child: Text(
                              profileProvider.userProfile?.name
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: TextStyle(fontSize: 50),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProfileRow(
                                  'Nama',
                                  profileProvider.userProfile?.name ?? 'N/A',
                                ),
                                Divider(),
                                _buildProfileRow(
                                  'Email',
                                  profileProvider.userProfile?.email ?? 'N/A',
                                ),
                                Divider(),
                                _buildProfileRow(
                                  'ID Batch',
                                  profileProvider.userProfile?.batchId
                                          ?.toString() ??
                                      'N/A',
                                ),
                                Divider(),
                                _buildProfileRow(
                                  'ID Training',
                                  profileProvider.userProfile?.trainingId
                                          ?.toString() ??
                                      'N/A',
                                ),
                                Divider(),
                                _buildProfileRow(
                                  'Terdaftar Sejak',
                                  profileProvider.userProfile?.createdAt != null
                                      ? DateFormatter.formatDate(
                                        profileProvider.userProfile!.createdAt!,
                                      )
                                      : 'N/A',
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await authProvider.logout();
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AppConstants.loginRoute);
                            },
                            icon: Icon(Icons.logout),
                            label: Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
