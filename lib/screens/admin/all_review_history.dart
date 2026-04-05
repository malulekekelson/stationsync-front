import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../models/application.dart';
import '../../widgets/common/status_badge.dart';

class AllReviewHistoryScreen extends StatefulWidget {
  const AllReviewHistoryScreen({super.key});

  @override
  State<AllReviewHistoryScreen> createState() => _AllReviewHistoryScreenState();
}

class _AllReviewHistoryScreenState extends State<AllReviewHistoryScreen> {
  final _apiClient = ApiClient();
  List<Application> _history = [];
  List<dynamic> _officerStats = [];
  bool _isLoading = true;
  String? _selectedOfficerId;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.getAllReviewHistory(
        officerId: _selectedOfficerId,
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      setState(() {
        _history = (response['history'] as List)
            .map((json) => Application.fromJson(json))
            .toList();
        _officerStats = response['stats'] ?? [];
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Review History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Officer Stats
                if (_officerStats.isNotEmpty)
                  Container(
                    height: 120,
                    margin: const EdgeInsets.all(16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _officerStats.length,
                      itemBuilder: (context, index) {
                        final stat = _officerStats[index];
                        return _buildOfficerStatCard(stat);
                      },
                    ),
                  ),

                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedOfficerId,
                          hint: const Text('All Officers'),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('All Officers')),
                            ..._officerStats.map((stat) => DropdownMenuItem(
                                  value: stat['id'],
                                  child: Text(stat['officer_name']),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedOfficerId = value;
                              _loadHistory();
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _statusFilter,
                          items: const [
                            DropdownMenuItem(
                                value: 'all', child: Text('All Status')),
                            DropdownMenuItem(
                                value: 'approved', child: Text('Approved')),
                            DropdownMenuItem(
                                value: 'rejected', child: Text('Rejected')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _statusFilter = value!;
                              _loadHistory();
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // History List
                Expanded(
                  child: _history.isEmpty
                      ? const Center(child: Text('No review history found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final app = _history[index];
                            return _buildHistoryCard(app);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildOfficerStatCard(Map<String, dynamic> stat) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat['officer_name'],
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text('${stat['approved_count'] ?? 0}',
                  style: GoogleFonts.inter(fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.cancel, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text('${stat['rejected_count'] ?? 0}',
                  style: GoogleFonts.inter(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Total: ${stat['total_count'] ?? 0}',
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Application app) {
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
                    app.licenseType.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                StatusBadge(status: app.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              app.siteDetails?['site_name'] ?? 'No site name',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  app.companyDetails?['company_name'] ?? 'Unknown',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Reviewed: ${_formatDate(app.reviewedAt ?? app.createdAt)}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
            if (app.rejectedReason != null && app.status == 'rejected')
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Reason: ${app.rejectedReason}',
                  style:
                      GoogleFonts.inter(fontSize: 11, color: AppColors.error),
                ),
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
