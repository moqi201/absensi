import 'package:absensi/data/models/batch_model.dart';
import 'package:absensi/data/models/training_model.dart';
import 'package:absensi/presentation/page/profil/profile_page.dart';
import 'package:absensi/providers/profile_provider.dart';
// Import ProfileProvider, pastikan jalur ini benar jika berubah
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Tambahkan import ini untuk menggunakan firstWhereOrNull
import 'package:collection/collection.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Batch? _selectedBatch;
  Training? _selectedTraining;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );

      profileProvider.fetchProfile().then((_) {
        if (profileProvider.userProfile != null) {
          _nameController.text = profileProvider.userProfile!.name ?? '';
          _emailController.text = profileProvider.userProfile!.email ?? '';

          profileProvider.fetchBatches().then((_) {
            if (profileProvider.batches != null &&
                profileProvider.userProfile?.batchId != null) {
              setState(() {
                // Menggunakan firstWhereOrNull
                _selectedBatch = profileProvider.batches!.firstWhereOrNull(
                  (batch) => batch.id == profileProvider.userProfile!.batchId,
                );
              });
            } else {
              setState(() {
                _selectedBatch =
                    null; // Pastikan null jika tidak ada batch atau ID tidak ada
              });
            }
          });

          profileProvider.fetchTrainings().then((_) {
            if (profileProvider.trainings != null &&
                profileProvider.userProfile?.trainingId != null) {
              setState(() {
                // Menggunakan firstWhereOrNull
                _selectedTraining = profileProvider.trainings!.firstWhereOrNull(
                  (training) =>
                      training.id == profileProvider.userProfile!.trainingId,
                );
              });
            } else {
              setState(() {
                _selectedTraining =
                    null; // Pastikan null jika tidak ada training atau ID tidak ada
              });
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBatch == null || _selectedTraining == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon pilih Batch dan Training')),
        );
        return;
      }

      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      bool success = await profileProvider.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        batchId: _selectedBatch!.id,
        trainingId: _selectedTraining!.id,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              profileProvider.errorMessage ?? 'Gagal memperbarui profil',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body:
          profileProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!value.contains('@')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<ProfileProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading && provider.batches == null) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return DropdownButtonFormField<Batch>(
                            value: _selectedBatch,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Batch',
                            ),
                            items:
                                provider.batches?.map((batch) {
                                  return DropdownMenuItem(
                                    value: batch,
                                    child: Text(batch.name ?? ''),
                                  );
                                }).toList(),
                            onChanged: (Batch? newValue) {
                              setState(() {
                                _selectedBatch = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Batch wajib dipilih';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<ProfileProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading &&
                              provider.trainings == null) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return DropdownButtonFormField<Training>(
                            value: _selectedTraining,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Training',
                            ),
                            items:
                                provider.trainings?.map((training) {
                                  return DropdownMenuItem(
                                    value: training,
                                    child: Text(training.title ?? ''),
                                  );
                                }).toList(),
                            onChanged: (Training? newValue) {
                              setState(() {
                                _selectedTraining = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Training wajib dipilih';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text('Simpan Perubahan'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
