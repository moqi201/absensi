import 'package:absensi/constants/app_colors.dart';
import 'package:absensi/constants/app_text_styles.dart';
import 'package:absensi/data/models/app_models.dart';
import 'package:absensi/data/service/api_service.dart';
import 'package:absensi/routes/app_router.dart';
import 'package:absensi/widgets/custom_dropdown_input_field.dart';
import 'package:absensi/widgets/custom_input_field.dart';
import 'package:absensi/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Removed _confirmPasswordController
  final ApiService _apiService = ApiService(); // Instantiate your ApiService

  bool _isPasswordVisible = false;
  // Removed _isConfirmPasswordVisible
  bool _isLoading = false; // Add loading state

  List<Batch> _batches = []; // Keep this to fetch batches and find "Batch 2"
  List<Training> _trainings = [];
  int? _selectedBatchId;
  String _selectedBatchName =
      'Loading Batch...'; // To display the selected batch
  int? _selectedTrainingId;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    setState(() {
      _isLoading = true;
    });

    // Fetch Batches
    try {
      final batchResponse = await _apiService.getBatches();
      if (batchResponse.statusCode == 200 && batchResponse.data != null) {
        setState(() {
          _batches = batchResponse.data!;
          // Automatically select "Batch 2" if found, otherwise select the first available batch
          final batch2 = _batches.firstWhere(
            (batch) => batch.batch_ke == '2', // Correctly using batch.batch_ke
            orElse:
                () =>
                    _batches.isNotEmpty
                        ? _batches.first
                        : Batch(
                          id: -1,
                          batch_ke: 'N/A',
                          startDate: '',
                          endDate: '',
                        ), // Corrected Batch constructor
          );
          _selectedBatchId = batch2.id;
          _selectedBatchName =
              'Batch ${batch2.batch_ke}'; // Display as "Batch 2"
        });
      } else {
        if (mounted) {
          final String message = batchResponse.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load batches: $message')),
          );
        }
        setState(() {
          _selectedBatchName = 'Error Loading Batch';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while fetching batches: $e'),
          ),
        );
      }
      setState(() {
        _selectedBatchName = 'Error Loading Batch';
      });
    }

    // Fetch Trainings
    try {
      final trainingResponse = await _apiService.getTrainings();
      if (trainingResponse.statusCode == 200 && trainingResponse.data != null) {
        setState(() {
          _trainings = trainingResponse.data!;
        });
      } else {
        if (mounted) {
          final String message = trainingResponse.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load trainings: $message')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while fetching trainings: $e'),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBatchId == null || _selectedBatchId == -1) {
        // Check for valid batch ID
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch not selected or invalid.')),
        );
        return;
      }
      if (_selectedTrainingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a training')),
        );
        return;
      }
      // Removed password confirmation check
      // if (_passwordController.text != _confirmPasswordController.text) {
      //   ScaffoldMessenger.of(
      //     context,
      //   ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      //   return;
      // }

      setState(() {
        _isLoading = true; // Set loading to true
      });

      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      // Call the register method from ApiService
      final ApiResponse<AuthData> response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        batchId: _selectedBatchId!,
        trainingId: _selectedTrainingId!,
        jenisKelamin: _selectedGender!,
      );

      setState(() {
        _isLoading = false; // Set loading to false
      });

      if (response.statusCode == 200 && response.data != null) {
        // Registration successful
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        // Registration failed, show error message
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // Removed _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Changed to AppColors.background
      body: Stack(
        children: [
          // Top Wave Background with Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: WaveClipper(), // Custom clipper for the wave shape
              child: Container(
                height: 250, // Height of the wave section
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ], // Use a gradient for a richer look
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Main content without SingleChildScrollView
          SafeArea(
            // Keep SafeArea to avoid system UI overlap
            child: Padding(
              // Apply padding directly to the content
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Adjust spacing at the top to account for the wave
                    // Increased space for the wave effect
                    // --- Logo Section ---
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png', // Path to your logo image
                        height: 120, // Adjust height as needed
                        width: 120, // Adjust width as needed
                      ),
                    ),
                    const SizedBox(height: 36), // Spacing after the logo
                    // --- End Logo Section ---
                    Text(
                      "Create Account",
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.primary,
                        fontSize: 28,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Username Input Field with Shadow
                    Container(
                      decoration: BoxDecoration(
                        // Removed borderRadius from here
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CustomInputField(
                        controller: _nameController,
                        hintText: "Name",
                        icon: Icons.person_outline,
                        // Removed borderRadius from here
                        customValidator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name cannot be empty';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Input Field with Shadow
                    Container(
                      decoration: BoxDecoration(
                        // Removed borderRadius from here
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CustomInputField(
                        controller: _emailController,
                        hintText: "Email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        // Removed borderRadius from here
                        customValidator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email cannot be empty';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Input Field with Shadow
                    Container(
                      decoration: BoxDecoration(
                        // Removed borderRadius from here
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CustomInputField(
                        controller: _passwordController,
                        hintText: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: !_isPasswordVisible,
                        // Removed borderRadius from here
                        toggleVisibility:
                            () => setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            }),
                        customValidator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Removed Confirm Password Field
                    // Container(
                    //   decoration: const BoxDecoration(
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.grey.withOpacity(0.2),
                    //         spreadRadius: 2,
                    //         blurRadius: 5,
                    //         offset: Offset(0, 3),
                    //       ),
                    //     ],
                    //   ),
                    //   child: CustomInputField(
                    //     controller: _confirmPasswordController,
                    //     hintText: "Confirm Password",
                    //     icon: Icons.lock_outline,
                    //     isPassword: true,
                    //     obscureText: !_isConfirmPasswordVisible,
                    //     toggleVisibility:
                    //         () => setState(() {
                    //           _isConfirmPasswordVisible =
                    //               !_isConfirmPasswordVisible;
                    //         }),
                    //     customValidator: (value) {
                    //       if (value == null || value.isEmpty) {
                    //         return 'Confirm password cannot be empty';
                    //       }
                    //       if (value != _passwordController.text) {
                    //         return 'Passwords do not match';
                    //       }
                    //       return null;
                    //     },
                    //   ),
                    // ),
                    // const SizedBox(height: 16),

                    // Jenis Kelamin Dropdown with Shadow
                    Container(
                      decoration: BoxDecoration(
                        // Removed borderRadius from here
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CustomDropdownInputField<String>(
                        labelText: 'Select Gender',
                        hintText: 'Select Gender',
                        icon: Icons.people_outline,
                        value: _selectedGender,
                        // Removed borderRadius from here
                        items: const [
                          DropdownMenuItem(
                            value: 'L',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'P',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select your gender';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Display Batch Name (not a dropdown) with Shadow
                    _isLoading
                        ? const Center(
                          // child: CircularProgressIndicator(
                          //   color: AppColors.primary,
                          // ),
                        )
                        : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            // Removed borderRadius from here
                            color: AppColors.inputFill,
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              // Add shadow here
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.group_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedBatchName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 16),

                    // Training Dropdown using CustomDropdownInputField with Shadow
                    _isLoading
                        ? const SizedBox.shrink()
                        : Container(
                          decoration: BoxDecoration(
                            // Removed borderRadius from here
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CustomDropdownInputField<int>(
                            labelText: 'Select Training',
                            hintText: 'Select Training',
                            icon: Icons.school_outlined,
                            value: _selectedTrainingId,
                            // Removed borderRadius from here
                            items:
                                _trainings.map((training) {
                                  return DropdownMenuItem<int>(
                                    value: training.id,
                                    child: Text(training.title),
                                  );
                                }).toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                _selectedTrainingId = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a training';
                              }
                              return null;
                            },
                            menuMaxHeight: 300.0, // Apply menuMaxHeight here
                          ),
                        ),
                    const SizedBox(height: 32),

                    // Register Button with Shadow
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                        : Container(
                          decoration: BoxDecoration(
                            // Removed borderRadius from here
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                spreadRadius: 3,
                                blurRadius: 7,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: PrimaryButton(
                            label: "Register",
                            onPressed: _register,
                            // Removed borderRadius from here
                          ),
                        ),
                    const SizedBox(height: 20),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          GestureDetector(
                            onTap:
                                () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                ),
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Clipper for the wave shape at the top
// This class needs to be added to your RegisterScreen.dart file
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50); // Start from bottom-left of the wave
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0); // Go to top-right
    path.close(); // Close the path
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false; // No need to reclip unless the size changes
  }
}
