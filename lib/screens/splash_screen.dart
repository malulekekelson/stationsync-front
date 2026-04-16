import 'package:flutter/material.dart';
import '../widgets/common/app_logo.dart';
import '../core/constants/app_colors.dart';
import '../core/api/api_client.dart';
import 'auth/login_screen.dart';
import 'applicant/dashboard.dart';
import 'officer/dashboard.dart';
import 'admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // Check if user is logged in
    final apiClient = ApiClient();
    final token = await apiClient.getToken();

    // Debug print
    debugPrint('=== SPLASH SCREEN: Token exists = ${token != null} ===');

    if (token != null) {
      try {
        final userData = await apiClient.getCurrentUser();
        final role = userData['user']['role'] as String;

        debugPrint('=== USER ROLE DETECTED: $role ===');

        if (mounted) {
          // IMPORTANT: Check super_admin FIRST (most specific first)
          if (role == 'super_admin') {
            debugPrint('✅ Navigating to ADMIN Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          } else if (role == 'officer') {
            debugPrint('✅ Navigating to OFFICER Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OfficerDashboard()),
            );
          } else if (role == 'applicant') {
            debugPrint('✅ Navigating to APPLICANT Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ApplicantDashboard()),
            );
          } else {
            debugPrint('⚠️ Unknown role: $role, going to login');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error getting user: $e');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } else {
      debugPrint('No token found, going to login');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.background,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              AppLogo(size: 100, showText: true),

              SizedBox(height: 48),

              // Loading Indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),

              SizedBox(height: 24),

              // Version
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
