import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/loading_button.dart';
import 'new_application_step6.dart';

class NewApplicationStep5 extends StatelessWidget {
  final String applicationId;
  final String licenseType;

  const NewApplicationStep5({
    super.key,
    required this.applicationId,
    required this.licenseType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supporting Documents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(5),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 5 of 7',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supporting Documents',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload any additional supporting documents (Optional)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.textHint.withOpacity(0.3),
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_upload,
                            size: 48, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text(
                          'Drag & drop files here or click to browse',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Handle file upload
                          },
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload Documents'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  LoadingButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewApplicationStep6(
                            applicationId: applicationId,
                            licenseType: licenseType,
                          ),
                        ),
                      );
                    },
                    isLoading: false,
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
