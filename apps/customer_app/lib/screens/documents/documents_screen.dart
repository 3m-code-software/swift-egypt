import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../../core/theme.dart';
import '../../providers/shipment_provider.dart';
import '../../widgets/empty_state.dart';

class DocumentsScreen extends StatefulWidget {
  final String? shipmentId;
  const DocumentsScreen({super.key, this.shipmentId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _picker = ImagePicker();

  Future<void> _uploadDocument(String docType) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && widget.shipmentId != null) {
      context.read<ShipmentProvider>().uploadDocument(
            widget.shipmentId!,
            picked.path,
            docType,
          );
    }
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('اختر نوع المستند', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const Divider(),
            ...DocumentType.values.map((type) => ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(type.displayName),
                  onTap: () {
                    Navigator.pop(ctx);
                    _uploadDocument(type.apiValue);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ShipmentProvider>();
    final docs = prov.documents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستندات'),
        actions: [
          if (widget.shipmentId != null)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _showUploadDialog,
            ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : docs.isEmpty
              ? const EmptyState(
                  icon: Icons.description_outlined,
                  title: 'لا توجد مستندات',
                  subtitle: 'قم برفع المستندات الخاصة بالشحنة',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.description, color: AppTheme.primaryBlue),
                        ),
                        title: Text(doc.fileName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.documentType.displayName, style: const TextStyle(fontSize: 12)),
                            if (doc.ocrData != null)
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: AppTheme.accentGreen),
                                  const SizedBox(width: 4),
                                  const Text('OCR تم', style: TextStyle(fontSize: 12, color: AppTheme.accentGreen)),
                                ],
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (doc.fileUrl.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.preview),
                                onPressed: () => _openFile(doc.fileUrl),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            if (doc.fileUrl.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () => _openFile(doc.fileUrl),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
