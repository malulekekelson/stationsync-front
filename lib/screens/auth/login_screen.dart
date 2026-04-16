import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/loading_button.dart';
import 'register_screen.dart';
import 'change_password_screen.dart';
import '../applicant/dashboard.dart';
import '../officer/dashboard.dart';
import 'package:dio/dio.dart';
import 'forgot_password_screen.dart'; // ✅ ADD THIS IMPORT

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiClient = ApiClient();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please enter email and password', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.login({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      if (response['success'] == true) {
        final user = response['user'];
        final needsPasswordChange = response['needsPasswordChange'] ?? false;

        if (needsPasswordChange) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChangePasswordScreen(
                  token: response['token'],
                  user: user,
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            if (user['role'] == 'applicant') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ApplicantDashboard()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OfficerDashboard()),
              );
            }
          }
        }
      } else {
        final errorMsg = response['error'] ?? 'Login failed';
        _showSnackBar(errorMsg, AppColors.error);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _showSnackBar('Invalid email or password', AppColors.error);
      } else if (e.response?.statusCode == 429) {
        _showSnackBar(
            'Too many attempts. Please try again later.', AppColors.error);
      } else {
        _showSnackBar(
            'Connection error. Please check your internet.', AppColors.error);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const AppLogo(size: 80, showText: true),
              const SizedBox(height: 48),
              Text(
                'Welcome Back',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your account',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // EMAIL
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 16),

              // PASSWORD
              TextField(
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
                ),
              ),

              // ✅ ADDED HERE (correct placement)
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // LOGIN BUTTON
              LoadingButton(
                onPressed: _login,
                isLoading: _isLoading,
                text: 'Sign In',
              ),

              const SizedBox(height: 16),

              // REGISTER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
