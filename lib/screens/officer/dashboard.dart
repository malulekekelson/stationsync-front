import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../models/application.dart';
import '../../widgets/common/status_badge.dart';
import 'review_application.dart';
import 'review_history.dart';
import 'inspection_log_screen.dart';
import 'scheduled_inspections.dart';
import 'pending_renewals.dart';
import '../../models/site.dart';

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  State<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  final _apiClient = ApiClient();
  List<Application> _applications = [];
  bool _isLoading = true;
  String? _userName;
  int _pendingCount = 0;
  int _pendingRenewalsCount = 0;
  int _scheduledInspectionsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _apiClient.getCurrentUser();
      setState(() {
        _userName = userData['user']['full_name'];
      });
      await _loadApplications();
      await _loadCounts();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadApplications() async {
    try {
      final apps = await _apiClient.getPendingApplications();
      setState(() {
        _applications = apps.map((json) => Application.fromJson(json)).toList();
        _pendingCount = _applications.length;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadCounts() async {
    try {
      final renewals = await _apiClient.getPendingRenewals();
      setState(() {
        _pendingRenewalsCount = renewals.length;
      });

      final inspections = await _apiClient.getScheduledInspections();
      setState(() {
        _scheduledInspectionsCount = inspections.length;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _logout() async {
    await _apiClient.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReviewHistoryScreen()),
              );
            },
            tooltip: 'Review History',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadApplications,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(),
              const SizedBox(height: 16),

              // Quick Stats Row
              _buildStatsRow(),
              const SizedBox(height: 24),

              // Quick Actions Grid
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),

              // Pending Applications Section
              _buildPendingApplicationsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              _userName?.substring(0, 1).toUpperCase() ?? 'O',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  _userName?.split(' ').first ?? 'Officer',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _pendingCount.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Pending',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending Renewals',
            _pendingRenewalsCount,
            Icons.refresh,
            AppColors.warning,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PendingRenewalsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Scheduled Inspections',
            _scheduledInspectionsCount,
            Icons.calendar_today,
            AppColors.info,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ScheduledInspectionsScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, int count, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center, // ✅ correct place
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'Review History',
              Icons.history,
              AppColors.primary,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ReviewHistoryScreen()),
                );
              },
            ),
            _buildActionCard(
              'Log Inspection',
              Icons.assignment,
              AppColors.success,
              () {
                // Navigate to sites list first, then inspection log
                _showSitesForInspection();
              },
            ),
            _buildActionCard(
              'View Renewals',
              Icons.refresh,
              AppColors.warning,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PendingRenewalsScreen()),
                );
              },
            ),
            _buildActionCard(
              'Inspections',
              Icons.calendar_month,
              AppColors.info,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ScheduledInspectionsScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSitesForInspection() async {
    try {
      final sites = await _apiClient.getSites();
      if (sites.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active sites found')),
        );
        return;
      }

      // Show dialog to select site
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Site'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sites.length,
              itemBuilder: (context, index) {
                final site = sites[index];
                return ListTile(
                  title: Text(site['site_name']),
                  subtitle: Text(site['physical_address'] ?? 'No address'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InspectionLogScreen(
                          site: Site.fromJson(site),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load sites: $e')),
      );
    }
  }

  Widget _buildPendingApplicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Applications',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // Refresh
                _loadApplications();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _applications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _applications.length,
                    itemBuilder: (context, index) {
                      final app = _applications[index];
                      return _buildApplicationCard(app);
                    },
                  ),
      ],
    );
  }

  Widget _buildApplicationCard(Application app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewApplicationScreen(applicationId: app.id),
            ),
          ).then((_) => _loadApplications());
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
                      'Application #${app.id.substring(0, 8)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  StatusBadge(status: app.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                app.companyDetails?['company_name'] ?? 'No Company',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                app.siteDetails?['physical_address'] ?? 'No Address',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.business,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    app.licenseType.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted: ${_formatDate(app.submittedAt ?? app.createdAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 48, color: AppColors.success),
          const SizedBox(height: 12),
          Text(
            'No pending applications',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              color: AppColors.primary,
              child: Column(
                children: [
                  const Icon(Icons.gavel, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    _userName ?? 'Officer',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'DMRE Officer',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Review History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ReviewHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Pending Renewals'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PendingRenewalsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Scheduled Inspections'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ScheduledInspectionsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout',
                  style: TextStyle(color: AppColors.error)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
