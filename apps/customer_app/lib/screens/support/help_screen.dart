import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المساعدة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'دليل الاستخدام'),
          const SizedBox(height: 8),
          _HelpTutorialCard(
            icon: Icons.add_circle_outline,
            title: 'إنشاء شحنة جديدة',
            steps: [
              'اضغط على "إنشاء شحنة" من الصفحة الرئيسية',
              'اختر نوع الخدمة (دولي بري / بحري / محلي)',
              'أدخل بيانات المرسل والمستلم',
              'أدخل تفاصيل الطرد (الوزن، الأبعاد، الوصف)',
              'راجع السعر التقديري',
              'اضغط "تأكيد الشحنة"',
              'احفظ رقم التتبع للمتابعة',
            ],
          ),
          _HelpTutorialCard(
            icon: Icons.gps_fixed,
            title: 'تتبع الشحنة',
            steps: [
              'من القائمة اختر "الشحنات"',
              'ابحث برقم التتبع أو اختر الشحنة',
              'اضغط على "تتبع الشحنة"',
              'سترى الموقع الحالي على الخريطة',
              'تابع تحديثات الحالة في خط التتبع',
            ],
          ),
          _HelpTutorialCard(
            icon: Icons.calculate_outlined,
            title: 'حاسبة السعر',
            steps: [
              'من الصفحة الرئيسية اضغط "حاسبة السعر"',
              'أدخل الوزن والأبعاد والوجهة',
              'اختر نوع الخدمة',
              'اضغط "احسب" لعرض السعر التقديري',
            ],
          ),
          _HelpTutorialCard(
            icon: Icons.description_outlined,
            title: 'رفع المستندات',
            steps: [
              'من تفاصيل الشحنة اضغط "المستندات"',
              'اضغط "رفع مستند جديد"',
              'اختر الملف من جهازك',
              'حدد نوع المستند (فاتورة، جواز، إلخ)',
              'اضغط "رفع"',
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'الأسئلة الشائعة'),
          const SizedBox(height: 8),
          _FaqExpansionTile(
            question: 'كيف أستعيد كلمة المرور؟',
            answer: 'من شاشة تسجيل الدخول، اضغط "نسيت كلمة المرور"، أدخل بريدك الإلكتروني، واتبع الخطوات لإدخال رمز التحقق وإنشاء كلمة مرور جديدة.',
          ),
          _FaqExpansionTile(
            question: 'كم تستغرق الشحنات الدولية؟',
            answer: 'تختلف المدة حسب الوجهة: الشحن الدولي البري من 7-14 يوم، الشحن البحري من 21-45 يوم، الشحن المحلي من 1-3 أيام.',
          ),
          _FaqExpansionTile(
            question: 'كيف أغير عنوان التسليم؟',
            answer: 'يمكنك تعديل عنوان التسليم من تفاصيل الشحنة قبل أن يبدأ السائق في التوصيل. اتصل بالدعم الفني إذا كانت الشحنة في الطريق.',
          ),
          _FaqExpansionTile(
            question: 'ما هي طرق الدفع المتاحة؟',
            answer: 'نقبل الدفع بالبطاقة الائتمانية، محافظ الهاتف المحمول (فودافون كاش، أورانج كاش)، والدفع عند الاستلام.',
          ),
          _FaqExpansionTile(
            question: 'كيف أتابع شكوى دعم فني؟',
            answer: 'من شاشة "الدعم الفني"، يمكنك متابعة جميع شكاواك وحالة كل شكوى والردود عليها.',
          ),
          _FaqExpansionTile(
            question: 'هل يمكنني إلغاء شحنة؟',
            answer: 'نعم، يمكنك إلغاء الشحنة قبل بدء المعالجة. من تفاصيل الشحنة اضغط "إلغاء الشحنة". لا يمكن الإلغاء بعد الشحن.',
          ),
          _FaqExpansionTile(
            question: 'كيف أحصل على فاتورة؟',
            answer: 'ال fatsورة تُنشأ تلقائياً بعد تأكيد الشحنة. يمكنك تحميلها من قسم "الفواتير" في الملف الشخصي.',
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'تواصل معنا'),
          const SizedBox(height: 8),
          _ContactCard(
            icon: Icons.phone_outlined,
            title: 'الهاتف',
            subtitle: '19000',
            onTap: () => launchUrl(Uri.parse('tel:19000')),
          ),
          _ContactCard(
            icon: Icons.email_outlined,
            title: 'البريد الإلكتروني',
            subtitle: 'support@swiftegypt.com',
            onTap: () => launchUrl(Uri.parse('mailto:support@swiftegypt.com')),
          ),
          _ContactCard(
            icon: Icons.chat_bubble_outline,
            title: 'الدردشة المباشرة',
            subtitle: 'متاح من 9 صباحاً - 6 مساءً',
            onTap: () => Navigator.pushNamed(context, AppRoutes.chat),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
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
        borderRadius: BorderRadius.circular(16),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
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
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
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
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: AppTheme.primaryBlue,
        collapsedIconColor: const Color(0xFF94A3B8),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),
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
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_left, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}
