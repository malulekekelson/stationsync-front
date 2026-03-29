import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class ComplianceHistory {
  final String id;
  final String siteId;
  final String eventType; // inspection, renewal, violation, corrective_action
  final DateTime eventDate;
  final String description;
  final int riskScoreChange;
  final DateTime createdAt;

  ComplianceHistory({
    required this.id,
    required this.siteId,
    required this.eventType,
    required this.eventDate,
    required this.description,
    required this.riskScoreChange,
    required this.createdAt,
  });

  factory ComplianceHistory.fromJson(Map<String, dynamic> json) {
    return ComplianceHistory(
      id: json['id'],
      siteId: json['site_id'],
      eventType: json['event_type'] ?? 'inspection',
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'])
          : DateTime.now(),
      description: json['description'] ?? '',
      riskScoreChange: json['risk_score_change'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy').format(eventDate);
  }

  String get eventTypeDisplay {
    switch (eventType) {
      case 'inspection':
        return 'Inspection';
      case 'renewal':
        return 'License Renewal';
      case 'violation':
        return 'Violation';
      case 'corrective_action':
        return 'Corrective Action';
      default:
        return eventType;
    }
  }

  IconData get eventIcon {
    switch (eventType) {
      case 'inspection':
        return Icons.engineering;
      case 'renewal':
        return Icons.refresh;
      case 'violation':
        return Icons.warning;
      case 'corrective_action':
        return Icons.build;
      default:
        return Icons.history;
    }
  }

  Color get eventColor {
    switch (eventType) {
      case 'inspection':
        return const Color(0xFF3B82F6);
      case 'renewal':
        return const Color(0xFF10B981);
      case 'violation':
        return const Color(0xFFEF4444);
      case 'corrective_action':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String get riskScoreDisplay {
    if (riskScoreChange == 0) return 'No change';
    if (riskScoreChange > 0) {
      return '+$riskScoreChange points';
    }
    return '$riskScoreChange points';
  }

  Color get riskScoreColor {
    if (riskScoreChange > 0) return const Color(0xFFEF4444);
    if (riskScoreChange < 0) return const Color(0xFF10B981);
    return const Color(0xFF64748B);
  }
}
