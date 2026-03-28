import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
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
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveApplication() async {
    if (_notesController.text.isEmpty) {
      _showError('Please add review notes');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final response = await _apiClient.approveApplication(
        widget.applicationId,
        _notesController.text,
      );
      if (response['success'] == true) {
        _showSuccess('Application approved successfully');
        Navigator.pop(context, true);
      } else {
        _showError(response['error'] ?? 'Approval failed');
      }
    } catch (e) {
      _showError('Connection error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectApplication() async {
    if (_reasonController.text.isEmpty) {
      _showError('Please provide rejection reason');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final response = await _apiClient.rejectApplication(
        widget.applicationId,
        _reasonController.text,
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _requestInfo() async {
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Additional Information'),
        content: TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Please specify what information is needed...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _reasonController.text),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (message != null && message.isNotEmpty) {
      setState(() => _isProcessing = true);
      try {
        final response = await _apiClient.requestInfo(
          widget.applicationId,
          message,
        );
        if (response['success'] == true) {
          _showSuccess('Information request sent');
          Navigator.pop(context, true);
        } else {
          _showError(response['error'] ?? 'Request failed');
        }
      } catch (e) {
        _showError('Connection error');
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
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
        title: const Text('Review Application'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Application Status',
                              style: GoogleFonts.inter(color: Colors.white70),
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
                          ],
                        ),
                        StatusBadge(status: _application?.status ?? 'draft'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Applicant Info
                  _buildInfoCard(
                    'Applicant Information',
                    '''
Company: ${_application?.companyDetails?['company_name'] ?? 'N/A'}
Registration: ${_application?.companyDetails?['registration_number'] ?? 'N/A'}
B-BBEE: ${_application?.companyDetails?['bee_status'] ?? 'N/A'}
''',
                    Icons.business,
                  ),
                  const SizedBox(height: 12),

                  // Site Details
                  _buildInfoCard(
                    'Site Details',
                    '''
Site Name: ${_application?.siteDetails?['site_name'] ?? 'N/A'}
Address: ${_application?.siteDetails?['physical_address'] ?? 'N/A'}
Coordinates: ${_application?.siteDetails?['gps_coordinates'] ?? 'N/A'}
Capacity: ${_application?.siteDetails?['storage_capacity'] ?? 'N/A'} liters
''',
                    Icons.location_on,
                  ),
                  const SizedBox(height: 12),

                  // Documents
                  if (_documents.isNotEmpty) _buildDocumentsCard(),
                  const SizedBox(height: 12),

                  // Review Notes
                  Card(
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
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
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
                          onPressed: _rejectApplication,
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
                      onPressed: _requestInfo,
                      child: const Text('Request More Information'),
                    ),
                  ),
                ],
              ),
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
                const Icon(Icons.attach_file, size: 20, color: AppColors.primary),
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
            ..._documents.map((doc) => ListTile(
                  leading:
                      const Icon(Icons.insert_drive_file, color: AppColors.primary),
                  title: Text(doc.fileName),
                  subtitle: Text(doc.documentTypeDisplay),
                  dense: true,
                )),
          ],
        ),
      ),
    );
  }
}
