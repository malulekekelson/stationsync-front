import 'package:flutter/material.dart';
import 'dart:convert';

class Application {
  final String id;
  final String userId;
  final String licenseType;
  final Map<String, dynamic>? companyDetails;
  final Map<String, dynamic>? siteDetails;
  final String status;
  final String? siteName;
  final String? physicalAddress;
  final String? gpsCoordinates;
  final String? officerNotes;
  final String? rejectedReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Application({
    required this.id,
    required this.userId,
    required this.licenseType,
    this.companyDetails,
    this.siteDetails,
    required this.status,
    this.siteName,
    this.physicalAddress,
    this.gpsCoordinates,
    this.officerNotes,
    this.rejectedReason,
    this.reviewedBy,
    this.reviewedAt,
    this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      userId: json['user_id'],
      licenseType: json['license_type'],
      companyDetails: json['company_details'] != null
          ? jsonDecode(json['company_details'])
          : null,
      siteDetails: json['site_details'] != null
          ? jsonDecode(json['site_details'])
          : null,
      status: json['status'],
      siteName: json['site_name'],
      physicalAddress: json['physical_address'],
      gpsCoordinates: json['gps_coordinates'],
      officerNotes: json['officer_notes'],
      rejectedReason: json['rejected_reason'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isDraft => status == 'draft';
  bool get isSubmitted => status == 'submitted';
  bool get isUnderReview => status == 'under_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isInfoRequested => status == 'info_requested';

  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'info_requested':
        return 'Info Required';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'draft':
        return const Color(0xFF64748B);
      case 'submitted':
        return const Color(0xFF3B82F6);
      case 'under_review':
        return const Color(0xFFF59E0B);
      case 'info_requested':
        return const Color(0xFF8B5CF6);
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }
}
