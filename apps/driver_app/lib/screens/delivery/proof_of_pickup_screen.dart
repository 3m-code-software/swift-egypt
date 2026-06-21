import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../providers/task_provider.dart';
import '../../widgets/signature_dialog.dart';

class ProofOfPickupScreen extends StatefulWidget {
  final String shipmentId;

  const ProofOfPickupScreen({super.key, required this.shipmentId});

  @override
  State<ProofOfPickupScreen> createState() => _ProofOfPickupScreenState();
}

class _ProofOfPickupScreenState extends State<ProofOfPickupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();
  final _itemCountController = TextEditingController(text: '1');

  String? _photoPath;
  String? _signaturePath;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    _notesController.dispose();
    _itemCountController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() => _photoPath = photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في التقاط الصورة')),
        );
      }
    }
  }

  Future<void> _captureSignature() async {
    final Uint8List? pngBytes = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const SignatureDialog(),
    );
    if (pngBytes != null && mounted) {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      setState(() => _signaturePath = file.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<TaskProvider>();
    final success = await provider.submitProofOfPickup(
      shipmentId: widget.shipmentId,
      itemCount: int.tryParse(_itemCountController.text) ?? 1,
      photoPath: _photoPath,
      signaturePath: _signaturePath,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _showSuccess = success;
      });

      if (success) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'حدث خطأ'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('إثبات الاستلام')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 100, color: AppTheme.accentGreen),
              const SizedBox(height: 24),
              const Text(
                'تم تأكيد الاستلام بنجاح!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إثبات الاستلام')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('صورة المواد',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            image: _photoPath != null
                                ? DecorationImage(
                                    image: FileImage(File(_photoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _photoPath == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_rounded,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('اضغط لالتقاط صورة',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('عدد المواد',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _itemCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'عدد المواد المستلمة',
                          prefixIcon: Icon(Icons.inventory_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'يرجى إدخال العدد';
                          final n = int.tryParse(v);
                          if (n == null || n <= 0) return 'يرجى إدخال عدد صحيح';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('توقيع المرسل',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _captureSignature,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _signaturePath == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.draw_rounded,
                                        size: 36, color: Colors.grey),
                                    SizedBox(height: 4),
                                    Text('اضغط للتوقيع',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                )
                              : const Icon(Icons.check_circle_rounded,
                                  size: 48, color: AppTheme.accentGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('تأكيد الاستلام'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
