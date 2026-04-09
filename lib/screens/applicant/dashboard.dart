import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../models/application.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/app_logo.dart';
import 'application/new_application_step1.dart';
import 'application_detail.dart';
import 'compliance_dashboard.dart'; // Import Compliance Dashboard
import 'profile_screen.dart';
import 'help_support_screen.dart';

class ApplicantDashboard extends StatefulWidget {
  const ApplicantDashboard({super.key});

  @override
  State<ApplicantDashboard> createState() => _ApplicantDashboardState();
}

class _ApplicantDashboardState extends State<ApplicantDashboard>
    with SingleTickerProviderStateMixin {
  final _apiClient = ApiClient();
  List<Application> _applications = [];
  bool _isLoading = true;
  String _filter = 'all';
  String? _userName;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _apiClient.getCurrentUser();
      setState(() {
        _userName = userData['user']['full_name'];
      });

      await _loadApplications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load data'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadApplications() async {
    try {
      final apps = await _apiClient.listApplications();
      setState(() {
        _applications = apps.map((json) => Application.fromJson(json)).toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  List<Application> _getFilteredApplications() {
    if (_filter == 'all') return _applications;
    return _applications.where((app) => app.status == _filter).toList();
  }

  Future<void> _logout() async {
    await _apiClient.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredApps = _getFilteredApplications();

    return Scaffold(
      appBar: AppBar(
        title: const Text('StationSync'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'Applications'),
            Tab(icon: Icon(Icons.verified), text: 'Compliance'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Applications
          _buildApplicationsTab(filteredApps),
          // Tab 2: Compliance Dashboard
          const ComplianceDashboard(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NewApplicationStep1(),
                  ),
                ).then((_) => _loadApplications());
              },
              icon: const Icon(Icons.add),
              label: const Text('New Application'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  Widget _buildApplicationsTab(List<Application> filteredApps) {
    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: Column(
        children: [
          // Welcome Card
          Container(
            margin: const EdgeInsets.all(16),
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
                    _userName?.substring(0, 1).toUpperCase() ?? 'U',
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
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        _userName?.split(' ').first ?? 'Applicant',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_applications.length} Applications',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard(
                  'Total',
                  _applications.length,
                  Icons.description,
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Approved',
                  _applications.where((a) => a.isApproved).length,
                  Icons.check_circle,
                  AppColors.success,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Pending',
                  _applications
                      .where((a) => a.isSubmitted || a.isUnderReview)
                      .length,
                  Icons.pending,
                  AppColors.warning,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterTabs(),
          ),

          const SizedBox(height: 16),

          // Applications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredApps.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          return _buildApplicationCard(app);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
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

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'draft', 'label': 'Draft'},
      {'key': 'submitted', 'label': 'Submitted'},
      {'key': 'approved', 'label': 'Approved'},
      {'key': 'rejected', 'label': 'Rejected'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filter == filter['key'];

          return GestureDetector(
            onTap: () {
              setState(() => _filter = filter['key']!);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                ),
              ),
              child: Center(
                child: Text(
                  filter['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
              builder: (_) => ApplicationDetailScreen(applicationId: app.id),
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
                      app.licenseType.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusBadge(status: app.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                app.siteDetails?['site_name'] ?? 'No site name',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(app.createdAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (app.submittedAt != null) ...[
                    const Icon(Icons.send, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted: ${_formatDate(app.submittedAt!)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
            Icons.description_outlined,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No applications found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first application',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textHint,
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
                  const AppLogo(size: 60, showText: false),
                  const SizedBox(height: 12),
                  Text(
                    _userName ?? 'Applicant',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Applicant Account',
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
              leading: const Icon(Icons.description),
              title: const Text('My Applications'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
// Replace the Profile and Help & Support ListTiles with:

            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Logout',
                  style: TextStyle(color: AppColors.error)),
              onTap: _logout,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
