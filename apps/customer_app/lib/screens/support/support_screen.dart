import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدعم الفني')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.headset_mic, size: 48, color: AppTheme.primaryBlue),
                    const SizedBox(height: 12),
                    const Text('كيف يمكننا مساعدتك؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('فريق الدعم الفني جاهز لمساعدتك', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('الأسئلة الشائعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _faqItem(context, 'كيف أتتبع شحنتي؟',
                'يمكنك تتبع شحنتك من خلال الذهاب إلى "تتبع شحنة" في الشاشة الرئيسية وإدخال رقم التتبع الخاص بك. كما يمكنك تفعيل الإشعارات لتلقي التحديثات لحظة بلحظة.'),
            _faqItem(context, 'ما هي طرق الدفع المتاحة؟',
                'نوفر عدة طرق دفع مرنة: الدفع نقداً عند الاستلام، التحويل البنكي، والدفع عبر البطاقات الائتمانية. يمكنك اختيار الطريقة التي تناسبك أثناء إنشاء الشحنة.'),
            _faqItem(context, 'كم يستغرق الشحن؟',
                'مدة الشحن تعتمد على نوع الخدمة: الشحن الداخلي يستغرق 1-3 أيام عمل، الشحن البري الدولي 5-10 أيام، والشحن البحري 15-30 يوماً حسب الوجهة.'),
            _faqItem(context, 'كيف أرفع مستندات؟',
                'يمكنك رفع المستندات المطلوبة من خلال تفاصيل الشحنة. نوصي برفع: الفاتورة التجارية، بوليصة الشحن، وشهادة المنشأ. سيتم مراجعة المستندات من قبل فريقنا.'),
            _faqItem(context, 'ما هي المستندات المطلوبة للشحن؟',
                'تختلف المستندات حسب نوع الشحنة والوجهة، ولكن عادة ما تشمل: الفاتورة التجارية، قائمة التعبئة، بوليصة الشحن، وشهادة المنشأ. للشحنات الشخصية قد يلزم جواز السفر.'),
            const SizedBox(height: 24),
            const Text('معلومات الاتصال', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.phone, color: AppTheme.primaryBlue), title: const Text('رقم الهاتف'), subtitle: const Text('+20 100 000 0000')),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.email_outlined, color: AppTheme.primaryBlue), title: const Text('البريد الإلكتروني'), subtitle: const Text('support@swiftegypt.com')),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue), title: const Text('العنوان'), subtitle: const Text('القاهرة، مصر')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('فتح تذكرة دعم'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: Color(0xFF64748B), height: 1.5)),
          ),
        ],
      ),
    );
  }
}
