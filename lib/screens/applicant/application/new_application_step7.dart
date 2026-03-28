import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/loading_button.dart';
import '../dashboard.dart';

class NewApplicationStep7 extends StatefulWidget {
  final String applicationId;
  final String licenseType;

  const NewApplicationStep7({
    super.key,
    required this.applicationId,
    required this.licenseType,
  });

  @override
  State<NewApplicationStep7> createState() => _NewApplicationStep7State();
}

class _NewApplicationStep7State extends State<NewApplicationStep7> {
  final _apiClient = ApiClient();
  bool _isSubmitting = false;
  bool _submitted = false;

  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);

    try {
      final response = await _apiClient.submitApplication(widget.applicationId);

      if (response['success'] == true) {
        setState(() => _submitted = true);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted successfully!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate back to dashboard after delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ApplicantDashboard()),
                (route) => false,
              );
            }
          });
        }
      } else {
        _showError(response['error'] ?? 'Submission failed');
      }
    } catch (e) {
      _showError('Connection error. Please try again.');
    } finally {
      if (mounted && !_submitted) {
        setState(() => _isSubmitting = false);
      }
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
        title: const Text('Submit Application'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(7),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _submitted
                  ? _buildSuccessView()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        const Icon(
                          Icons.send,
                          size: 80,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ready to Submit',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your application is complete and ready for review.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Once submitted, you will not be able to make changes.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: AppColors.warning),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Please ensure all information is correct before submitting.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        LoadingButton(
                          onPressed: _submitApplication,
                          isLoading: _isSubmitting,
                          text: 'Submit Application',
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back to Review'),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          size: 100,
          color: AppColors.success,
        ),
        const SizedBox(height: 24),
        Text(
          'Application Submitted!',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your application has been submitted successfully.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You can track its progress in your dashboard.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Redirecting to dashboard...',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),
      ],
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
