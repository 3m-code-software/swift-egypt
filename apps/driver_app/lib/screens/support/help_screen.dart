import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المساعدة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'دليل الاستخدام',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          _HelpTutorialCard(
            icon: Icons.assignment_rounded,
            title: 'عرض وبدء المهام',
            steps: [
              'من الشاشة الرئيسية اضغط "عرض المهام" أو انتقل لتبويب "المهام"',
              'اختر المهمة التي تريد تنفيذها',
              'اضغط "بدء التوصيل" لبدء العملية',
            ],
          ),
          _HelpTutorialCard(
            icon: Icons.gps_fixed_rounded,
            title: 'التنقل إلى العنوان',
            steps: [
              'بعد بدء المهمة، اضغط "التنقل" لفتح الخريطة',
              'اتبع المسار المحدد للوصول إلى نقطة الاستلام',
              'بعد الاستلام، انتقل إلى عنوان التسليم',
            ],
          ),
          _HelpTutorialCard(
            icon: Icons.update_rounded,
            title: 'تحديث حالة التوصيل',
            steps: [
              'بعد الوصول إلى العميل، اختر حالة التوصيل المناسبة',
              'تم التسليم: تم استلام الطرد بالكامل',
              'توصيل جزئي: تم استلام جزء من الطرد',
              'مرتجع: لم يتم التسليم (أدخل السبب)',
              'لا رد: العميل غير متاح (أدخل ملاحظات)',
            ],
          ),
          _HelpTutorialCard(
            icon: Icons.receipt_rounded,
            title: 'تسجيل المبالغ المحصلة',
            steps: [
              'أثناء التوصيل، يمكنك تسجيل المبلغ المحصل من العميل',
              'أدخل المبلغ في حقل "المبلغ المحصل"',
              'سيتم تسجيله في حسابك اليومي',
            ],
          ),
          _HelpTutorialCard(
            icon: Icons.today_rounded,
            title: 'إنهاء اليوم',
            steps: [
              'بعد الانتهاء من جميع المهام، اضغط "إنهاء اليوم"',
              'سيتم تحويل الطلبات المتبقية إلى مرتجعة تلقائياً',
              'راجع ملخص يومك من شاشة الملف الشخصي',
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'الأسئلة الشائعة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          _FaqExpansionTile(
            question: 'ماذا أفعل إذا لم أتمكن من الوصول إلى العنوان؟',
            answer: 'حدّث حالة الطلب إلى "لا رد" مع إضافة ملاحظات. يمكنك المحاولة لاحقاً أو تسجيل مرتجع.',
          ),
          _FaqExpansionTile(
            question: 'كيف أتتبع مساري اليومي؟',
            answer: 'من تبويب "النشاط" يمكنك رؤية جميع الإجراءات التي قمت بها اليوم مع التوقيت والموقع.',
          ),
          _FaqExpansionTile(
            question: 'ماذا أفعل عند استلام مبلغ نقدي؟',
            answer: 'أدخل المبلغ المحصل في حقل "المبلغ المحصل" أثناء تحديث الحالة. سيتم تسجيله في حسابك.',
          ),
          _FaqExpansionTile(
            question: 'هل يمكنني تعديل حالة بعد التحديث؟',
            answer: 'لا، بعد تحديث الحالة لا يمكن التراجع عنها. تأكد من اختيار الحالة الصحيحة قبل التأكيد.',
          ),
          _FaqExpansionTile(
            question: 'كيف أتواصل مع المشرف؟',
            answer: 'يمكنك التواصل مع فريق الدعم من خلال قسم "الدعم الفني" في الملف الشخصي أو الاتصال بالخط الساخن.',
          ),
          const SizedBox(height: 24),
          const Text(
            'تواصل معنا',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          _ContactCard(
            icon: Icons.phone_outlined,
            title: 'الخط الساخن',
            subtitle: '19000',
            onTap: () => launchUrl(Uri.parse('tel:19000')),
          ),
          _ContactCard(
            icon: Icons.email_outlined,
            title: 'البريد الإلكتروني',
            subtitle: 'drivers@swiftegypt.com',
            onTap: () => launchUrl(Uri.parse('mailto:drivers@swiftegypt.com')),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _HelpTutorialCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<String> steps;

  const _HelpTutorialCard({
    required this.icon,
    required this.title,
    required this.steps,
  });

  @override
  State<_HelpTutorialCard> createState() => _HelpTutorialCardState();
}

class _HelpTutorialCardState extends State<_HelpTutorialCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: AppTheme.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ...widget.steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqExpansionTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqExpansionTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        iconColor: AppTheme.primaryBlue,
        collapsedIconColor: const Color(0xFF94A3B8),
        children: [
          Text(answer, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.6)),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        trailing: const Icon(Icons.chevron_left, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}
