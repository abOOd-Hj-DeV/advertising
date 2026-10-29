import 'package:flutter/material.dart';
import '../data/demo_store.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'account.dart';

Color panelBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xff11120f)
    : Brand.background;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: panelBackground(context),
    appBar: const PageHeader('الإعدادات والمساعدة'),
    body: ListView(
      children: [
        if (DemoScope.of(context).signedIn) ...[
          RowLink(
            'تعديل الملف الشخصي',
            icon: Icons.person_outline,
            onTap: () => go(
              context,
              EditProfilePage(initial: DemoScope.of(context).name),
            ),
          ),
          RowLink(
            'الإشعارات',
            icon: Icons.notifications_none,
            onTap: () => go(context, const NotificationPreferencesPage()),
          ),
        ],
        RowLink(
          'البيانات المحلية والحدود',
          icon: Icons.storage_outlined,
          onTap: () => go(context, const LocalDataPage()),
        ),
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              RowLink(
                'حذف سجل البحث',
                icon: Icons.manage_search,
                trailing: const SizedBox.shrink(),
                onTap: () async {
                  final store = DemoScope.of(context);
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('حذف سجل البحث؟'),
                      content: const Text(
                        'ستُحذف فقط عبارات البحث المحفوظة محليًا في هذا العرض التجريبي.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('حذف'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true) {
                    store.clearHistory();
                    if (context.mounted) {
                      toast(context, 'تم حذف سجل البحث المحلي');
                    }
                  }
                },
              ),
              const Divider(indent: 16),
              RowLink(
                'سوقنا بلس',
                subtitle: 'اشتراك',
                icon: Icons.auto_awesome_outlined,
                trailing: const SizedBox.shrink(),
                onTap: () => go(context, const PurPage()),
              ),
              const Divider(indent: 16),
              RowLink(
                'الخصوصية',
                subtitle: 'إعدادات الخصوصية · سياسة الخصوصية',
                icon: Icons.lock_outline,
                trailing: const SizedBox.shrink(),
                onTap: () => go(context, const PrivacyPage()),
              ),
              const Divider(indent: 16),
              RowLink(
                'المظهر',
                subtitle: 'مظهر فاتح · مظهر داكن',
                icon: Icons.light_mode_outlined,
                trailing: const SizedBox.shrink(),
                onTap: () => go(context, const DesignPage()),
              ),
              const Divider(indent: 16),
              RowLink(
                'حول سوقنا',
                subtitle: 'البيان القانوني · الوظائف · إمكانية الوصول',
                icon: Icons.star_outline,
                trailing: const SizedBox.shrink(),
                onTap: () => go(context, const AboutPage()),
              ),
              const Divider(indent: 16),
              RowLink(
                'المساعدة والملاحظات',
                subtitle: 'قسم المساعدة · الإبلاغ عن عطل · أرسل ملاحظاتك',
                icon: Icons.support,
                trailing: const SizedBox.shrink(),
                onTap: () => go(context, const HelpMenuPage()),
              ),
              const Divider(indent: 16),
              RowLink(
                'إلغاء العقد',
                icon: Icons.info_outline,
                trailing: const SizedBox.shrink(),
                onTap: () => go(
                  context,
                  const InformationPage(
                    title: 'إلغاء العقد',
                    paragraphs: [
                      'لا يوجد عقد في هذا العرض التجريبي',
                      'لا توجد اشتراكات أو مدفوعات أو علاقات تعاقدية حقيقية. '
                          'شاشة المعلومات المحلية هذه إضافة تجريبية.',
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 34),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.devices_outlined, size: 19, color: Brand.muted),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  DemoScope.of(context).isLive
                      ? '1.0.0 (1) · سوقنا'
                      : '1.0.0 (1) · واجهة Flutter تجريبية',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Brand.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => go(context, const DemoInfoPage()),
            child: const Text(
              'حول هذا العرض التجريبي',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: panelBackground(context),
    appBar: const PageHeader('الخصوصية'),
    body: Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RowLink(
            'إعدادات الخصوصية والقياس والتحليل',
            trailing: const SizedBox.shrink(),
            onTap: () => go(context, const ConsentSettingsPage()),
          ),
          const Divider(indent: 16, endIndent: 16),
          RowLink(
            'سياسة الخصوصية',
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () =>
                go(context, const LegalPage(kind: 'Datenschutzerklärung')),
          ),
          const Divider(indent: 16, endIndent: 16),
          RowLink(
            'شروط الاستخدام',
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => go(
              context,
              const LegalPage(kind: 'Messaging-Nutzungsbedingungen'),
            ),
          ),
        ],
      ),
    ),
  );
}

class ConsentIntroPage extends StatelessWidget {
  const ConsentIntroPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 42),
              const Logo(size: 46),
              const SizedBox(height: 42),
              const Text(
                'كيف تريد استخدام سوقنا؟',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'أهلاً بك في سوقنا',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              const Text(
                'بالإعلانات والتتبع كالمعتاد',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                DemoScope.of(context).isLive
                    ? 'نحترم خصوصيتك. لا نستخدم شبكات إعلانية خارجية في هذه النسخة.'
                    : 'في النسخة المرجعية تُعرض هنا معلومات عن الإعلانات والخصوصية. '
                        'هذا العرض التجريبي المحلي لا يستخدم شبكات إعلانية ولا تحليلات ولا خوادم. يبقى اختيارك على هذا الجهاز.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                'قبول الكل',
                onPressed: () => store.acceptConsent(all: true),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                'رفض الكل والمتابعة',
                onPressed: () => store.acceptConsent(),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => go(context, const ConsentSettingsPage()),
                child: const Text('إعدادات الخصوصية'),
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'بدون إعلانات مع سوقنا بلس',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'معاينة مرئية فقط. لا يوجد اشتراك حقيقي ولا دفع.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => go(context, const PurPage()),
                child: const Text('عرض سوقنا بلس'),
              ),
              const SizedBox(height: 18),
              const Text(
                'دراسة واجهة غير رسمية بمحتوى افتراضي.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Brand.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConsentSettingsPage extends StatefulWidget {
  const ConsentSettingsPage({super.key});
  @override
  State<ConsentSettingsPage> createState() => _ConsentSettingsPageState();
}

class _ConsentSettingsPageState extends State<ConsentSettingsPage> {
  bool? personalized, analytics;
  void save({bool? all}) {
    final store = DemoScope.of(context);
    if (!store.consentAccepted) store.acceptConsent();
    store.setPrivacy(
      personalized: all ?? personalized ?? store.personalized,
      analytics: all ?? analytics ?? store.analytics,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      appBar: const PageHeader('إعدادات الخصوصية'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'الإعلانات والإعدادات الشخصية المرتبطة بها',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'هذا المحتوى والإعدادات التالية تخص عرضنا التجريبي.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'تحكّم في المعلومات التي يمكننا استخدامها لتخصيص تجربتك',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'هنا تختار الإعدادات المعروضة محليًا. في هذا العرض التجريبي لا يصل أي شركاء '
            'إلى جهازك. ملفات تعريف الارتباط وملفات الإعلانات وتتبّع الطرف الثالث غير مُطبَّقة.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 14),
          PrimaryButton('قبول الكل', onPressed: () => save(all: true)),
          const SizedBox(height: 8),
          PrimaryButton(
            'رفض الكل والمتابعة',
            onPressed: () => save(all: false),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => save(),
            child: const Text('حفظ ومتابعة'),
          ),
          OutlinedButton(
            onPressed: () => go(context, const PurPage()),
            child: const Text('اشترك في سوقنا بلس'),
          ),
          const SizedBox(height: 20),
          const Text(
            'المصلحة المشروعة',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'المفاتيح التالية للعرض المحلي فقط.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('محتوى مخصّص', style: TextStyle(fontSize: 15)),
            value: personalized ?? store.personalized,
            onChanged: (v) => setState(() => personalized = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'القياس والتحليل',
              style: TextStyle(fontSize: 15),
            ),
            value: analytics ?? store.analytics,
            onChanged: (v) => setState(() => analytics = v),
          ),
          RowLink(
            'عرض الأغراض',
            onTap: () => go(
              context,
              const InformationPage(
                title: 'عرض الأغراض',
                paragraphs: [
                  'بيانات مثال محلية',
                  'تغيّر المفاتيح إعدادات العرض التجريبي فقط. لا تُنقل أي بيانات استخدام.',
                ],
              ),
            ),
          ),
          RowLink(
            'عرض الشركاء',
            onTap: () => go(
              context,
              const InformationPage(
                title: 'عرض الشركاء',
                paragraphs: [
                  'لا شركاء في هذا العرض التجريبي',
                  'لا يحتوي التطبيق على حزم إعلانية ولا ينقل بيانات إلى شركاء.',
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DesignPage extends StatelessWidget {
  const DesignPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      backgroundColor: panelBackground(context),
      appBar: const PageHeader('المظهر'),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'المظهر الداكن يحافظ على بطاريتك ويوفر الطاقة فعلًا. '
                'مفيد لك وللبيئة.',
                style: TextStyle(fontSize: 14, height: 1.3),
              ),
            ),
            for (final entry in {
              ThemeMode.system: 'استخدام إعدادات النظام',
              ThemeMode.dark: 'مظهر داكن',
              ThemeMode.light: 'مظهر فاتح',
            }.entries)
              Column(
                children: [
                  RowLink(
                    entry.value,
                    icon: store.themeMode == entry.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    trailing: const SizedBox.shrink(),
                    onTap: () => store.setTheme(entry.key),
                  ),
                  const Divider(indent: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: panelBackground(context),
    appBar: const PageHeader('حول سوقنا'),
    body: Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in [
            (label: 'البيان القانوني', kind: 'Impressum'),
            (label: 'الوظائف', kind: 'Karriereseite'),
            (label: 'بيان إمكانية الوصول', kind: 'Barrierefreiheitserklärung'),
            (label: 'حقوق النشر', kind: 'Copyright'),
          ])
            Column(
              children: [
                RowLink(
                  item.label,
                  trailing: item.kind == 'Copyright'
                      ? const SizedBox.shrink()
                      : const Icon(Icons.open_in_new, size: 18),
                  onTap: () => go(
                    context,
                    item.kind == 'Karriereseite' ||
                            item.kind == 'Barrierefreiheitserklärung'
                        ? WebConsentPage(title: item.label)
                        : LegalPage(kind: item.kind),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
              ],
            ),
        ],
      ),
    ),
  );
}

class HelpMenuPage extends StatelessWidget {
  const HelpMenuPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: panelBackground(context),
    appBar: const PageHeader('المساعدة والملاحظات'),
    body: Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RowLink(
            'مركز الحلول',
            trailing: const SizedBox.shrink(),
            onTap: () => go(context, const ErrorPage()),
          ),
          const Divider(indent: 16, endIndent: 16),
          RowLink(
            'قسم المساعدة',
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => go(context, const HelpCenterPage()),
          ),
          const Divider(indent: 16, endIndent: 16),
          RowLink(
            'الإبلاغ عن عطل',
            trailing: const SizedBox.shrink(),
            onTap: () =>
                go(context, const FeedbackPage(title: 'الإبلاغ عن عطل')),
          ),
          const Divider(indent: 16, endIndent: 16),
          RowLink(
            'أرسل ملاحظاتك',
            trailing: const SizedBox.shrink(),
            onTap: () =>
                go(context, const FeedbackPage(title: 'أرسل ملاحظاتك')),
          ),
        ],
      ),
    ),
  );
}

const helpTopics = {
  'الإعلانات': ['كيف أنشر إعلانًا؟', 'كيف أعدّل إعلاني؟', 'كيف أحذف إعلانًا؟'],
  'حساب المستخدم': [
    'كيف أنشئ حسابًا؟',
    'كيف أعدّل ملفي الشخصي؟',
    'كيف أسجّل الخروج؟',
  ],
  'الأمان': ['كيف أميّز العروض الموثوقة؟', 'كيف أحمي بياناتي؟'],
  'الدفع الآمن': ['كيف يعمل الدفع الآمن؟', 'ما طرق الدفع المتاحة؟'],
  'الشحن': ['كيف أرتّب الاستلام الشخصي؟', 'كيف يتم الشحن؟'],
  'سوقنا بلس': ['ما هو سوقنا بلس؟', 'كيف أدير اشتراكي؟'],
};

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});
  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final articles = [
      for (final group in helpTopics.entries)
        for (final article in group.value) article,
    ];
    return Scaffold(
      appBar: const PageHeader('مركز مساعدة سوقنا', close: true),
      body: ListView(
        children: [
          Container(
            color: Brand.deep,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Logo(size: 36, color: Colors.white),
                const SizedBox(height: 22),
                const Text(
                  'كيف نستطيع مساعدتك؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (v) => setState(() => query = v),
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'أدخل كلمة البحث',
                    hintStyle: const TextStyle(color: Brand.muted),
                    prefixIcon: const Icon(Icons.search, color: Brand.green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Text(
              'معاينة مساعدة محلية · المقالات إضافات تجريبية',
              style: TextStyle(color: Brand.muted, fontSize: 11),
            ),
          ),
          if (query.isNotEmpty) ...[
            for (final a in articles.where(
              (a) => a.toLowerCase().contains(query.toLowerCase()),
            ))
              RowLink(
                a,
                onTap: () => go(
                  context,
                  InformationPage(
                    title: a,
                    paragraphs: [
                      a,
                      'يعرض هذا التطبيق التجريبي الاستخدام ببيانات افتراضية. '
                          'تبقى الإعلانات والرسائل وإجراءات الحساب محلية؛ لا يمكن إجراء مشتريات أو مدفوعات حقيقية.',
                    ],
                  ),
                ),
              ),
            if (!articles.any(
              (a) => a.toLowerCase().contains(query.toLowerCase()),
            ))
              const Padding(
                padding: EdgeInsets.all(30),
                child: Text('لا توجد مقالات مساعدة مطابقة.'),
              ),
          ] else
            for (final topic in helpTopics.keys)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: RowLink(
                    topic,
                    subtitle: 'إجابات عن $topic',
                    icon: Icons.help_outline,
                    onTap: () => go(context, HelpTopicPage(topic: topic)),
                  ),
                ),
              ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class HelpTopicPage extends StatelessWidget {
  const HelpTopicPage({super.key, required this.topic});
  final String topic;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(topic),
    body: ListView(
      children: [
        for (final article in helpTopics[topic] ?? [])
          Column(
            children: [
              RowLink(
                article,
                onTap: () => go(
                  context,
                  InformationPage(
                    title: article,
                    paragraphs: [
                      article,
                      'ستجد هنا شرحًا افتراضيًا للعرض التجريبي المحلي. '
                          'لم تُنقل المساعدة الحقيقية. تبقى جميع إجراءات العرض على جهازك.',
                    ],
                  ),
                ),
              ),
              const Divider(),
            ],
          ),
      ],
    ),
  );
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, this.home = false});
  final bool home;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(home ? 'بحث' : 'مركز الحلول', center: true),
    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ErrorArtwork(),
              const SizedBox(height: 36),
              Text(
                home ? 'حدث خطأ ما' : 'مشكلة تقنية',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                home
                    ? 'يرجى المحاولة مرة أخرى.'
                    : 'هناك مشكلة تقنية قيد الإصلاح حاليًا.\nلا حاجة لتحديث التطبيق.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {
                  if (home) {
                    openMarketplaceTab(context, 0, returnToRoot: true);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const HelpCenterPage(),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                child: const Text('إعادة المحاولة'),
              ),
              const SizedBox(height: 16),
              const Text(
                'حالة خطأ محاكاة · إعادة المحاولة تفتح العرض المحلي.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Brand.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: home
        ? BottomTabs(
            selected: 0,
            onTap: (tab) =>
                openMarketplaceTab(context, tab, returnToRoot: true),
          )
        : null,
  );
}

class ErrorArtwork extends StatelessWidget {
  const ErrorArtwork({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(190, 150), painter: _CoffeePainter());
}

class _CoffeePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final paint = Paint();
    c.drawOval(
      const Rect.fromLTWH(15, 131, 158, 9),
      paint..color = const Color(0xffefeeeb),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(86, 42, 69, 85),
        const Radius.circular(10),
      ),
      paint..color = const Color(0xffebe7dc),
    );
    c.drawRect(
      const Rect.fromLTWH(91, 83, 58, 40),
      paint..color = const Color(0xffb88455),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(87, 30, 62, 18),
        const Radius.circular(5),
      ),
      paint..color = const Color(0xffd9ecf9),
    );
    c.drawArc(
      const Rect.fromLTWH(118, 46, 55, 65),
      -1.5,
      2.6,
      false,
      Paint()
        ..color = const Color(0xff91918d)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(38, 83, 51, 43),
        const Radius.circular(8),
      ),
      paint..color = const Color(0xffffc9cc),
    );
    for (final x in [53.0, 70.0, 112.0, 130.0]) {
      c.drawOval(
        Rect.fromLTWH(x, x < 80 ? 98 : 67, 4, 6),
        paint..color = const Color(0xff464844),
      );
    }
    for (final r in [
      const Rect.fromLTWH(55, 100, 13, 12),
      const Rect.fromLTWH(114, 69, 15, 12),
    ]) {
      c.drawArc(
        r,
        0,
        3.14,
        false,
        Paint()
          ..color = const Color(0xff464844)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final steam = Path()
      ..moveTo(62, 74)
      ..cubicTo(78, 64, 45, 62, 59, 53);
    c.drawPath(
      steam,
      Paint()
        ..color = const Color(0xffe6edf1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(_CoffeePainter oldDelegate) => false;
}

class InformationPage extends StatelessWidget {
  const InformationPage({
    super.key,
    required this.title,
    required this.paragraphs,
  });
  final String title;
  final List<String> paragraphs;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(title),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (var i = 0; i < paragraphs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              paragraphs[i],
              style: TextStyle(
                fontSize: i == 0 ? 23 : 15,
                fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
      ],
    ),
  );
}

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.kind});
  final String kind;
  @override
  Widget build(BuildContext context) {
    // `kind` is a cross-file key (other pages pass German values); it is not
    // shown to the user. `displayKind` is the Arabic title rendered instead.
    final displayKind = switch (kind) {
      'Datenschutzerklärung' => 'سياسة الخصوصية',
      'Messaging-Nutzungsbedingungen' => 'شروط استخدام المراسلات',
      'Nutzungsbedingungen' => 'شروط الاستخدام',
      'Impressum' => 'البيان القانوني',
      'Copyright' => 'حقوق النشر',
      _ => kind,
    };
    final privacy = displayKind == 'سياسة الخصوصية';
    final sections = privacy
        ? [
            'نطاق تطبيق سياسة الخصوصية هذه وتحديثها',
            'الجهة المسؤولة',
            'مسؤول حماية البيانات والتواصل',
            'البيانات الشخصية التي نجمعها ونعالجها',
            'أغراض معالجة البيانات وأسسها القانونية',
            'نقل البيانات دوليًا',
            'مدة التخزين والحذف',
            'حقوقك كصاحب بيانات',
            'ملفات تعريف الارتباط والتقنيات المشابهة',
            'أمن البيانات',
          ]
        : displayKind == 'حقوق النشر'
        ? [
            'Flutter',
            'Nunito Sans',
            'صور Unsplash',
            'مرجع الواجهة والعلامات التجارية',
          ]
        : displayKind == 'البيان القانوني'
        ? [
            'البيان القانوني للعرض التجريبي',
            'التواصل',
            'ملاحظات حول دراسة الواجهة',
          ]
        : [
            'نطاق التطبيق',
            'الرسائل المحلية التجريبية',
            'المسؤولية والأمان',
            'لا عقود حقيقية',
          ];
    final anchorKeys = [for (final _ in sections) GlobalKey()];
    return Scaffold(
      appBar: const PageHeader('سوقنا'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Logo(size: 24, wordmark: false),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => toast(
                      context,
                      'هذا النص التجريبي المحلي ليس له رابط خارجي.',
                    ),
                    icon: const Icon(Icons.share_outlined, size: 15),
                    label: const Text('مشاركة', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Brand.pale,
              child: const Text(
                'محتوى مثال لعرض واجهة غير رسمي. ليس نصًا قانونيًا ملزمًا من سوقنا.',
                style: TextStyle(color: Brand.deep, fontSize: 12),
              ),
            ),
            if (privacy)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المحتويات',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < sections.length; i++)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          alignment: AlignmentDirectional.centerStart,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => Scrollable.ensureVisible(
                          anchorKeys[i].currentContext!,
                          duration: const Duration(milliseconds: 250),
                          alignment: .05,
                        ),
                        icon: const Icon(Icons.south, size: 16),
                        label: Text(
                          sections[i],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
              child: Text(
                displayKind,
                textAlign: privacy ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (var i = 0; i < sections.length; i++)
              Padding(
                key: anchorKeys[i],
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${sections[i]}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayKind == 'حقوق النشر'
                          ? switch (i) {
                              0 =>
                                'Flutter إطار عمل مفتوح المصدر. تحتفظ المكتبات بتراخيصها الخاصة.',
                              1 =>
                                'يُستخدم خط Nunito Sans بموجب رخصة SIL Open Font License 1.1. نص الرخصة موجود في المشروع.',
                              2 =>
                                'الصور المثال المضمّنة محليًا من Unsplash. المصادر في ملف ASSET_CREDITS.md.',
                              _ =>
                                'العلامات التجارية ملك لأصحابها. هذا العرض التجريبي ليس منتجًا رسميًا من سوقنا.',
                            }
                          : displayKind == 'البيان القانوني'
                          ? 'مزوّد تجريبي افتراضي\nشارع المثال 12 · دمشق\ndemo@example.test\n\n'
                                'هذه بيانات مختلقة عمدًا. لا يُدار سوق حقيقي.'
                          : 'لا يعالج هذا العرض التجريبي بيانات على خادم. عبارات البحث وعرض الحساب والرسائل '
                                'حالات محلية افتراضية. لا تُحفظ كلمة المرور المُدخلة. يمكن حفظ المظهر والمفضلة '
                                'وعمليات البحث المحفوظة وخيار الخصوصية على جهازك. '
                                'يمكنك إزالة هذه البيانات من إعدادات التطبيق أو ذاكرة المتصفح. '
                                'هذا نص مثال، ليس استشارة قانونية ولا سياسة منسوخة.',
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

class WebConsentPage extends StatefulWidget {
  const WebConsentPage({super.key, required this.title});
  final String title;
  @override
  State<WebConsentPage> createState() => _WebConsentPageState();
}

class _WebConsentPageState extends State<WebConsentPage> {
  bool accepted = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(widget.title, close: true),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Logo(size: 34),
        const SizedBox(height: 24),
        if (!accepted) ...[
          const Text(
            'أهلاً بك في سوقنا',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          const Text(
            'بالإعلانات والتتبع كالمعتاد',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'أظهر الفحص المرجعي هنا صفحة موافقة ويب مستقلة. '
            'المعاينة التالية محلية ولا تستخدم ملفات تعريف ارتباط أو خدمات خارجية.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'قبول الكل',
            onPressed: () => setState(() => accepted = true),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => setState(() => accepted = true),
            child: const Text('رفض الكل والمتابعة'),
          ),
        ] else ...[
          Text(
            widget.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title == 'الوظائف'
                ? 'إضافة تجريبية: نصنع المستقبل معًا. '
                      'لا تحتوي هذه المعاينة على وظائف حقيقية.'
                : 'إضافة تجريبية: تدعم الواجهة التمرير وملصقات الدلالة '
                      'والنصوص الأكبر والألوان عالية التباين. '
                      'هذا ليس بيان إمكانية وصول رسميًا.',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ],
    ),
  );
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, required this.title, this.subject = ''});
  final String title, subject;
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final text = TextEditingController();
  final key = GlobalKey<FormState>();
  bool sent = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(widget.title),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: sent
          ? const Column(
              children: [
                Icon(Icons.check_circle_outline, size: 70, color: Brand.green),
                SizedBox(height: 20),
                Text(
                  'شكرًا لملاحظاتك على العرض التجريبي!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 12),
                Text('لم يُرسل شيء. سيُتجاهل هذا الإدخال عند الإغلاق.'),
              ],
            )
          : Form(
              key: key,
              child: ListView(
                children: [
                  const Text(
                    'يبقى هذا الإدخال في هذه الشاشة فقط. لن يُرسل أي تقرير.',
                    style: TextStyle(color: Brand.muted, fontSize: 13),
                  ),
                  if (widget.subject.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.subject,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: text,
                    maxLines: 7,
                    decoration: const InputDecoration(labelText: 'رسالتك'),
                    validator: (v) => v != null && v.trim().length >= 10
                        ? null
                        : 'أدخل 10 أحرف على الأقل',
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    'تأكيد ملاحظات العرض',
                    onPressed: () {
                      if (key.currentState!.validate()) {
                        setState(() => sent = true);
                      }
                    },
                  ),
                ],
              ),
            ),
    ),
  );
}

class PurPage extends StatelessWidget {
  const PurPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('سوقنا بلس'),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 30),
        const Logo(size: 46),
        const SizedBox(height: 32),
        const Text(
          'قطعك المفضلة.\nبدون مشتتات.',
          style: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'معاينة لصفحة اشتراك. لا اشتراك حقيقي ولا دفع. هذه الشاشة إضافة تجريبية.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        const RowLink(
          'لا إعلانات خارجية',
          icon: Icons.check,
          trailing: SizedBox.shrink(),
        ),
        const RowLink(
          'لا مشاركة مع شركاء إعلانيين',
          icon: Icons.check,
          trailing: SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          'مشاهدة العرض التجريبي',
          onPressed: () => toast(
            context,
            'العرض التجريبي يعمل دون اتصال وخالٍ من الإعلانات أصلًا.',
          ),
        ),
      ],
    ),
  );
}

class DemoInfoPage extends StatelessWidget {
  const DemoInfoPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('حول هذا العرض التجريبي'),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'دراسة واجهة Flutter',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        const Text(
          'مبني على فحص مرئي أثناء التشغيل. دون استخراج أي كود أو موارد. '
          'جميع الإعلانات والحسابات والنصوص والمحادثات افتراضية. لا توجد واجهة برمجة شبكة ولا مدفوعات حقيقية.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 16),
        const Text(
          'الشاشات غير الملاحَظة مثل محتوى الحساب ونشر الإعلانات ومقالات المساعدة الأعمق '
          'هي صراحةً إضافات تجريبية. الصور والخط أصول بديلة مرخّصة.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 16),
        RowLink(
          'الصفحة الرئيسية في حالة خطأ',
          icon: Icons.error_outline,
          onTap: () => go(context, const ErrorPage(home: true)),
        ),
        RowLink(
          'مركز الحلول في حالة خطأ',
          icon: Icons.support,
          onTap: () => go(context, const ErrorPage()),
        ),
        RowLink(
          'التراخيص',
          icon: Icons.description_outlined,
          onTap: () => go(context, const LegalPage(kind: 'Copyright')),
        ),
      ],
    ),
  );
}
