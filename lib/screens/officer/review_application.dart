import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../models/application.dart';
import '../../models/document.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/loading_button.dart';

class ReviewApplicationScreen extends StatefulWidget {
  final String applicationId;

  const ReviewApplicationScreen({super.key, required this.applicationId});

  @override
  State<ReviewApplicationScreen> createState() =>
      _ReviewApplicationScreenState();
}

class _ReviewApplicationScreenState extends State<ReviewApplicationScreen> {
  final _apiClient = ApiClient();

  Application? _application;
  List<Document> _documents = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  final _licenseController = TextEditingController();

  final bool _showLicenseField = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _reasonController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.getApplication(widget.applicationId);

      setState(() {
        _application = Application.fromJson(response['application']);
        _documents = (response['documents'] as List)
            .map((json) => Document.fromJson(json))
            .toList();
      });
    } catch (e) {
      _showError('Failed to load application');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadDocument(Document doc) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading...'),
        ),
      );

      final fileData = await _apiClient.downloadDocument(doc.id);
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/${doc.fileName}';
      final file = File(filePath);

      await file.writeAsBytes(fileData);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Download ${doc.fileName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download ready!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('Download failed: ${e.toString()}');
    }
  }

  Future<void> _approveApplication() async {
    if (_notesController.text.trim().isEmpty) {
      _showError('Please add review notes');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await _apiClient.approveApplication(
        widget.applicationId,
        _notesController.text.trim(),
      );

      if (response['success'] == true) {
        if (mounted) {
          _showLicenseDialog();
        }
      } else {
        _showError(response['error'] ?? 'Approval failed');
      }
    } catch (e) {
      _showError('Connection error');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _issueLicense() async {
    if (_licenseController.text.trim().isEmpty) {
      _showError('Please enter license number');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _apiClient.issueLicense(
        widget.applicationId,
        _licenseController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccess('License issued successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Failed to issue license');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showLicenseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Issue License Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the license number for this application:'),
            const SizedBox(height: 16),
            TextField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'License Number',
                border: OutlineInputBorder(),
                hintText: 'e.g., LIC-2024-001',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed:
                _isProcessing ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          SizedBox(
            width: 140,
            child: LoadingButton(
              onPressed: _issueLicense,
              isLoading: _isProcessing,
              text: 'Issue License',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectDialog() async {
    _reasonController.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: _reasonController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Please provide rejection reason...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _rejectApplication();
    }
  }

  Future<void> _rejectApplication() async {
    if (_reasonController.text.trim().isEmpty) {
      _showError('Please provide rejection reason');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await _apiClient.rejectApplication(
        widget.applicationId,
        _reasonController.text.trim(),
      );

      if (response['success'] == true) {
        _showSuccess('Application rejected');
        Navigator.pop(context, true);
      } else {
        _showError(response['error'] ?? 'Rejection failed');
      }
    } catch (e) {
      _showError('Connection error');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _requestDocuments() async {
    final documentTypes = await showDialog<List<String>>(
      context: context,
      builder: (context) => const _DocumentTypeDialog(),
    );

    if (documentTypes != null && documentTypes.isNotEmpty) {
      setState(() => _isProcessing = true);

      try {
        await _apiClient.requestDocuments(
          widget.applicationId,
          'Please upload the following documents for review:',
          documentTypes,
        );

        if (mounted) {
          _showSuccess('Document request sent');
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError('Failed to send request');
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
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

  String _buildApplicantInfo() {
    final details = _application?.companyDetails;
    if (details == null) return 'No data';

    return 'Company: ${details['company_name'] ?? 'N/A'}\n'
        'Registration: ${details['registration_number'] ?? 'N/A'}\n'
        'B-BBEE: ${details['bee_status'] ?? 'N/A'}\n'
        'Directors: ${(details['directors'] as List?)?.length ?? 0}';
  }

  String _buildSiteDetails() {
    final details = _application?.siteDetails;
    if (details == null) return 'No data';

    return 'Site: ${details['site_name'] ?? 'N/A'}\n'
        'Address: ${details['physical_address'] ?? 'N/A'}\n'
        'Coordinates: ${details['gps_coordinates'] ?? 'N/A'}\n'
        'Capacity: ${details['storage_capacity'] ?? 'N/A'} liters';
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Status',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _application?.statusDisplay ?? 'Unknown',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((_application?.licenseNumber ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'License: ${_application?.licenseNumber}',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          StatusBadge(status: _application?.status ?? 'draft'),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
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

  Widget _buildDocumentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Uploaded Documents',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            ..._documents.map(
              (doc) => ListTile(
                leading: const Icon(
                  Icons.insert_drive_file,
                  color: AppColors.primary,
                ),
                title: Text(doc.fileName),
                subtitle: Text(doc.documentTypeDisplay),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadDocument(doc),
                ),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Notes',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your review notes here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseFieldCard() {
    if (!_showLicenseField) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'License Number',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _licenseController,
              decoration: const InputDecoration(
                hintText: 'Enter license number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Application'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    'Applicant Information',
                    _buildApplicantInfo(),
                    Icons.business,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Site Details',
                    _buildSiteDetails(),
                    Icons.location_on,
                  ),
                  const SizedBox(height: 12),
                  if (_documents.isNotEmpty) _buildDocumentsCard(),
                  const SizedBox(height: 12),
                  _buildReviewNotesCard(),
                  const SizedBox(height: 12),
                  _buildLicenseFieldCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: LoadingButton(
                          onPressed: _approveApplication,
                          isLoading: _isProcessing,
                          text: 'Approve',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : _showRejectDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : _requestDocuments,
                      child: const Text('Request Documents'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DocumentTypeDialog extends StatefulWidget {
  const _DocumentTypeDialog();

  @override
  State<_DocumentTypeDialog> createState() => _DocumentTypeDialogState();
}

class _DocumentTypeDialogState extends State<_DocumentTypeDialog> {
  final List<String> _selectedTypes = [];

  final List<Map<String, String>> _documentTypes = [
    {
      'value': 'registration_cert',
      'label': 'Company Registration Certificate',
    },
    {
      'value': 'bee_cert',
      'label': 'B-BBEE Certificate',
    },
    {
      'value': 'env_approval',
      'label': 'Environmental Approval',
    },
    {
      'value': 'municipal_approval',
      'label': 'Municipal Approval',
    },
    {
      'value': 'land_use',
      'label': 'Land Use Permission',
    },
    {
      'value': 'site_plan',
      'label': 'Site Plan',
    },
    {
      'value': 'id_copy',
      'label': 'ID Copy',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Documents'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _documentTypes
                .map(
                  (type) => CheckboxListTile(
                    title: Text(type['label']!),
                    value: _selectedTypes.contains(type['value']),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedTypes.add(type['value']!);
                        } else {
                          _selectedTypes.remove(type['value']);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedTypes),
          child: const Text('Send Request'),
        ),
      ],
    );
  }
}
