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
import 'application/new_application_step2.dart';
import 'application/new_application_step3.dart';
import 'application/new_application_step4.dart';
import 'application/new_application_step5.dart';
import 'application/new_application_step6.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;

  const ApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  final _apiClient = ApiClient();

  Application? _application;
  List<Document> _documents = [];
  List<dynamic> _documentRequests = [];
  bool _isLoading = true;

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

      if (_application?.status == 'info_requested') {
        final requests =
            await _apiClient.getDocumentRequests(widget.applicationId);

        setState(() {
          _documentRequests = requests;
        });
      } else {
        setState(() {
          _documentRequests = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load application: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _getCurrentStep() {
    if (_application == null) return 2;

    if (_application!.companyDetails == null) return 2;
    if (_application!.siteDetails == null) return 3;
    if (_documents.isEmpty) return 4;

    return 6;
  }

  void _editApplication() {
    if (_application == null) return;

    final currentStep = _getCurrentStep();

    switch (currentStep) {
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewApplicationStep2(
              applicationId: _application!.id,
              licenseType: _application!.licenseType,
            ),
          ),
        ).then((_) => _loadData());
        break;

      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewApplicationStep3(
              applicationId: _application!.id,
              licenseType: _application!.licenseType,
            ),
          ),
        ).then((_) => _loadData());
        break;

      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewApplicationStep4(
              applicationId: _application!.id,
              licenseType: _application!.licenseType,
            ),
          ),
        ).then((_) => _loadData());
        break;

      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewApplicationStep5(
              applicationId: _application!.id,
              licenseType: _application!.licenseType,
            ),
          ),
        ).then((_) => _loadData());
        break;

      case 6:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewApplicationStep6(
              applicationId: _application!.id,
              licenseType: _application!.licenseType,
            ),
          ),
        ).then((_) => _loadData());
        break;

      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewApplicationStep2(
              applicationId: _application!.id,
              licenseType: _application!.licenseType,
            ),
          ),
        ).then((_) => _loadData());
    }
  }

  Future<void> _deleteApplication() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text(
          'Are you sure you want to delete this application? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        for (final doc in _documents) {
          await _apiClient.deleteDocument(doc.id);
        }

        await _apiClient.deleteApplication(widget.applicationId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
                if (_application?.licenseNumber != null &&
                    (_application?.licenseNumber?.isNotEmpty ?? false))
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
          StatusBadge(
            status: _application?.status ?? 'draft',
            isSmall: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard() {
    return Card(
      color: AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cancel,
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Rejected',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _application?.rejectedReason ?? 'No reason provided',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRequestsCard() {
    return Card(
      color: AppColors.warning.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  'Additional Documents Required',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._documentRequests.map(
              (req) => Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  bottom: 4,
                ),
                child: Text(
                  '• ${req['document_type']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deadline: ${_documentRequests.first?['deadline']?.toString().split('T')[0] ?? 'N/A'}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.warning,
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
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.primary,
                ),
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
                  'Documents',
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

  Widget _buildTimelineCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.timeline,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Timeline',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildTimelineItem(
              'Application Created',
              _application?.createdAt,
              true,
            ),
            if (_application?.submittedAt != null)
              _buildTimelineItem(
                'Application Submitted',
                _application?.submittedAt,
                true,
              ),
            if (_application?.reviewedAt != null)
              _buildTimelineItem(
                'Application Reviewed',
                _application?.reviewedAt,
                _application?.isApproved ?? false,
              ),
            if (_application?.isApproved == true)
              _buildTimelineItem(
                'Application Approved',
                _application?.reviewedAt,
                true,
              ),
            if (_application?.status == 'rejected')
              _buildTimelineItem(
                'Application Rejected',
                _application?.reviewedAt,
                true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    DateTime? date,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.success
                  : AppColors.textHint.withOpacity(0.3),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.access_time,
              size: 14,
              color: isCompleted ? Colors.white : AppColors.textHint,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (date != null)
                  Text(
                    _formatDate(date),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildCompanyDetails() {
    final details = _application?.companyDetails;
    if (details == null) return 'Not completed yet';

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
    if (details == null) return 'Not completed yet';

    return '''
Site: ${details['site_name'] ?? 'N/A'}
Address: ${details['physical_address'] ?? 'N/A'}
Coordinates: ${details['gps_coordinates'] ?? 'N/A'}
Capacity: ${details['storage_capacity'] ?? 'N/A'} liters
''';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        actions: [
          if (_application != null && _application!.isDraft)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editApplication,
              tooltip: 'Edit Draft',
            ),
          if (_application != null && _application!.isDraft)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
              ),
              onPressed: _deleteApplication,
              tooltip: 'Delete Draft',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  if (_application?.status == 'rejected' &&
                      _application?.rejectedReason != null)
                    _buildRejectionCard(),
                  if (_documentRequests.isNotEmpty)
                    _buildDocumentRequestsCard(),
                  _buildInfoCard(
                    'License Type',
                    _application?.licenseType.toUpperCase() ?? 'N/A',
                    Icons.local_gas_station,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Company Details',
                    _buildCompanyDetails(),
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
                  if (_application != null && _application!.isDraft)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewApplicationStep6(
                                applicationId: _application!.id,
                                licenseType: _application!.licenseType,
                              ),
                            ),
                          );

                          if (result == true) {
                            _loadData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Continue Application'),
                      ),
                    ),
                  _buildTimelineCard(),
                ],
              ),
            ),
    );
  }
}
