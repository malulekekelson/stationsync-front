import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';

class PendingRenewalsScreen extends StatefulWidget {
  const PendingRenewalsScreen({super.key});

  @override
  State<PendingRenewalsScreen> createState() => _PendingRenewalsScreenState();
}

class _PendingRenewalsScreenState extends State<PendingRenewalsScreen> {
  final _apiClient = ApiClient();
  List<dynamic> _renewals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRenewals();
  }

  Future<void> _loadRenewals() async {
    setState(() => _isLoading = true);
    try {
      final renewals = await _apiClient.getPendingRenewals();
      setState(() {
        _renewals = renewals;
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRenewal(
      String renewalId, String siteId, String currentExpiry) async {
    // Calculate new expiry date (5 years from now)
    final newExpiry = DateTime.now().add(const Duration(days: 365 * 5));

    try {
      await _apiClient.approveRenewal(renewalId, newExpiry.toIso8601String());
      await _loadRenewals();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Renewal approved'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Renewals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRenewals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _renewals.isEmpty
              ? const Center(child: Text('No pending renewals'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _renewals.length,
                  itemBuilder: (context, index) {
                    final renewal = _renewals[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              renewal['site_name'],
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Applicant: ${renewal['applicant_name']}',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            Text(
                              'Email: ${renewal['applicant_email']}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Divider(),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _approveRenewal(
                                      renewal['id'],
                                      renewal['site_id'],
                                      renewal['new_expiry_date'],
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                    ),
                                    child: const Text('Approve Renewal'),
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
