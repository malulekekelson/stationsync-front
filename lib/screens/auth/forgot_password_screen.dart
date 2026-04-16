import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/loading_button.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _apiClient = ApiClient();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _token;

  Future<void> _sendResetCode() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter your email address', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response =
          await _apiClient.forgotPassword(_emailController.text.trim());

      if (response['success'] == true) {
        setState(() {
          _emailSent = true;
          _token = response['token'];
        });
        _showSnackBar('Reset code sent to your email', AppColors.success);
      } else {
        _showSnackBar(
            response['error'] ?? 'Failed to send reset code', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('Connection error. Please try again.', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCodeAndReset() async {
    if (_resetCodeController.text.isEmpty) {
      _showSnackBar('Please enter the reset code', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Navigate to reset password with the code
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            token: _resetCodeController.text.trim().toUpperCase(),
            email: _emailController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Error. Please try again.', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.lock_reset,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Reset Password',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _emailSent
                    ? 'Enter the 8-character reset code sent to your email.'
                    : 'Enter your email address and we will send you a reset code.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_emailSent) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  onPressed: _sendResetCode,
                  isLoading: _isLoading,
                  text: 'Send Reset Code',
                ),
              ] else ...[
                TextField(
                  controller: _resetCodeController,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Reset Code',
                    prefixIcon: Icon(Icons.pin),
                    hintText: 'XXXX-XXXX',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 8-character code from your email',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _sendResetCode,
                      child: const Text('Resend Code'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LoadingButton(
                  onPressed: _verifyCodeAndReset,
                  isLoading: _isLoading,
                  text: 'Verify & Reset Password',
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
