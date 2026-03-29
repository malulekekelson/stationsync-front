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
  bool _isLoading = true;
  int _expiringCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Get all sites
      final sitesData = await _apiClient.getSites();
      setState(() {
        _sites = sitesData.map((json) => Site.fromJson(json)).toList();
      });

      // Get expiring licenses
      final expiringData = await _apiClient.getExpiringLicenses();
      setState(() {
        _expiringSites =
            expiringData.map((json) => Site.fromJson(json)).toList();
        _expiringCount = _expiringSites.length;
      });
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                      leading: const Icon(Icons.warning_amber,
                          color: AppColors.warning),
                      title: Text(site.siteName),
                      subtitle: Text('Expires in ${site.daysUntilExpiry} days'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RenewalWorkflow(site: site),
                            ),
                          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Dashboard'),
        actions: [
          // Notification bell for expiring licenses
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
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
            ? const Center(child: CircularProgressIndicator())
            : _sites.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sites.length,
                    itemBuilder: (context, index) {
                      final site = _sites[index];
                      return _buildSiteCard(site);
                    },
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SiteDetailScreen(site: site),
            ),
          ).then((_) => _loadData()); // Refresh on return
        },
        borderRadius: BorderRadius.circular(16),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  Icon(Icons.location_on, size: 14, color: AppColors.textHint),
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
                  Icon(Icons.confirmation_number,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'License: ${site.licenseNumber.substring(0, 8)}...',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today,
                      size: 12, color: AppColors.textHint),
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
                    _buildStatusChip('Inspection Due', AppColors.warning),
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
              // Progress bar for risk score
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: site.riskScore / 100,
                  backgroundColor: Colors.grey[200],
                  color: site.riskColor,
                  minHeight: 4,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 80, color: AppColors.textHint),
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
