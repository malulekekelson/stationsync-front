import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/application.dart';
import '../../../widgets/common/loading_button.dart';
import 'new_application_step7.dart';

class NewApplicationStep6 extends StatefulWidget {
  final String applicationId;
  final String licenseType;

  const NewApplicationStep6({
    super.key,
    required this.applicationId,
    required this.licenseType,
  });

  @override
  State<NewApplicationStep6> createState() => _NewApplicationStep6State();
}

class _NewApplicationStep6State extends State<NewApplicationStep6> {
  final _apiClient = ApiClient();
  Application? _application;
  bool _isLoading = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.getApplication(widget.applicationId);
      setState(() {
        _application = Application.fromJson(response['application']);
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FIXED: Better handling of risk readiness response
  Future<void> _checkRiskReadiness() async {
    setState(() => _isChecking = true);

    try {
      final riskData = await _apiClient.getRiskReadiness(widget.applicationId);

      print('Risk Readiness Response: $riskData');

      // Check if the response indicates readiness
      if (riskData['is_ready'] == true ||
          (riskData['overall_score'] != null &&
              riskData['overall_score'] <= 20)) {
        // Proceed to submit screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewApplicationStep7(
                applicationId: widget.applicationId,
                licenseType: widget.licenseType,
              ),
            ),
          );
        }
      } else {
        // Show detailed warning with all missing items
        _showRiskWarning(riskData);
      }
    } catch (e) {
      print('Risk Readiness Error: $e');
      String errorMessage = 'Failed to check readiness. ';

      if (e.toString().contains('director')) {
        errorMessage = 'Please add at least one director in Company Details';
      } else if (e.toString().contains('document')) {
        errorMessage = 'Please upload all required documents';
      } else if (e.toString().contains('approval')) {
        errorMessage = 'Please complete all approvals in Pre-Qualification';
      } else {
        errorMessage =
            'Please complete all required fields before submitting. Make sure you have:\n\n• At least 1 director\n• All company details\n• All site details\n• All required documents';
      }

      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showRiskWarning(Map<String, dynamic> riskData) {
    final missingFields = riskData['missing_fields'] as List? ?? [];
    final missingDocs = riskData['missing_documents'] as List? ?? [];
    final missingApprovals = riskData['missing_approvals'] as List? ?? [];
    final score = riskData['overall_score'] ?? 0;
    final message =
        riskData['message'] ?? 'Please complete all required information';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Application Not Ready'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: score > 50
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Readiness Score: $score%',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: score > 50 ? AppColors.error : AppColors.warning,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      score > 50 ? 'High Risk' : 'Medium Risk',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: score > 50 ? AppColors.error : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Missing Fields
              if (missingFields.isNotEmpty) ...[
                Text(
                  '⚠️ Missing Required Fields:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                ...missingFields.map((field) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 14, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(field,
                                  style: GoogleFonts.inter(fontSize: 12))),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],

              // Missing Documents
              if (missingDocs.isNotEmpty) ...[
                Text(
                  '📄 Missing Required Documents:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 8),
                ...missingDocs.map((doc) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(doc,
                                  style: GoogleFonts.inter(fontSize: 12))),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],

              // Missing Approvals
              if (missingApprovals.isNotEmpty) ...[
                Text(
                  '✅ Missing Approvals:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 8),
                ...missingApprovals.map((approval) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(approval,
                                  style: GoogleFonts.inter(fontSize: 12))),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back & Fix'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Proceed anyway
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewApplicationStep7(
                    applicationId: widget.applicationId,
                    licenseType: widget.licenseType,
                  ),
                ),
              );
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(6),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step 6 of 7',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Review Your Application',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please review all information before submitting',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          'License Type',
                          widget.licenseType.toUpperCase(),
                          Icons.local_gas_station,
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          'Company Details',
                          _buildCompanyDetails(),
                          Icons.business,
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          'Site Details',
                          _buildSiteDetails(),
                          Icons.location_on,
                        ),
                        const SizedBox(height: 32),
                        LoadingButton(
                          onPressed: _checkRiskReadiness,
                          isLoading: _isChecking,
                          text: 'Check Readiness & Submit',
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back to Edit'),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildCompanyDetails() {
    final details = _application?.companyDetails;
    if (details == null) return 'No data';
    final directors = details['directors'] as List? ?? [];
    return '''
Company: ${details['company_name'] ?? 'N/A'}
Registration: ${details['registration_number'] ?? 'N/A'}
B-BBEE: ${details['bee_status'] ?? 'N/A'}
Directors: ${directors.length}
''';
  }

  String _buildSiteDetails() {
    final details = _application?.siteDetails;
    if (details == null) return 'No data';
    return '''
Site: ${details['site_name'] ?? 'N/A'}
Address: ${details['physical_address'] ?? 'N/A'}
Coordinates: ${details['gps_coordinates'] ?? 'N/A'}
Capacity: ${details['storage_capacity'] ?? 'N/A'} liters
''';
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Row(
        children: List.generate(7, (index) {
          final step = index + 1;
          final isActive = step == currentStep;
          final isCompleted = step < currentStep;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.success
                        : (isActive ? AppColors.primary : Colors.white),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.success
                          : (isActive ? AppColors.primary : AppColors.textHint),
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text(
                            step.toString(),
                            style: TextStyle(
                              color:
                                  isActive ? Colors.white : AppColors.textHint,
                            ),
                          ),
                  ),
                ),
                if (step < 7)
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: step < currentStep
                        ? AppColors.success
                        : AppColors.textHint.withOpacity(0.3),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
