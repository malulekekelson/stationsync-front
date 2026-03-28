class Document {
  final String id;
  final String applicationId;
  final String documentType;
  final String fileName;
  final int? fileSize;
  final String? mimeType;
  final String uploadStatus;
  final DateTime uploadedAt;

  Document({
    required this.id,
    required this.applicationId,
    required this.documentType,
    required this.fileName,
    this.fileSize,
    this.mimeType,
    required this.uploadStatus,
    required this.uploadedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      applicationId: json['application_id'],
      documentType: json['document_type'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      mimeType: json['mime_type'],
      uploadStatus: json['upload_status'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  bool get isUploaded => uploadStatus == 'uploaded';
  bool get isPending => uploadStatus == 'pending';

  String get documentTypeDisplay {
    switch (documentType) {
      case 'registration_cert':
        return 'Registration Certificate';
      case 'bee_cert':
        return 'B-BBEE Certificate';
      case 'env_approval':
        return 'Environmental Approval';
      case 'municipal_approval':
        return 'Municipal Approval';
      case 'land_use':
        return 'Land Use Permission';
      case 'id_copy':
        return 'ID Copy';
      case 'site_plan':
        return 'Site Plan';
      default:
        return documentType;
    }
  }
}
