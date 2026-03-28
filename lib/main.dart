import 'package:flutter/material.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/applicant/dashboard.dart';
import 'screens/officer/dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();
  runApp(const StationSyncApp());
}

class StationSyncApp extends StatelessWidget {
  const StationSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StationSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/change-password': (context) => const ChangePasswordScreen(
              token: '',
              user: {},
            ),
        '/applicant-dashboard': (context) => const ApplicantDashboard(),
        '/officer-dashboard': (context) => const OfficerDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
      },
    );
  }
}
