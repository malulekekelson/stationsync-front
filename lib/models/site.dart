import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Site {
  final String id;
  final String userId;
  final String siteName;
  final String physicalAddress;
  final String gpsCoordinates;
  final double? storageCapacity;
  final String licenseNumber;
  final DateTime licenseIssueDate;
  final DateTime licenseExpiryDate;
  final String status; // active, suspended, expired, pending_renewal
  final int riskScore;
  final DateTime? lastInspectionDate;
  final String? lastInspectionResult;
  final String complianceStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Site({
    required this.id,
    required this.userId,
    required this.siteName,
    required this.physicalAddress,
    required this.gpsCoordinates,
    this.storageCapacity,
    required this.licenseNumber,
    required this.licenseIssueDate,
    required this.licenseExpiryDate,
    required this.status,
    required this.riskScore,
    this.lastInspectionDate,
    this.lastInspectionResult,
    required this.complianceStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      userId: json['user_id'],
      siteName: json['site_name'] ?? '',
      physicalAddress: json['physical_address'] ?? '',
      gpsCoordinates: json['gps_coordinates'] ?? '',
      storageCapacity: json['storage_capacity']?.toDouble(),
      licenseNumber: json['license_number'] ?? '',
      licenseIssueDate: json['license_issue_date'] != null
          ? DateTime.parse(json['license_issue_date'])
          : DateTime.now(),
      licenseExpiryDate: json['license_expiry_date'] != null
          ? DateTime.parse(json['license_expiry_date'])
          : DateTime.now().add(const Duration(days: 365 * 5)),
      status: json['status'] ?? 'active',
      riskScore: json['risk_score'] ?? 0,
      lastInspectionDate: json['last_inspection_date'] != null
          ? DateTime.parse(json['last_inspection_date'])
          : null,
      lastInspectionResult: json['last_inspection_result'],
      complianceStatus: json['compliance_status'] ?? 'compliant',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isExpired => licenseExpiryDate.isBefore(DateTime.now());
  bool get isExpiringSoon {
    final daysUntilExpiry = licenseExpiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 90 && daysUntilExpiry > 0;
  }

  bool get needsInspection {
    if (lastInspectionDate == null) return true;
    final daysSinceInspection =
        DateTime.now().difference(lastInspectionDate!).inDays;
    return daysSinceInspection > 365; // Annual inspection required
  }

  String get riskLevel {
    if (riskScore < 30) return 'Low';
    if (riskScore < 70) return 'Medium';
    return 'High';
  }

  Color get riskColor {
    if (riskScore < 30) return const Color(0xFF10B981);
    if (riskScore < 70) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get daysUntilExpiry {
    final days = licenseExpiryDate.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return '$days days';
  }

  String get formattedLicenseIssueDate {
    return DateFormat('dd MMM yyyy').format(licenseIssueDate);
  }

  String get formattedLicenseExpiryDate {
    return DateFormat('dd MMM yyyy').format(licenseExpiryDate);
  }

  String get formattedLastInspection {
    if (lastInspectionDate == null) return 'Never';
    return DateFormat('dd MMM yyyy').format(lastInspectionDate!);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'site_name': siteName,
      'physical_address': physicalAddress,
      'gps_coordinates': gpsCoordinates,
      'storage_capacity': storageCapacity,
      'license_number': licenseNumber,
      'license_issue_date': licenseIssueDate.toIso8601String(),
      'license_expiry_date': licenseExpiryDate.toIso8601String(),
      'status': status,
      'risk_score': riskScore,
      'last_inspection_date': lastInspectionDate?.toIso8601String(),
      'last_inspection_result': lastInspectionResult,
      'compliance_status': complianceStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
