import '../enums/document_type.dart';

class Document {
  final String id;
  final String shipmentId;
  final DocumentType documentType;
  final String fileName;
  final String fileUrl;
  final double? fileSize;
  final String? ocrData;
  final String? uploadedBy;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.shipmentId,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.ocrData,
    this.uploadedBy,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      documentType: DocumentType.fromApi(json['document_type'] as String),
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileSize: (json['file_size'] as num?)?.toDouble(),
      ocrData: json['ocr_data'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'document_type': documentType.apiValue,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_size': fileSize,
      'ocr_data': ocrData,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
