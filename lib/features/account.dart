import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/demo_store.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
export 'local_pages.dart';
export 'listing_editor.dart' show NewListingPage;
import 'local_pages.dart';
import 'settings.dart';

void openMarketplaceTab(
  BuildContext context,
  int tab, {
  bool returnToRoot = false,
}) {
  final store = DemoScope.of(context);
  final navigator = Navigator.of(context);
  if (returnToRoot) navigator.popUntil((route) => route.isFirst);
  if (tab != 0 && !store.signedIn) {
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => GuestPage(variant: [1, 0, 3, 2, 1][tab]),
      ),
    );
  } else {
    store.changeTab(tab);
  }
}

class GuestPage extends StatefulWidget {
  const GuestPage({
    super.key,
    this.variant = 0,
    this.favoriteId,
    this.continueTo,
    this.onEntered,
  });
  final WidgetBuilder? continueTo;
  final VoidCallback? onEntered;
  final int variant;
  final String? favoriteId;
  @override
  State<GuestPage> createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> {
  late int variant = widget.variant;
  static const headlines = [
    'كل مفضّلاتك بلمحة واحدة',
    'سوقنا. نظرة شاملة على حسابك.',
    'المحادثات الجيدة تبدأ من هنا',
    'أفسح مكاناً لمفضلات جديدة',
  ];
  void openAuth(bool register) {
    final store = DemoScope.of(context);
    final navigator = Navigator.of(context);
    go(
      context,
      AuthPage(
        register: register,
        onSuccess: () {
          if (widget.favoriteId != null &&
              !store.favorites.contains(widget.favoriteId)) {
            store.toggleFavorite(widget.favoriteId!);
          }
          store.changeTab([1, 4, 3, 2][widget.variant]);
          widget.onEntered?.call();
          if (widget.continueTo != null) {
            navigator.push(MaterialPageRoute(builder: widget.continueTo!));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, limits) => SingleChildScrollView(
          child: SizedBox(
            height: math.max(limits.maxHeight, 700),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: 58,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'إغلاق',
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              DemoScope.of(context).changeTab(0);
                            }
                          },
                          icon: const Icon(Icons.close, color: Brand.green),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => go(context, const SettingsPage()),
                          child: const Text('مساعدة'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 78),
                  const Logo(size: 52),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onHorizontalDragEnd: (d) {
                          setState(
                            () => variant =
                                (variant +
                                    ((d.primaryVelocity ?? 0) < 0 ? 1 : 3)) %
                                4,
                          );
                        },
                        child: GuestIllustration(variant: variant),
                      ),
                    ),
                  ),
                  Text(
                    headlines[variant],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 4; i++)
                        IconButton(
                          tooltip: 'مقدمة ${i + 1}',
                          constraints: const BoxConstraints(
                            minWidth: 21,
                            minHeight: 26,
                          ),
                          padding: const EdgeInsets.all(5),
                          onPressed: () => setState(() => variant = i),
                          icon: Icon(
                            Icons.circle,
                            size: i == variant ? 9 : 6,
                            color: i == variant ? Brand.green : Brand.muted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton('إنشاء حساب', onPressed: () => openAuth(true)),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => openAuth(false),
                    child: const Text('تسجيل الدخول'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'عرض محلي تجريبي · لا حسابات حقيقية',
                    style: TextStyle(fontSize: 10, color: Brand.muted),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.register = false, this.onSuccess});
  final bool register;
  final VoidCallback? onSuccess;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final key = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  final profileName = TextEditingController(text: 'بائع تجريبي');
  bool passwordStage = false, hidden = true, newsletter = false;
  String accountType = 'فردي';
  @override
  void dispose() {
    profileName.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void submit() {
    if (!key.currentState!.validate()) return;
    if (!widget.register && !passwordStage) {
      setState(() => passwordStage = true);
      return;
    }
    final store = DemoScope.of(context);
    if (widget.register) {
      store.registerLocal(
        profileName.text,
        business: accountType == 'تجاري',
        news: newsletter,
      );
    } else {
      store.signIn();
    }
    email.clear();
    password.clear();
    Navigator.popUntil(context, (r) => r.isFirst);
    widget.onSuccess?.call();
    toast(context, 'تم فتح حساب تجريبي. لم تُرسَل أي بيانات دخول.');
  }

  void info(String title, String body) =>
      go(context, InformationPage(title: title, paragraphs: [title, body]));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(
      widget.register ? '' : 'تسجيل الدخول',
      actions: [
        TextButton(
          onPressed: () => go(context, const SettingsPage()),
          child: const Text('مساعدة'),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        widget.register ? 16 : 38,
        48,
        widget.register ? 16 : 38,
        28,
      ),
      child: Form(
        key: key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 22),
            if (!widget.register)
              TextButton(
                onPressed: () => go(context, const RecoveryPage()),
                child: const Text('نسيت كلمة المرور؟'),
              ),
            const Center(child: Logo(size: widgetLogoSize)),
            const SizedBox(height: widgetLogoSpacing),
            if (widget.register) ...[
              const Text(
                'كيف تريد استخدام سوقنا؟',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final t in ['فردي', 'تجاري'])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: t == 'فردي' ? 8 : 0,
                        ),
                        child: InkWell(
                          onTap: () => setState(() => accountType = t),
                          child: Container(
                            height: 47,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Brand.muted),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  accountType == t
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 20,
                                  color: accountType == t
                                      ? Brand.green
                                      : Brand.muted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(
                  alignment: AlignmentDirectional.centerStart,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => info(
                  'متى أبيع بصفة تجارية؟',
                  'إذا كنت تبيع بانتظام وبشكل تجاري، اختر «تجاري». '
                      'هذا العرض التجريبي لا ينشئ حسابات ملزمة قانوناً.',
                ),
                child: const Text('متى أبيع بصفة تجارية؟'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  alignment: AlignmentDirectional.centerStart,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => info(
                  'أقل من 18 سنة؟ ابدأ بأمان',
                  'تحدث مع والديك أو أولياء أمورك قبل أي شراء أو بيع حقيقي. '
                      'لا يمكن إجراء أي شراء في هذا العرض التجريبي.',
                ),
                child: const Text('أقل من 18 سنة؟ ابدأ بأمان'),
              ),
              const SizedBox(height: 16),
              const Text(
                'بيانات تسجيل الدخول',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Text(
                'أهلاً بك في سوقنا!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              const Text(
                'صديق لجيبك وللبيئة — سجّل دخولك الآن.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: widget.register
                    ? 'البريد الإلكتروني'
                    : 'البريد الإلكتروني*',
              ),
              validator: (v) =>
                  v != null && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)
                  ? null
                  : 'يرجى إدخال بريد إلكتروني صحيح',
            ),
            if (widget.register || passwordStage) ...[
              const SizedBox(height: 18),
              TextFormField(
                controller: password,
                obscureText: hidden,
                autofillHints: const [],
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  suffixIcon: IconButton(
                    tooltip: 'إظهار كلمة المرور',
                    onPressed: () => setState(() => hidden = !hidden),
                    icon: Icon(
                      hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (v) => v != null && v.length >= 8
                    ? null
                    : 'استخدم 8 أحرف على الأقل',
              ),
            ],
            if (widget.register) ...[
              TextFormField(
                controller: profileName,
                decoration: const InputDecoration(
                  labelText: 'اسم الملف الشخصي المحلي',
                ),
                validator: validateProfileName,
              ),
              const SizedBox(height: 16),
            ],
            if (widget.register) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Switch(
                    value: newsletter,
                    onChanged: (v) => setState(() => newsletter = v),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'حفظ تفضيل النشرة البريدية محلياً فقط. لا اشتراك ولا بريد يُرسَل.',
                        style: TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              widget.register
                  ? 'إنشاء حساب'
                  : passwordStage
                  ? 'تسجيل الدخول'
                  : 'متابعة',
              onPressed: submit,
            ),
            const SizedBox(height: 22),
            if (widget.register) ...[
              const Text(
                'تسري شروط الاستخدام الخاصة بنا. تجد معلومات عن معالجة بياناتك في سياسة الخصوصية.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => go(
                      context,
                      const LegalPage(kind: 'Nutzungsbedingungen'),
                    ),
                    child: const Text(
                      'شروط الاستخدام',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => go(
                      context,
                      const LegalPage(kind: 'Datenschutzerklärung'),
                    ),
                    child: const Text(
                      'سياسة الخصوصية',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'ليس لديك حساب بعد؟',
                    style: TextStyle(fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () => go(
                      context,
                      AuthPage(register: true, onSuccess: widget.onSuccess),
                    ),
                    child: const Text(
                      'أنشئ حساباً',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'تجريبي: استخدم بيانات وهمية مثل demo@example.test. '
              'لا يوجد تسجيل دخول حقيقي. لا تُحفَظ كلمة المرور ولا تُرسَل.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Brand.muted, height: 1.4),
            ),
          ],
        ),
      ),
    ),
  );
  static const widgetLogoSize = 46.0, widgetLogoSpacing = 42.0;
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return ListView(
      children: [
        AppBar(
          title: const Text('حسابي'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'الإعدادات',
              onPressed: () => go(context, const SettingsPage()),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Brand.pale,
                child: Icon(Icons.person_outline, color: Brand.deep, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'بائع تجريبي — حساب ${store.commercial ? 'تجاري' : 'فردي'}',
                      style: TextStyle(fontSize: 13, color: Brand.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Brand.pale,
            child: const Text(
              'إضافة تجريبية محلية: لم تكن طريقة العرض هذه بعد تسجيل الدخول متاحة في الاختبار المرجعي.',
              style: TextStyle(color: Brand.deep, fontSize: 12),
            ),
          ),
        ),
        RowLink(
          'تعديل الملف الشخصي',
          icon: Icons.edit_outlined,
          onTap: () async {
            final result = await go<String>(
              context,
              EditProfilePage(initial: store.name),
            );
            if (result != null && context.mounted) {
              store.updateProfile(result);
            }
          },
        ),
        const Divider(),
        RowLink(
          'إعلاناتي',
          subtitle: 'إعلانات محلية: ${store.ownListings.length}',
          icon: Icons.sell_outlined,
          onTap: () => go(context, const OwnListingsPage()),
        ),
        const Divider(),
        RowLink(
          'ملفي الشخصي التجريبي',
          icon: Icons.person_outline,
          onTap: () => go(context, const SelfProfilePage()),
        ),
        RowLink(
          'شوهد مؤخراً',
          icon: Icons.history,
          onTap: () => go(context, const RecentPage()),
        ),
        RowLink(
          'الإشعارات',
          icon: Icons.notifications_none,
          onTap: () => go(context, const NotificationsPage()),
        ),
        const Divider(),
        RowLink(
          'الإعدادات والمساعدة',
          icon: Icons.settings_outlined,
          onTap: () => go(context, const SettingsPage()),
        ),
        const Divider(),
        RowLink('تسجيل الخروج', icon: Icons.logout, onTap: store.signOut),
      ],
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.initial});
  final String initial;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final text = TextEditingController(text: widget.initial);
  final key = GlobalKey<FormState>();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('تعديل الملف الشخصي'),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: key,
        child: Column(
          children: [
            TextFormField(
              controller: text,
              decoration: const InputDecoration(labelText: 'الاسم التجريبي'),
              validator: validateProfileName,
            ),
            SwitchListTile(
              title: const Text('بائع تجريبي تجاري'),
              value: DemoScope.of(context).commercial,
              onChanged: (v) => DemoScope.of(
                context,
              ).updateProfile(DemoScope.of(context).name, business: v),
            ),
            const Text(
              'يُحفَظ نوع البائع والاسم محلياً فقط. لا يوجد تحقق ولا تسجيل تجاري رسمي.',
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: BottomAction(
      'حفظ',
      onPressed: () {
        if (key.currentState!.validate()) {
          DemoScope.of(context).updateProfile(text.text);
          Navigator.pop(context, text.text.trim());
        }
      },
    ),
  );
}
