import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/document.dart';
import '../../../widgets/common/loading_button.dart';
import 'new_application_step5.dart';

class NewApplicationStep4 extends StatefulWidget {
  final String applicationId;
  final String licenseType;

  const NewApplicationStep4({
    super.key,
    required this.applicationId,
    required this.licenseType,
  });

  @override
  State<NewApplicationStep4> createState() => _NewApplicationStep4State();
}

class _NewApplicationStep4State extends State<NewApplicationStep4> {
  final _apiClient = ApiClient();
  List<Document> _documents = [];
  bool _isLoading = true;
  bool _isUploading = false;

  final List<String> _requiredDocuments = [
    'registration_cert',
    'bee_cert',
    'env_approval',
    'municipal_approval',
    'land_use',
    'id_copy',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.getApplication(widget.applicationId);
      final docs = response['documents'] as List? ?? [];
      setState(() {
        _documents = docs.map((json) => Document.fromJson(json)).toList();
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocument(String documentType) async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final file = await picker.pickImage(source: ImageSource.camera);
                if (file != null) await _uploadFile(file.path, documentType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file =
                    await picker.pickImage(source: ImageSource.gallery);
                if (file != null) await _uploadFile(file.path, documentType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Select PDF/Document'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: false,
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                );
                if (result != null) {
                  await _uploadFile(result.files.single.path!, documentType);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile(String filePath, String documentType) async {
    setState(() => _isUploading = true);

    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      final fileBytes = await file.readAsBytes();
      final mimeType =
          fileName.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg';

      // Get upload URL
      final uploadData = await _apiClient.getUploadUrl({
        'application_id': widget.applicationId,
        'document_type': documentType,
        'file_name': fileName,
        'file_size': fileBytes.length,
        'mime_type': mimeType,
      });

      if (uploadData['success'] == true) {
        final uploadKey = uploadData['upload_key'];

        // Upload file
        await _apiClient.uploadDocument(uploadKey, fileBytes, mimeType);

        // Refresh documents list
        await _loadDocuments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiClient.deleteDocument(documentId);
        await _loadDocuments();
      } catch (e) {
        // Handle error
      }
    }
  }

  bool get _allRequiredUploaded {
    final uploadedTypes = _documents
        .where((d) => d.isUploaded)
        .map((d) => d.documentType)
        .toSet();
    return _requiredDocuments.every((type) => uploadedTypes.contains(type));
  }

  Future<void> _nextStep() async {
    if (!_allRequiredUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all required documents'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewApplicationStep5(
            applicationId: widget.applicationId,
            licenseType: widget.licenseType,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Documents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(4),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step 4 of 7',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Compliance Documents',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload the required compliance documents',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ..._requiredDocuments
                            .map((type) => _buildDocumentCard(type)),
                        const SizedBox(height: 32),
                        LoadingButton(
                          onPressed: _nextStep,
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

  Widget _buildDocumentCard(String documentType) {
    final doc = _documents.firstWhere(
      (d) => d.documentType == documentType && d.isUploaded,
      orElse: () => Document(
        id: '',
        applicationId: widget.applicationId,
        documentType: documentType,
        fileName: '',
        uploadStatus: 'missing',
        uploadedAt: DateTime.now(),
      ),
    );

    final isUploaded = doc.isUploaded;
    final displayName =
        AppConstants.documentTypes[documentType] ?? documentType;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUploaded
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isUploaded ? Icons.check_circle : Icons.upload_file,
                color: isUploaded ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isUploaded)
                    Text(
                      doc.fileName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            if (!isUploaded)
              TextButton.icon(
                onPressed:
                    _isUploading ? null : () => _uploadDocument(documentType),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Upload'),
              )
            else
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _deleteDocument(doc.id),
              ),
          ],
        ),
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
