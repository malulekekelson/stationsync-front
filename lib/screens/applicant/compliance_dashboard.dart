import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/site.dart';
import 'site_detail_screen.dart';
import 'renewal_workflow.dart';

class ComplianceDashboard extends StatefulWidget {
  const ComplianceDashboard({super.key});

  @override
  State<ComplianceDashboard> createState() => _ComplianceDashboardState();
}

class _ComplianceDashboardState extends State<ComplianceDashboard> {
  final _apiClient = ApiClient();

  List<Site> _sites = [];
  List<Site> _expiringSites = [];
  List<dynamic> _scheduledInspections = [];

  bool _isLoading = true;
  int _expiringCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadScheduledInspections() async {
    try {
      final schedules = await _apiClient.getScheduledInspections();
      if (mounted) {
        setState(() {
          _scheduledInspections = schedules;
        });
      }
      print('Loaded ${schedules.length} scheduled inspections');
      for (var s in schedules) {
        print('  - ${s['site_name']}: ${s['status']}');
      }
    } catch (e) {
      debugPrint('Error loading scheduled inspections: $e');
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final sitesData = await _apiClient.getSites();
      final expiringData = await _apiClient.getExpiringLicenses();

      if (mounted) {
        setState(() {
          _sites = sitesData.map((json) => Site.fromJson(json)).toList();
          _expiringSites =
              expiringData.map((json) => Site.fromJson(json)).toList();
          _expiringCount = _expiringSites.length;
        });
      }

      await _loadScheduledInspections();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showExpiringAlerts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expiring Licenses'),
        content: _expiringSites.isEmpty
            ? const Text('No licenses expiring soon')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _expiringSites.length,
                  itemBuilder: (context, index) {
                    final site = _expiringSites[index];

                    return ListTile(
                      leading: const Icon(
                        Icons.warning_amber,
                        color: AppColors.warning,
                      ),
                      title: Text(site.siteName),
                      subtitle: Text(
                        'Expires in ${site.daysUntilExpiry} days',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RenewalWorkflow(site: site),
                            ),
                          ).then((_) => _loadData());
                        },
                        child: const Text('Renew'),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) {
      return 'N/A';
    }

    if (dateValue is DateTime) {
      return '${dateValue.day}/${dateValue.month}/${dateValue.year}';
    }

    try {
      final parsedDate = DateTime.parse(dateValue.toString());
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  Widget _buildScheduledInspectionsCard() {
    if (_scheduledInspections.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Scheduled Inspections',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ..._scheduledInspections.map(
              (schedule) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  schedule['status'] == 'confirmed'
                      ? Icons.check_circle
                      : schedule['status'] == 'cancelled'
                          ? Icons.cancel
                          : Icons.pending,
                  color: schedule['status'] == 'confirmed'
                      ? AppColors.success
                      : schedule['status'] == 'cancelled'
                          ? AppColors.error
                          : AppColors.warning,
                ),
                title: Text(
                  schedule['site_name'] ?? 'Unknown Site',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${_formatDate(schedule['scheduled_date'])}',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    Text(
                      'Type: ${schedule['inspection_type'] ?? 'N/A'}',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: schedule['status'] == 'confirmed'
                            ? AppColors.success.withOpacity(0.1)
                            : schedule['status'] == 'cancelled'
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (schedule['status'] ?? 'pending')
                            .toString()
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: schedule['status'] == 'confirmed'
                              ? AppColors.success
                              : schedule['status'] == 'cancelled'
                                  ? AppColors.error
                                  : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _showExpiringAlerts,
                tooltip: 'Expiring Licenses',
              ),
              if (_expiringCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_expiringCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _sites.isEmpty && _scheduledInspections.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_scheduledInspections.isNotEmpty)
                        _buildScheduledInspectionsCard(),
                      ..._sites.map((site) => _buildSiteCard(site)),
                    ],
                  ),
      ),
      floatingActionButton: _expiringCount > 0
          ? FloatingActionButton.extended(
              onPressed: _showExpiringAlerts,
              icon: const Icon(Icons.warning_amber),
              label: Text('$_expiringCount Expiring'),
              backgroundColor: AppColors.warning,
            )
          : null,
    );
  }

  Widget _buildSiteCard(Site site) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SiteDetailScreen(site: site),
            ),
          ).then((_) => _loadData());
        },
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
                      site.siteName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
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
                      color: site.riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Risk: ${site.riskLevel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: site.riskColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      site.physicalAddress,
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
                  const Icon(
                    Icons.confirmation_number,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'License: ${site.licenseNumber.substring(0, 8)}...',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    site.daysUntilExpiry,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: site.isExpiringSoon
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusChip(
                    site.isExpired ? 'Expired' : 'Active',
                    site.isExpired ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  if (site.needsInspection)
                    _buildStatusChip(
                      'Inspection Due',
                      AppColors.warning,
                    ),
                  const Spacer(),
                  if (site.isExpiringSoon && !site.isExpired)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RenewalWorkflow(site: site),
                          ),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Renew'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: site.riskScore / 100,
                  minHeight: 4,
                  backgroundColor: Colors.grey[200],
                  color: site.riskColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.business,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Sites',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your approved applications will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/applicant-dashboard');
            },
            icon: const Icon(Icons.add),
            label: const Text('Apply for License'),
          ),
        ],
      ),
    );
  }
}
