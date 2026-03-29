import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Inspection {
  final String id;
  final String siteId;
  final String inspectorId;
  final String inspectorName;
  final DateTime inspectionDate;
  final String inspectionType; // initial, annual, follow_up, random
  final String findings;
  final bool passed;
  final int riskImpact;
  final String? reportUrl;
  final DateTime createdAt;

  Inspection({
    required this.id,
    required this.siteId,
    required this.inspectorId,
    required this.inspectorName,
    required this.inspectionDate,
    required this.inspectionType,
    required this.findings,
    required this.passed,
    required this.riskImpact,
    this.reportUrl,
    required this.createdAt,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'],
      siteId: json['site_id'],
      inspectorId: json['inspector_id'],
      inspectorName: json['inspector_name'] ?? '',
      inspectionDate: json['inspection_date'] != null
          ? DateTime.parse(json['inspection_date'])
          : DateTime.now(),
      inspectionType: json['inspection_type'] ?? 'annual',
      findings: json['findings'] ?? '',
      passed: json['passed'] == 1 || json['passed'] == true,
      riskImpact: json['risk_impact'] ?? 0,
      reportUrl: json['report_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy').format(inspectionDate);
  }

  String get statusDisplay => passed ? 'Passed' : 'Failed';
  Color get statusColor =>
      passed ? const Color(0xFF10B981) : const Color(0xFFEF4444);
  IconData get statusIcon => passed ? Icons.check_circle : Icons.warning;
}
