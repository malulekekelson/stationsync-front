import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../models/site.dart';

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
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String scheduleId, String status) async {
    try {
      await _apiClient.updateScheduleStatus(scheduleId, status);
      await _loadSchedules();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Inspection $status'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error),
      );
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
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? const Center(child: Text('No scheduled inspections'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = _schedules[index];
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
                                    schedule['site_name'],
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: schedule['status'] == 'pending'
                                        ? AppColors.warning.withOpacity(0.1)
                                        : AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    schedule['status'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: schedule['status'] == 'pending'
                                          ? AppColors.warning
                                          : AppColors.success,
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
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  'Date: ${schedule['scheduled_date']?.toString().split('T')[0] ?? 'N/A'}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.person,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  'Requested by: ${schedule['requested_by_name'] ?? 'Unknown'}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ],
                            ),
                            if (schedule['notes'] != null &&
                                schedule['notes'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Notes: ${schedule['notes']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                            if (schedule['status'] == 'pending')
                              const SizedBox(height: 12),
                            if (schedule['status'] == 'pending')
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateStatus(
                                          schedule['id'], 'confirmed'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                      ),
                                      child: const Text('Confirm'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _updateStatus(
                                          schedule['id'], 'cancelled'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
