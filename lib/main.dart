import 'package:flutter/material.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/applicant/dashboard.dart';
import 'screens/applicant/application_detail.dart';
import 'screens/applicant/site_detail_screen.dart';
import 'screens/applicant/renewal_workflow.dart';
import 'screens/applicant/application/new_application_step1.dart';
import 'screens/applicant/application/pre_qualification_screen.dart';
import 'screens/applicant/application/new_application_step2.dart';
import 'screens/applicant/application/new_application_step3.dart';
import 'screens/applicant/application/new_application_step4.dart';
import 'screens/applicant/application/new_application_step5.dart';
import 'screens/applicant/application/new_application_step6.dart';
import 'screens/applicant/application/new_application_step7.dart';
import 'screens/officer/dashboard.dart';
import 'screens/officer/review_application.dart';
import 'screens/officer/inspection_log_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/create_officer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clear token on app start to force fresh login
  // This ensures if app was killed, user must login again
  await ApiClient().clearTokenOnStart();

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
      onGenerateRoute: (settings) {
        // Handle routes with parameters
        if (settings.name == '/application-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ApplicationDetailScreen(
              applicationId: args['applicationId'],
            ),
          );
        }
        if (settings.name == '/site-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => SiteDetailScreen(
              site: args['site'],
            ),
          );
        }
        if (settings.name == '/renewal-workflow') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => RenewalWorkflow(
              site: args['site'],
            ),
          );
        }
        if (settings.name == '/review-application') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ReviewApplicationScreen(
              applicationId: args['applicationId'],
            ),
          );
        }
        if (settings.name == '/inspection-log') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => InspectionLogScreen(
              site: args['site'],
            ),
          );
        }
        if (settings.name == '/change-password') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(
              token: args['token'],
              user: args['user'],
            ),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/applicant-dashboard': (context) => const ApplicantDashboard(),
        '/officer-dashboard': (context) => const OfficerDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/create-officer': (context) => const CreateOfficerScreen(),

        // Application Wizard Routes
        '/new-application-step1': (context) => const NewApplicationStep1(),
        '/pre-qualification': (context) => const PreQualificationScreen(
              applicationId: '',
              licenseType: '',
            ),
        '/new-application-step2': (context) => const NewApplicationStep2(
              applicationId: '',
              licenseType: '',
            ),
        '/new-application-step3': (context) => const NewApplicationStep3(
              applicationId: '',
              licenseType: '',
            ),
        '/new-application-step4': (context) => const NewApplicationStep4(
              applicationId: '',
              licenseType: '',
            ),
        '/new-application-step5': (context) => const NewApplicationStep5(
              applicationId: '',
              licenseType: '',
            ),
        '/new-application-step6': (context) => const NewApplicationStep6(
              applicationId: '',
              licenseType: '',
            ),
        '/new-application-step7': (context) => const NewApplicationStep7(
              applicationId: '',
              licenseType: '',
            ),
      },
    );
  }
}
