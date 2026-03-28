import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/common/loading_button.dart';
import 'new_application_step2.dart';

class NewApplicationStep1 extends StatefulWidget {
  const NewApplicationStep1({super.key});

  @override
  State<NewApplicationStep1> createState() => _NewApplicationStep1State();
}

class _NewApplicationStep1State extends State<NewApplicationStep1> {
  final _apiClient = ApiClient();
  String? _selectedLicenseType;
  bool _isLoading = false;

  Future<void> _nextStep() async {
    if (_selectedLicenseType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a license type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.createApplication({
        'license_type': _selectedLicenseType,
        'company_details': {},
        'site_details': {},
      });

      if (response['success'] == true) {
        final applicationId = response['application']['id'];
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewApplicationStep2(
                applicationId: applicationId,
                licenseType: _selectedLicenseType!,
              ),
            ),
          );
        }
      } else {
        _showError(response['error'] ?? 'Failed to create application');
      }
    } catch (e) {
      _showError('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: const Text('New Application'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.background,
            child: Row(
              children: [
                _buildStepCircle(1, true),
                _buildStepLine(),
                _buildStepCircle(2, false),
                _buildStepLine(),
                _buildStepCircle(3, false),
                _buildStepLine(),
                _buildStepCircle(4, false),
                _buildStepLine(),
                _buildStepCircle(5, false),
                _buildStepLine(),
                _buildStepCircle(6, false),
                _buildStepLine(),
                _buildStepCircle(7, false),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1 of 7',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select License Type',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose the type of petroleum license you want to apply for:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...AppConstants.licenseTypes
                      .map((type) => _buildLicenseCard(type)),
                  const SizedBox(height: 32),
                  LoadingButton(
                    onPressed: _nextStep,
                    isLoading: _isLoading,
                    text: 'Continue',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primary : Colors.white,
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.textHint,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textHint,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: AppColors.textHint.withOpacity(0.3),
      ),
    );
  }

  Widget _buildLicenseCard(String type) {
    final isSelected = _selectedLicenseType == type;
    final icon = {
          'retail': Icons.local_gas_station,
          'wholesale': Icons.business,
          'manufacturing': Icons.factory,
          'storage': Icons.warehouse,
        }[type] ??
        Icons.description;

    final title = {
          'retail': 'Retail License',
          'wholesale': 'Wholesale License',
          'manufacturing': 'Manufacturing License',
          'storage': 'Storage License',
        }[type] ??
        type;

    final description = {
          'retail': 'For operating fuel service stations',
          'wholesale': 'For bulk fuel distribution',
          'manufacturing': 'For petroleum product manufacturing',
          'storage': 'For fuel storage facilities',
        }[type] ??
        '';

    return GestureDetector(
      onTap: () => setState(() => _selectedLicenseType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textHint.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
