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
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Officer Created'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${response['officer']['email']}'),
                  const SizedBox(height: 8),
                  Text('Temporary Password: ${response['temporary_password']}'),
                  const SizedBox(height: 16),
                  Text(
                    'Please share this password with the officer securely.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.warning,
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
      _showError('Connection error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
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
              const Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Add New Officer',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new officer account for DMRE or municipal staff',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (!v!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department (Optional)',
                  prefixIcon: Icon(Icons.business),
                  hintText: 'e.g., DMRE, Municipal',
                ),
              ),
              const SizedBox(height: 32),
              LoadingButton(
                onPressed: _createOfficer,
                isLoading: _isLoading,
                text: 'Create Officer',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
