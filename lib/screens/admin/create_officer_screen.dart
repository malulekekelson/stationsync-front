import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/loading_button.dart';

class CreateOfficerScreen extends StatefulWidget {
  const CreateOfficerScreen({super.key});

  @override
  State<CreateOfficerScreen> createState() => _CreateOfficerScreenState();
}

class _CreateOfficerScreenState extends State<CreateOfficerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _apiClient = ApiClient();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _createOfficer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.createOfficer({
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'department': _departmentController.text.trim(),
      });

      if (response['success'] == true) {
        if (mounted) {
          // Show success dialog with temporary password
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Officer Created'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Officer account has been created successfully.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email: ${response['officer']['email']}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Temporary Password: ${response['temporary_password']}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '⚠️ Please share this password with the officer securely.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    'The officer will be required to change their password on first login.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        _showError(response['error'] ?? 'Failed to create officer');
      }
    } catch (e) {
      _showError('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Officer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Add New Officer',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Create a new officer account for DMRE or municipal staff',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Full Name Field
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'e.g., John Doe',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'officer@dmre.gov.za',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Department Field (Optional)
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department (Optional)',
                  prefixIcon: Icon(Icons.business_outlined),
                  hintText: 'e.g., DMRE, Municipal',
                ),
              ),
              const SizedBox(height: 32),

              // Create Button
              LoadingButton(
                onPressed: _createOfficer,
                isLoading: _isLoading,
                text: 'Create Officer',
              ),

              const SizedBox(height: 16),

              // Info Text
              Text(
                'The officer will receive a temporary password and must change it on first login.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
