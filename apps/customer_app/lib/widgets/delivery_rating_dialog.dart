import 'package:flutter/material.dart';
import '../../core/theme.dart';

class DeliveryRatingDialog extends StatefulWidget {
  final String shipmentId;
  final String? driverName;
  final Function(int rating, String? comment) onSubmit;

  const DeliveryRatingDialog({
    super.key,
    required this.shipmentId,
    this.driverName,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String shipmentId,
    String? driverName,
    required Function(int rating, String? comment) onSubmit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeliveryRatingDialog(
        shipmentId: shipmentId,
        driverName: driverName,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<DeliveryRatingDialog> createState() => _DeliveryRatingDialogState();
}

class _DeliveryRatingDialogState extends State<DeliveryRatingDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _submitted = false;

  final _ratingLabels = const [
    '',
    'سيء جداً',
    'سيء',
    'مقبول',
    'جيد جداً',
    'ممتاز',
  ];

  final _ratingEmojis = const ['', '😡', '😟', '😐', '😊', '🤩'];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) return;
    setState(() => _submitted = true);
    widget.onSubmit(_rating, _commentController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.accentGreen,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تم التسليم بنجاح!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            if (widget.driverName != null) ...[
              const SizedBox(height: 4),
              Text(
                'كيف كانت تجربتك مع ${widget.driverName}؟',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: _rating == starIndex
                          ? (Matrix4.identity()..scale(1.2))
                          : Matrix4.identity(),
                      child: Icon(
                        _rating >= starIndex ? Icons.star : Icons.star_border,
                        size: 40,
                        color: _rating >= starIndex
                            ? AppTheme.warningAmber
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Text(
                _ratingLabels[_rating],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _rating >= 4
                      ? AppTheme.accentGreen
                      : _rating >= 3
                          ? AppTheme.warningAmber
                          : AppTheme.errorRed,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              textDirection: TextDirection.rtl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'أضف تعليقاً (اختياري)',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('لاحقاً'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _rating == 0 ? null : _submit,
                    child: _submitted
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('إرسال'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
