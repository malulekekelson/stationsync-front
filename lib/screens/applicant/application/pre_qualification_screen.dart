import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/loading_button.dart';
import 'new_application_step2.dart';

class PreQualificationScreen extends StatefulWidget {
  final String applicationId;
  final String licenseType;

  const PreQualificationScreen({
    super.key,
    required this.applicationId,
    required this.licenseType,
  });

  @override
  State<PreQualificationScreen> createState() => _PreQualificationScreenState();
}

class _PreQualificationScreenState extends State<PreQualificationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Company Details
  final _companyRegController = TextEditingController();
  final _beeController = TextEditingController();
  final _vatController = TextEditingController();

  // Site Location
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _zoningController = TextEditingController();

  // Approvals
  bool _hasEnvironmentalApproval = false;
  bool _hasMunicipalApproval = false;
  bool _hasLandUsePermission = false;

  bool _isLoading = false;

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();

      final preQualData = {
        'company_registration': _companyRegController.text.trim(),
        'bee_status': _beeController.text.trim(),
        'vat_registered': _vatController.text.trim().isEmpty
            ? null
            : _vatController.text.trim(),
        'gps_coordinates':
            '${_latitudeController.text},${_longitudeController.text}',
        'zoning_compliance': _zoningController.text,
        'environmental_approval': _hasEnvironmentalApproval,
        'municipal_approval': _hasMunicipalApproval,
        'land_use_permission': _hasLandUsePermission,
      };

      await apiClient.preQualify(widget.applicationId, preQualData);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewApplicationStep2(
              applicationId: widget.applicationId,
              licenseType: widget.licenseType,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Qualification'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 2 of 7',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pre-Qualification Checklist',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verify your eligibility before proceeding',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Company Registration Section
              _buildSection('Company Registration', [
                TextFormField(
                  controller: _companyRegController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _beeController,
                  decoration: const InputDecoration(
                    labelText: 'B-BBEE Status',
                    prefixIcon: Icon(Icons.star),
                    hintText: 'e.g., Level 1, Level 2, Non-Compliant',
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vatController,
                  decoration: const InputDecoration(
                    labelText: 'VAT Registration Number (Optional)',
                    prefixIcon: Icon(Icons.receipt),
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // Site Location Section
              _buildSection('Site Location', [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          prefixIcon: Icon(Icons.map),
                        ),
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _zoningController,
                  decoration: const InputDecoration(
                    labelText: 'Zoning Compliance',
                    prefixIcon: Icon(Icons.location_city),
                    hintText: 'e.g., Commercial, Industrial',
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
              ]),

              const SizedBox(height: 24),

              // Approvals Section
              _buildSection('Required Approvals', [
                CheckboxListTile(
                  value: _hasEnvironmentalApproval,
                  onChanged: (value) {
                    setState(() => _hasEnvironmentalApproval = value ?? false);
                  },
                  title: const Text('Environmental Approval'),
                  subtitle:
                      const Text('Approval from environmental authorities'),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),
                CheckboxListTile(
                  value: _hasMunicipalApproval,
                  onChanged: (value) {
                    setState(() => _hasMunicipalApproval = value ?? false);
                  },
                  title: const Text('Municipal Approval'),
                  subtitle: const Text('Approval from local municipality'),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),
                CheckboxListTile(
                  value: _hasLandUsePermission,
                  onChanged: (value) {
                    setState(() => _hasLandUsePermission = value ?? false);
                  },
                  title: const Text('Land Use Permission'),
                  subtitle: const Text('Permission for fuel retail use'),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),
              ]),

              const SizedBox(height: 32),
              LoadingButton(
                onPressed: _saveAndContinue,
                isLoading: _isLoading,
                text: 'Continue',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
