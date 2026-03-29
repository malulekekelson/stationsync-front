import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../models/site.dart';
import '../../widgets/common/loading_button.dart';
import 'compliance_dashboard.dart';

class RenewalWorkflow extends StatefulWidget {
  final Site site;

  const RenewalWorkflow({super.key, required this.site});

  @override
  State<RenewalWorkflow> createState() => _RenewalWorkflowState();
}

class _RenewalWorkflowState extends State<RenewalWorkflow> {
  final _apiClient = ApiClient();
  bool _isLoading = false;

  Future<void> _startRenewal() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.createRenewal(widget.site.id);
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Renewal application created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ComplianceDashboard(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('License Renewal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.refresh,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Renew License for ${widget.site.siteName}',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current License Information',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('License Number: ${widget.site.licenseNumber}'),
                  Text(
                      'Expiry Date: ${_formatDate(widget.site.licenseExpiryDate)}'),
                  Text('Days Remaining: ${widget.site.daysUntilExpiry}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Renewal Process',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildStep(
              1,
              'Review Compliance',
              'Ensure all compliance documents are up to date',
            ),
            _buildStep(
              2,
              'Submit Renewal Application',
              'Complete the renewal application form',
            ),
            _buildStep(
              3,
              'Pay Renewal Fee',
              'Pay the applicable renewal fee',
            ),
            _buildStep(
              4,
              'Wait for Approval',
              'DMRE will review and approve your renewal',
            ),
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: _startRenewal,
              isLoading: _isLoading,
              text: 'Start Renewal Process',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
