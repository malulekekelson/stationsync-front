import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import 'create_officer_screen.dart';
import 'all_review_history.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _apiClient = ApiClient();
  List<dynamic> _officers = [];
  bool _isLoading = true;
  String? _userName;

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
      await _loadOfficers();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOfficers() async {
    try {
      final officers = await _apiClient.listOfficers();
      setState(() {
        _officers = officers;
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
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AllReviewHistoryScreen()),
              );
            },
            tooltip: 'Review History',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadOfficers,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(),
              const SizedBox(height: 16),

              // Quick Actions Grid
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),

              // Officers Section
              _buildOfficersSection(),
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
              _userName?.substring(0, 1).toUpperCase() ?? 'A',
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
                  'Welcome,',
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
                Text(
                  _userName?.split(' ').first ?? 'Admin',
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
                  _officers.length.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Officers',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
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
              'Create Officer',
              Icons.person_add,
              AppColors.success,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateOfficerScreen()),
                ).then((_) => _loadOfficers());
              },
            ),
            _buildActionCard(
              'Review History',
              Icons.history,
              AppColors.primary,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AllReviewHistoryScreen()),
                );
              },
            ),
            _buildActionCard(
              'View All Officers',
              Icons.people,
              AppColors.info,
              () {
                // Scroll to officers section
              },
            ),
            _buildActionCard(
              'System Stats',
              Icons.analytics,
              AppColors.warning,
              () {
                // Show stats dialog
                _showStatsDialog();
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

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Officers', _officers.length),
            _buildStatRow('Active Officers',
                _officers.where((o) => o['is_active'] == 1).length),
            const Divider(),
            _buildStatRow('Total Applications', 'Loading...'),
            _buildStatRow('Approved Applications', 'Loading...'),
            _buildStatRow('Rejected Applications', 'Loading...'),
          ],
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

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14)),
          Text(
            value.toString(),
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Officers',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateOfficerScreen()),
                ).then((_) => _loadOfficers());
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Officer'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _officers.isEmpty
                ? _buildEmptyOfficersState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _officers.length,
                    itemBuilder: (context, index) {
                      final officer = _officers[index];
                      return _buildOfficerCard(officer);
                    },
                  ),
      ],
    );
  }

  Widget _buildOfficerCard(Map<String, dynamic> officer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                officer['full_name'][0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    officer['full_name'],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    officer['email'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (officer['department'] != null)
                    Text(
                      officer['department'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: officer['is_active'] == 1
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                officer['is_active'] == 1 ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 10,
                  color: officer['is_active'] == 1
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOfficersState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            'No officers found',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateOfficerScreen()),
              ).then((_) => _loadOfficers());
            },
            icon: const Icon(Icons.add),
            label: const Text('Create First Officer'),
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
                  const Icon(Icons.admin_panel_settings,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    _userName ?? 'Admin',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'System Administrator',
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
                      builder: (_) => const AllReviewHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Create Officer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateOfficerScreen()),
                ).then((_) => _loadOfficers());
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
}
