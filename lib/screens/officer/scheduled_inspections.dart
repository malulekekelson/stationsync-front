import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';

class ScheduledInspectionsScreen extends StatefulWidget {
  const ScheduledInspectionsScreen({super.key});

  @override
  State<ScheduledInspectionsScreen> createState() =>
      _ScheduledInspectionsScreenState();
}

class _ScheduledInspectionsScreenState
    extends State<ScheduledInspectionsScreen> {
  final _apiClient = ApiClient();
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  String? _actionInProgress;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await _apiClient.getScheduledInspections();
      setState(() {
        _schedules = schedules;
      });
      print('Loaded ${_schedules.length} scheduled inspections');
    } catch (e) {
      print('Error loading schedules: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String scheduleId, String status) async {
    setState(() => _actionInProgress = scheduleId);

    try {
      await _apiClient.updateScheduleStatus(scheduleId, status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Inspection ${status == 'confirmed' ? 'confirmed' : 'cancelled'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Reload the list to show updated status
      await _loadSchedules();
    } catch (e) {
      print('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Inspections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text(
                        'No pending inspection requests',
                        style: GoogleFonts.inter(
                            fontSize: 16, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When applicants request inspections, they will appear here',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textHint),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = _schedules[index];
                    final isProcessing = _actionInProgress == schedule['id'];
                    final status = schedule['status'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    schedule['site_name'] ?? 'Unknown Site',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'pending'
                                        ? AppColors.warning.withOpacity(0.1)
                                        : status == 'confirmed'
                                            ? AppColors.success.withOpacity(0.1)
                                            : AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: status == 'pending'
                                          ? AppColors.warning
                                          : status == 'confirmed'
                                              ? AppColors.success
                                              : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    schedule['physical_address'] ??
                                        'No address',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  'Requested by: ${schedule['requested_by_name'] ?? 'Unknown'}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  'Date: ${_formatDate(schedule['scheduled_date'])}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  'Type: ${schedule['inspection_type'] ?? 'Annual'}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ],
                            ),
                            if (schedule['notes'] != null &&
                                schedule['notes'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '📝 Notes: ${schedule['notes']}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: AppColors.textHint),
                                ),
                              ),
                            if (status == 'pending') ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _updateStatus(
                                              schedule['id'], 'confirmed'),
                                      icon: isProcessing
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))
                                          : const Icon(Icons.check, size: 18),
                                      label: Text(isProcessing
                                          ? 'Processing...'
                                          : 'Confirm'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _updateStatus(
                                              schedule['id'], 'cancelled'),
                                      icon: isProcessing
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))
                                          : const Icon(Icons.close, size: 18),
                                      label: Text(isProcessing
                                          ? 'Processing...'
                                          : 'Cancel'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(
                                            color: AppColors.error),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (status == 'confirmed') ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 16, color: AppColors.success),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Inspection confirmed. The applicant has been notified.',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.success),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (status == 'cancelled') ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel,
                                        size: 16, color: AppColors.error),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Inspection cancelled. The applicant has been notified.',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      final date = DateTime.parse(dateValue);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateValue.toString().split('T')[0];
    }
  }
}
