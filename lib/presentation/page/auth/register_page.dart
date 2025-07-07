import 'package:absensi/data/models/batch_model.dart';
import 'package:absensi/data/models/training_model.dart';
import 'package:absensi/providers/auth_provider.dart';
import 'package:absensi/providers/profile_provider.dart';
import 'package:absensi/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // To fetch batches and trainings

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Batch? _selectedBatch;
  Training? _selectedTraining;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchBatches();
      Provider.of<ProfileProvider>(context, listen: false).fetchTrainings();
    });
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBatch == null || _selectedTraining == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mohon pilih Batch dan Training')),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        batchId: _selectedBatch!.id!,
        trainingId: _selectedTraining!.id!,
      );

      if (success) {
        Navigator.of(context).pushReplacementNamed(AppConstants.dashboardRoute);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registrasi gagal'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Lengkap'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
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
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, child) {
                  if (profileProvider.isLoading &&
                      profileProvider.batches == null) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return DropdownButtonFormField<Batch>(
                    value: _selectedBatch,
                    decoration: InputDecoration(labelText: 'Pilih Batch'),
                    items:
                        profileProvider.batches?.map((batch) {
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
              SizedBox(height: 16),
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, child) {
                  if (profileProvider.isLoading &&
                      profileProvider.trainings == null) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return DropdownButtonFormField<Training>(
                    value: _selectedTraining,
                    decoration: InputDecoration(labelText: 'Pilih Training'),
                    items:
                        profileProvider.trainings?.map((training) {
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
              SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return authProvider.isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: _register,
                        child: Text('Register'),
                      );
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppConstants.loginRoute);
                },
                child: Text('Sudah punya akun? Login di sini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
