import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter/services.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@malegatechnovation.co.za',
      query: 'subject=StationSync%20Support%20Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // Copy email to clipboard
      await Clipboard.setData(
          const ClipboardData(text: 'info@malegatechnovation.co.za'));
      ScaffoldMessenger.of(globalContext!).showSnackBar(
        const SnackBar(
          content: Text('Email address copied to clipboard'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  static BuildContext? globalContext;

  @override
  Widget build(BuildContext context) {
    globalContext = context;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            _buildFaqItem(
              'How do I apply for a license?',
              'Go to the Applications tab and tap the "+" button. Follow the 7-step application wizard to submit your license application.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'How long does the review take?',
              'Applications are typically reviewed within 14 business days. You can track the status in your dashboard.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'What documents are required?',
              'Required documents include: Company Registration Certificate, B-BBEE Certificate, Environmental Approval, Municipal Approval, Land Use Permission, and ID copies of directors.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'How do I schedule an inspection?',
              'Once your license is approved, go to the Compliance tab, select your site, and tap "Schedule Inspection".',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'How is risk score calculated?',
              'Risk scores are calculated based on inspection results, document compliance, and regulatory adherence.',
            ),

            const SizedBox(height: 32),

            // Contact Section
            Text(
              'Contact Us',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: InkWell(
                onTap: _sendEmail,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Icon(Icons.email, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Support',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'info@malegatechnovation.co.za',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.access_time,
                          color: AppColors.warning),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Response Time',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Typically within 24-48 hours',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Version Info
            Center(
              child: Text(
                'StationSync Version 1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
