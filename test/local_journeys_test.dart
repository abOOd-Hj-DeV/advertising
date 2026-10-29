import 'package:advertising/app.dart';
import 'package:advertising/data/demo_store.dart';
import 'package:advertising/data/media.dart';
import 'package:advertising/features/account.dart';
import 'package:advertising/features/listing.dart';
import 'package:advertising/features/listing_editor.dart';
import 'package:advertising/features/settings.dart';
import 'package:advertising/ui/theme.dart';
import 'package:advertising/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_fonts.dart';

DemoStore ready() => DemoStore()
  ..acceptConsent()
  ..signIn();
Future<void> page(
  WidgetTester tester,
  DemoStore store,
  Widget child, {
  double width = 393,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 852);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    DemoScope(
      store: store,
      child: MaterialApp(
        key: UniqueKey(),
        theme: Brand.theme(Brightness.light),
        darkTheme: Brand.theme(Brightness.dark),
        themeMode: store.themeMode,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);
Future<void> tapVisible(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> localLogin(WidgetTester tester) async {
  await tapVisible(tester, 'تسجيل الدخول');
  await tester.enterText(find.byType(TextFormField).first, 'demo@example.test');
  await tapVisible(tester, 'متابعة');
  await tester.enterText(find.byType(TextFormField).at(1), 'fiktiv-12345');
  final login = find.widgetWithText(FilledButton, 'تسجيل الدخول');
  await tester.ensureVisible(login);
  await tester.tap(login);
  await tester.pumpAndSettle();
  expect(find.text('يرجى إدخال بريد إلكتروني صحيح'), findsNothing);
  expect(find.text('استخدم 8 أحرف على الأقل'), findsNothing);
}

Listing own(String id) => Listing(
  id: id,
  title: 'كنبتي المحلية',
  price: 90,
  image: 'sofa',
  category: 'المنزل والحديقة',
  description: 'وصف محلي طويل بما فيه الكفاية.',
);
void main() {
  setUpAll(loadTestFonts);
  for (final choice in ['حفظ المسودة', 'تجاهل', 'متابعة التحرير']) {
    testWidgets('root editor Android back safely handles $choice', (
      tester,
    ) async {
      MediaRepository.instance = MediaRepository(MemoryMediaStorage());
      final s = ready()..changeTab(2);
      await page(tester, s, const Scaffold());
      await tester.pumpWidget(MarketplaceApp(store: s));
      await tester.pumpAndSettle();
      await tester.enterText(field('العنوان'), 'Android Durable Draft');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('الاحتفاظ بالتغييرات؟'), findsOneWidget);
      await tapVisible(tester, choice);
      expect(find.byType(MarketplaceShell), findsOneWidget);
      expect(s.selectedTab, choice == 'متابعة التحرير' ? 2 : 4);
      if (choice == 'حفظ المسودة') {
        expect(s.drafts.single.values['title'], 'Android Durable Draft');
      } else {
        expect(s.drafts, isEmpty);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('clean root editor Android back returns to Meins', (
    tester,
  ) async {
    final s = ready()..changeTab(2);
    await page(tester, s, const Scaffold());
    await tester.pumpWidget(MarketplaceApp(store: s));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MarketplaceShell), findsOneWidget);
    expect(s.selectedTab, 4);
    expect(tester.takeException(), isNull);
  });
  testWidgets('navigation labels remain single-line at 320px', (tester) async {
    await page(
      tester,
      ready(),
      Scaffold(bottomNavigationBar: BottomTabs(selected: 3, onTap: (_) {})),
      width: 320,
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('الرسائل'),
    );
    final lines = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 7),
    );
    expect(lines.map((box) => box.top).toSet(), hasLength(1));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'guest notification intent returns to Notifications rather than messages',
    (tester) async {
      final s = DemoStore()..acceptConsent();
      await page(tester, s, const Scaffold());
      await tester.pumpWidget(MarketplaceApp(store: s));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('الإشعارات'));
      await tester.pumpAndSettle();
      await localLogin(tester);
      expect(s.signedIn, isTrue);
      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(MessagesPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'guest contact intent resumes same listing thread after local entry',
    (tester) async {
      final s = DemoStore()..acceptConsent();
      await page(tester, s, ListingPage(listing: listings.first));
      await tester.tap(find.text('مراسلة'));
      await tester.pumpAndSettle();
      await localLogin(tester);
      expect(find.byType(MessagePage), findsOneWidget);
      expect(s.conversations.single.listingId, listings.first.id);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'registration stores chosen profile provider and local preference, never inputs',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      final s = DemoStore(preferences: p)..acceptConsent();
      await page(tester, s, const AuthPage(register: true));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'demo@example.test',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'fiktiv-nicht-speichern',
      );
      await tester.enterText(field('اسم الملف الشخصي المحلي'), 'فريق محلي');
      await tapVisible(tester, 'تجاري');
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tapVisible(tester, 'إنشاء حساب');
      await s.flush();
      expect(s.name, 'فريق محلي');
      expect(s.commercial, isTrue);
      expect(s.newsletter, isTrue);
      final raw = p.getString(DemoStore.storageKey)!;
      expect(raw, isNot(contains('demo@example.test')));
      expect(raw, isNot(contains('fiktiv-nicht-speichern')));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'draft survives tab switch and restart while preview cancel never publishes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      final s = DemoStore(preferences: p)
        ..acceptConsent()
        ..signIn()
        ..changeTab(2);
      await tester.pumpWidget(MarketplaceApp(store: s));
      await tester.pumpAndSettle();
      await tester.enterText(field('العنوان'), 'مسودة محلية');
      await tester.tap(find.text('حسابي'));
      await tester.pumpAndSettle();
      expect(find.text('الاحتفاظ بالتغييرات؟'), findsOneWidget);
      await tapVisible(tester, 'متابعة التحرير');
      expect(s.selectedTab, 2);
      await tester.tap(find.text('حسابي'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'حفظ المسودة');
      expect(s.selectedTab, 4);
      await s.flush();
      final restored = DemoStore(preferences: p)
        ..acceptConsent()
        ..signIn();
      expect(restored.drafts.single.values['title'], 'مسودة محلية');
      await page(
        tester,
        restored,
        ListingEditor(draft: restored.drafts.single),
      );
      await tester.enterText(field('السعر'), '123,45');
      await tester.enterText(field('الوصف'), 'محلي فقط، وصف كامل.');
      await tapVisible(tester, 'معاينة');
      expect(find.byType(ListingPreviewPage), findsOneWidget);
      expect(restored.ownListings, isEmpty);
      await tapVisible(tester, 'متابعة التحرير');
      expect(restored.ownListings, isEmpty);
      expect(field('العنوان'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'preview-confirmed edit preserves ID and deleted detail route cannot resurrect',
    (tester) async {
      final s = ready()..publish(own('own'));
      await page(
        tester,
        s,
        const ListingEditor(listingId: 'own', embedded: true),
      );
      await tester.enterText(field('العنوان'), 'كنبة محلية معدّلة');
      await tapVisible(tester, 'معاينة');
      expect(s.findListing('own')!.title, 'كنبتي المحلية');
      await tapVisible(tester, 'حفظ التغييرات محلياً');
      expect(s.ownListings.single.id, 'own');
      expect(s.ownListings.single.title, 'كنبة محلية معدّلة');
      final value = s.ownListings.single;
      await page(tester, s, ListingPage(listing: value));
      s.deleteListing('own');
      await tester.pumpAndSettle();
      expect(find.text('الإعلان غير متاح'), findsOneWidget);
      expect(find.text('مراسلة'), findsNothing);
      expect(s.findListing('own'), isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'chat drafts thread isolation incoming/read archive and block controls work',
    (tester) async {
      final s = ready();
      final a = s.ensureConversation(listings.first);
      final b = s.ensureConversation(listings[8]);
      s.sendMessage(a.id, 'في المحادثة الأولى فقط', incoming: true);
      s.sendMessage(b.id, 'في المحادثة الثانية فقط', incoming: true);
      await page(tester, s, MessagePage(threadId: a.id));
      expect(a.unread, 0);
      expect(b.unread, 1);
      expect(find.text('في المحادثة الأولى فقط'), findsOneWidget);
      expect(find.text('في المحادثة الثانية فقط'), findsNothing);
      await tester.enterText(find.byType(TextField), 'مسودة غير مرسلة');
      expect(a.draft, 'مسودة غير مرسلة');
      expect(b.draft, isEmpty);
      await tester.tap(find.byTooltip('إدارة المحادثة'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'حظر محلياً');
      await tapVisible(tester, 'حظر');
      expect(s.blockedParticipants, contains(a.participantId));
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'إرسال رسالة تجريبية',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('إدارة المحادثة'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'إلغاء الحظر المحلي');
      await tapVisible(tester, 'إلغاء الحظر');
      await tester.tap(find.byTooltip('إرسال رسالة تجريبية'));
      await tester.pumpAndSettle();
      expect(a.messages.last.text, 'مسودة غير مرسلة');
      expect(a.draft, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reset cancellation retains data; confirmation clears only local demo state',
    (tester) async {
      final s = ready()
        ..publish(own('keep'))
        ..toggleFavorite('b1');
      await page(tester, s, const LocalDataPage());
      await tester.scrollUntilVisible(
        find.text('إعادة تعيين بيانات العرض المحلية'),
        300,
      );
      await tapVisible(tester, 'إعادة تعيين بيانات العرض المحلية');
      await tapVisible(tester, 'إلغاء');
      expect(s.ownListings.single.id, 'keep');
      expect(s.favorites, {'b1'});
      await tapVisible(tester, 'إعادة تعيين بيانات العرض المحلية');
      await tapVisible(tester, 'إعادة تعيين الكل محلياً');
      expect(s.ownListings, isEmpty);
      expect(s.favorites, isEmpty);
      expect(s.signedIn, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'recovery screen explains there is no password storage or email delivery',
    (tester) async {
      await page(tester, ready(), const AuthPage());
      await tapVisible(tester, 'نسيت كلمة المرور؟');
      expect(find.byType(RecoveryPage), findsOneWidget);
      expect(find.text('لا تُحفَظ أي كلمة مرور حقيقية'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  final screens = <String, Widget>{
    'draft editor': const ListingEditor(),
    'inventory': const OwnListingsPage(),
    'collections': const Scaffold(body: FavoritesPage()),
    'account': const Scaffold(body: AccountPage()),
    'notifications': const NotificationsPage(),
    'notification preferences': const NotificationPreferencesPage(),
    'recent': const RecentPage(),
    'local data': const LocalDataPage(),
    'safety': const LocalSafetyPage(),
    'profile': const SelfProfilePage(),
    'settings': const SettingsPage(),
    'inbox': const Scaffold(body: MessagesPage()),
    'report': const LocalReportPage(target: 'demo'),
  };
  for (final entry in screens.entries) {
    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${entry.key} remains usable at 320px in $theme', (
        tester,
      ) async {
        final s = ready()
          ..setTheme(theme)
          ..publish(own('one'))
          ..seedConversations()
          ..seedNotice();
        s.saveDraft(
          ListingDraft(id: 'pending', values: {'title': 'إعلان غير مكتمل'}),
        );
        await page(tester, s, entry.value, width: 320);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await s.flush();
        s.dispose();
      });
    }
  }
}
