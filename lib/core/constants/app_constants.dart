import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'StationSync';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl =
      'https://stationsync-api.malulekekelson.workers.dev';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String storageTokenKey = 'auth_token';
  static const String storageUserKey = 'user_data';
  static const String storageThemeKey = 'theme_mode';

  // Application Statuses
  static const List<String> licenseTypes = [
    'retail',
    'wholesale',
    'manufacturing',
    'storage',
  ];

  static const Map<String, String> documentTypes = {
    'registration_cert': 'Company Registration Certificate',
    'bee_cert': 'B-BBEE Certificate',
    'env_approval': 'Environmental Approval',
    'municipal_approval': 'Municipal Approval',
    'land_use': 'Land Use Permission',
    'id_copy': 'ID Copy (Directors)',
    'site_plan': 'Site Plan',
    'other': 'Other Documents',
  };

  static const Map<String, Color> statusColors = {
    'draft': Color(0xFF64748B),
    'submitted': Color(0xFF3B82F6),
    'under_review': Color(0xFFF59E0B),
    'info_requested': Color(0xFF8B5CF6),
    'approved': Color(0xFF10B981),
    'rejected': Color(0xFFEF4444),
  };

  static const Map<String, String> statusLabels = {
    'draft': 'Draft',
    'submitted': 'Submitted',
    'under_review': 'Under Review',
    'info_requested': 'Additional Info Required',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };
}
