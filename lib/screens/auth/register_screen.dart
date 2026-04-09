import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/loading_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final _apiClient = ApiClient();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  int _resendCooldown = 60;
  Timer? _resendTimer;
  String? _otpError;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter email address first', AppColors.error);
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showSnackBar('Please enter a valid email address', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.sendOtp(
        _emailController.text.trim(),
        _fullNameController.text.trim().isEmpty
            ? 'User'
            : _fullNameController.text.trim(),
      );

      if (response['success'] == true) {
        setState(() {
          _isOtpSent = true;
          _resendCooldown = 60;
          _otpError = null;
        });
        _startResendTimer();
        _showSnackBar(
            'Verification code sent to your email', AppColors.success);
      } else {
        _showSnackBar(response['error'] ?? 'Failed to send verification code',
            AppColors.error);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      setState(() => _otpError = 'Please enter verification code');
      return;
    }

    if (_otpController.text.length != 6) {
      setState(() => _otpError = 'Verification code must be 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      final response = await _apiClient.verifyOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );

      if (response['success'] == true) {
        setState(() {
          _isOtpVerified = true;
        });
        _showSnackBar('Email verified successfully!', AppColors.success);
      } else {
        setState(() {
          _otpError = response['error'] ?? 'Invalid verification code';
        });
        _showSnackBar(_otpError!, AppColors.error);
      }
    } catch (e) {
      setState(() {
        _otpError = 'Verification failed. Please try again.';
      });
      _showSnackBar(_otpError!, AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isOtpVerified) {
      _showSnackBar('Please verify your email first', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.register({
        'email': _emailController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'password': _passwordController.text,
        'company_name': _companyController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        _showSnackBar(
            response['error'] ?? 'Registration failed', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('Connection error. Please try again.', AppColors.error);
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Apply for License',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your applicant account',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Full name required' : null,
                ),
                const SizedBox(height: 16),

                // Company Name
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Company name required' : null,
                ),
                const SizedBox(height: 16),

                // Email with OTP Send Button
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    suffixIcon: _isOtpSent && _isOtpVerified
                        ? Icon(Icons.verified, color: AppColors.success)
                        : IconButton(
                            icon: Icon(
                              Icons.send,
                              color: _isOtpSent
                                  ? AppColors.textHint
                                  : AppColors.primary,
                            ),
                            onPressed: _isOtpSent ? null : _sendOtp,
                          ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                  onChanged: (_) {
                    if (_isOtpSent) {
                      setState(() {
                        _isOtpSent = false;
                        _isOtpVerified = false;
                        _otpController.clear();
                      });
                    }
                  },
                ),

                // OTP Section (only show after OTP sent)
                if (_isOtpSent && !_isOtpVerified) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'Verification Code',
                                prefixIcon: const Icon(Icons.pin),
                                hintText: 'Enter 6-digit code',
                                errorText: _otpError,
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter the 6-digit code sent to your email',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                          onPressed: _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(80, 56),
                          ),
                          child: const Text('Verify'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _resendCooldown > 0 ? null : _sendOtp,
                        child: Text(
                          _resendCooldown > 0
                              ? 'Resend in ${_resendCooldown}s'
                              : 'Resend Code',
                        ),
                      ),
                    ],
                  ),
                ],

                // Verified indicator
                if (_isOtpVerified) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Email verified successfully!',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    helperText:
                        'Min 8 chars, uppercase, lowercase, number, special',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Password required';
                    if (value!.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Password must contain uppercase letter';
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return 'Password must contain lowercase letter';
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Password must contain number';
                    }
                    if (!RegExp(r'[@$!%*?&]').hasMatch(value)) {
                      return 'Password must contain special character (@\$!%*?&)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                LoadingButton(
                  onPressed: _register,
                  isLoading: _isLoading,
                  text: 'Create Account',
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
