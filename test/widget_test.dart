import 'package:advertising/app.dart';
import 'package:advertising/data/demo_store.dart';
import 'package:advertising/features/account.dart';
import 'package:advertising/features/discovery.dart';
import 'package:advertising/features/filters.dart';
import 'package:advertising/features/listing.dart';
import 'package:advertising/features/settings.dart';
import 'package:advertising/ui/theme.dart';
import 'package:advertising/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_fonts.dart';

Future<void> phoneSize(
  WidgetTester tester, {
  Size size = const Size(393, 852),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

DemoStore readyStore() => DemoStore()..acceptConsent();
Future<void> start(WidgetTester tester, DemoStore store) async {
  await phoneSize(tester);
  await tester.pumpWidget(MarketplaceApp(store: store));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadTestFonts);
  testWidgets('first launch consent enters the five-tab marketplace', (
    tester,
  ) async {
    final store = DemoStore();
    await start(tester, store);
    expect(find.text('كيف تريد استخدام سوقنا؟'), findsOneWidget);
    await tester.tap(find.text('رفض الكل والمتابعة'));
    await tester.pumpAndSettle();
    for (final tab in ['بحث', 'المفضلة', 'أضف إعلانًا', 'الرسائل', 'حسابي']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(store.analytics, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'guest favorite gate and registration create only a demo session',
    (tester) async {
      final store = readyStore();
      await start(tester, store);
      await tester.tap(find.text('المفضلة'));
      await tester.pumpAndSettle();
      expect(find.text('كل مفضّلاتك بلمحة واحدة'), findsOneWidget);
      await tester.tap(find.text('إنشاء حساب'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'demo@example.test',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'demo-only-password',
      );
      await tester.ensureVisible(find.text('إنشاء حساب'));
      await tester.tap(find.text('إنشاء حساب'));
      await tester.pumpAndSettle();
      expect(store.signedIn, isTrue);
      expect(store.selectedTab, 1);
      expect(find.text('البحوث المحفوظة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'search, nested price and category preserve filters and show matching results',
    (tester) async {
      final store = readyStore();
      await start(tester, store);
      await tester.tap(find.text('ابحث في كل سوريا'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'دراجة');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('8 نتيجة'), findsOneWidget);
      await tester.tap(find.text('الفلاتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('السعر'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '500000');
      await tester.enterText(find.byType(TextFormField).at(1), '1500000');
      await tester.tap(find.text('عرض النتائج'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('القسم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('سيارات ودراجات وقوارب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('دراجات وملحقات'));
      await tester.pumpAndSettle();
      expect(find.text('500,000–1,500,000 ل.س'), findsOneWidget);
      await tester.tap(find.text('عرض 5 نتيجة'));
      await tester.pumpAndSettle();
      expect(store.filters.maximum, 1500000);
      expect(store.filters.category, 'دراجات وملحقات');
      expect(find.text('5 نتيجة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'invalid price is rejected and canceled filter edits stay unapplied',
    (tester) async {
      final store = readyStore();
      await phoneSize(tester);
      await tester.pumpWidget(
        DemoScope(
          store: store,
          child: MaterialApp(
            theme: Brand.theme(Brightness.light),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FiltersPage(initial: store.filters),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('السعر'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '200');
      await tester.enterText(find.byType(TextFormField).at(1), '50');
      await tester.tap(find.text('عرض النتائج'));
      await tester.pumpAndSettle();
      expect(find.text('الحد الأدنى أكبر من الحد الأعلى'), findsWidgets);
      await tester.tap(find.byTooltip('إغلاق'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('رجوع'));
      await tester.pumpAndSettle();
      expect(store.filters.minimum, isNull);
      expect(store.filters.maximum, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('theme switches in place without resetting navigation', (
    tester,
  ) async {
    final store = readyStore();
    await start(tester, store);
    await tester.tap(find.text('حسابي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مساعدة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المظهر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مظهر داكن'));
    await tester.pumpAndSettle();
    expect(store.themeMode, ThemeMode.dark);
    expect(find.text('مظهر فاتح'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('المظهر'))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('gallery advances and seller tabs are navigable', (tester) async {
    final store = readyStore();
    await phoneSize(tester);
    await tester.pumpWidget(
      DemoScope(
        store: store,
        child: MaterialApp(
          theme: Brand.theme(Brightness.light),
          home: ListingPage(listing: listings.first),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProductImage).first);
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
    await tester.tap(find.byTooltip('الصورة التالية'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.tap(find.byTooltip('إغلاق المعرض'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('كل إعلانات لينا'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('كل إعلانات لينا'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نبذة'));
    await tester.pumpAndSettle();
    expect(find.text('وصف النشاط التجاري'), findsOneWidget);
    await tester.tap(find.text('التواصل'));
    await tester.pumpAndSettle();
    expect(find.textContaining('شارع المثال 12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('chat sends a local message without a backend', (tester) async {
    final store = readyStore()..signIn();
    await phoneSize(tester);
    await tester.pumpWidget(
      DemoScope(
        store: store,
        child: MaterialApp(
          theme: Brand.theme(Brightness.light),
          home: MessagePage(listing: listings.first),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'مرحباً، هل الدراجة ما زالت متوفرة؟',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('إرسال رسالة تجريبية'));
    await tester.pumpAndSettle();
    expect(store.messagesFor('b1'), ['مرحباً، هل الدراجة ما زالت متوفرة؟']);
    expect(find.text('مرحباً، هل الدراجة ما زالت متوفرة؟'), findsOneWidget);
  });

  testWidgets(
    'creating an ad publishes only locally and opens the demo account',
    (tester) async {
      final store = readyStore()
        ..signIn()
        ..changeTab(2);
      await start(tester, store);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'كنبة تجريبية للبيع',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '55,50');
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'إعلان تجريبي محلي دون نشر حقيقي.',
      );
      await tester.ensureVisible(find.text('معاينة'));
      await tester.tap(find.text('معاينة'));
      await tester.pumpAndSettle();
      expect(store.ownListings, isEmpty);
      await tester.ensureVisible(find.text('نشر محلياً'));
      await tester.tap(find.text('نشر محلياً'));
      await tester.pumpAndSettle();
      expect(store.ownListings.single.title, 'كنبة تجريبية للبيع');
      expect(store.ownListings.single.price, 55.5);
      expect(store.ownListings.single.ageHours, 0);
      expect(store.selectedTab, 4);
      await tester.tap(find.text('إعلاناتي'));
      await tester.pumpAndSettle();
      expect(find.text('كنبة تجريبية للبيع'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inbox opens the correct listing without leaking another thread',
    (tester) async {
      final store = readyStore()
        ..signIn()
        ..changeTab(3);
      final car = listings.firstWhere((listing) => listing.id == 'c1');
      store.addMessage('b1', 'Fahrrad-Nachricht');
      store.addMessage(car.id, 'Auto-Nachricht');
      await start(tester, store);
      await tester.tap(find.textContaining(car.title));
      await tester.pumpAndSettle();
      expect(find.text('Auto-Nachricht'), findsOneWidget);
      expect(find.text('Fahrrad-Nachricht'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'non-bike details show category instead of bicycle-specific kind',
    (tester) async {
      await phoneSize(tester);
      final sofa = listings.firstWhere((listing) => listing.id == 's1');
      await tester.pumpWidget(
        DemoScope(
          store: readyStore(),
          child: MaterialApp(
            theme: Brand.theme(Brightness.light),
            home: ListingPage(listing: sofa),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('القسم'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('للجنسين'), findsNothing);
      expect(find.text('القسم'), findsOneWidget);
      expect(find.text('المنزل والحديقة'), findsOneWidget);
      expect(sofa.title, contains('أخضر'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('invalid price messages wrap on a narrow phone', (tester) async {
    await phoneSize(tester, size: const Size(320, 640));
    await tester.pumpWidget(
      MaterialApp(
        theme: Brand.theme(Brightness.light),
        home: Scaffold(body: PriceSheet(initial: SearchFilters())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '200');
    await tester.enterText(find.byType(TextFormField).at(1), '50');
    await tester.tap(find.text('عرض النتائج'));
    await tester.pumpAndSettle();
    final errors = find.text('الحد الأدنى أكبر من الحد الأعلى');
    expect(errors, findsNWidgets(2));
    for (final error in tester.widgetList<Text>(errors)) {
      expect(error.maxLines, 3);
    }
    expect(tester.takeException(), isNull);
  });

  for (final tab in <int?>[null, 0, 1, 2, 3, 4]) {
    for (final signedIn in [false, true]) {
      testWidgets(
        'home error ${tab == null ? 'retry' : 'tab $tab'} returns to marketplace root (signed in: $signedIn)',
        (tester) async {
          final store = readyStore();
          store.signedIn = signedIn;
          await start(tester, store);
          await tester.tap(find.text('حسابي'));
          await tester.pumpAndSettle();
          await tester.tap(
            signedIn ? find.byTooltip('الإعدادات') : find.text('مساعدة'),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('حول هذا العرض التجريبي'),
            300,
          );
          await tester.tap(find.text('حول هذا العرض التجريبي'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('الصفحة الرئيسية في حالة خطأ'));
          await tester.pumpAndSettle();
          expect(find.byType(ErrorPage), findsOneWidget);
          await tester.tap(
            tab == null
                ? find.text('إعادة المحاولة')
                : find.descendant(
                    of: find.byType(BottomTabs),
                    matching: find.text(
                      [
                        'بحث',
                        'المفضلة',
                        'أضف إعلانًا',
                        'الرسائل',
                        'حسابي',
                      ][tab],
                    ),
                  ),
          );
          await tester.pumpAndSettle();
          expect(store.selectedTab, signedIn ? tab ?? 0 : 0);
          expect(find.byType(ErrorPage), findsNothing);
          expect(find.byType(DemoInfoPage), findsNothing);
          expect(find.byType(SettingsPage), findsNothing);
          if (tab == null || tab == 0) {
            expect(find.byType(HomePage), findsOneWidget);
          } else {
            if (signedIn) {
              expect(
                find.byType(
                  [
                    HomePage,
                    FavoritesPage,
                    NewListingPage,
                    MessagesPage,
                    AccountPage,
                  ][tab],
                ),
                findsOneWidget,
              );
            } else {
              expect(find.byType(GuestPage), findsOneWidget);
              expect(
                tester.widget<GuestPage>(find.byType(GuestPage)).variant,
                [1, 0, 3, 2, 1][tab],
              );
            }
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  final screens = <String, Widget Function()>{
    'home': () => const HomePage(),
    'search': () => const SearchPage(),
    'filters': () => FiltersPage(initial: SearchFilters()),
    'categories': () => const CategoryPage(),
    'bicycle categories': () =>
        const CategoryPage(parent: 'سيارات ودراجات وقوارب'),
    'sort': () => const OptionPage(
      title: 'الترتيب',
      selected: 'مقترح',
      options: ['مقترح', 'الأحدث', 'الأقل سعراً', 'الأعلى سعراً'],
    ),
    'location': () => LocationPage(initial: SearchFilters(city: 'دمشق')),
    'guest': () => const GuestPage(),
    'login': () => const AuthPage(),
    'register': () => const AuthPage(register: true),
    'listing': () => ListingPage(listing: listings.first),
    'gallery': () => GalleryPage(listing: listings.first),
    'seller': () => SellerPage(listing: listings.first),
    'settings': () => const SettingsPage(),
    'privacy': () => const PrivacyPage(),
    'consent': () => const ConsentSettingsPage(),
    'design': () => const DesignPage(),
    'about': () => const AboutPage(),
    'help menu': () => const HelpMenuPage(),
    'help center': () => const HelpCenterPage(),
    'help articles': () => const HelpTopicPage(topic: 'الإعلانات'),
    'resolution error': () => const ErrorPage(),
    'privacy policy': () => const LegalPage(kind: 'Datenschutzerklärung'),
    'terms': () => const LegalPage(kind: 'Messaging-Nutzungsbedingungen'),
    'imprint': () => const LegalPage(kind: 'Impressum'),
    'copyright': () => const LegalPage(kind: 'Copyright'),
    'web consent': () => const WebConsentPage(title: 'الوظائف'),
    'favorites': () => const FavoritesPage(),
    'account': () => const AccountPage(),
    'messages': () => const MessagesPage(),
    'create': () => const NewListingPage(),
    'notifications': () => const NotificationsPage(),
    'feedback': () => const FeedbackPage(title: 'أرسل ملاحظاتك'),
    'own listings': () => const OwnListingsPage(),
    'demo info': () => const DemoInfoPage(),
    'pur': () => const PurPage(),
  };
  for (final size in [const Size(393, 852), const Size(320, 640)]) {
    for (final screen in screens.entries) {
      testWidgets(
        '${screen.key} renders without layout exceptions at ${size.width.toInt()}px',
        (tester) async {
          await phoneSize(tester, size: size);
          final store = readyStore()..signIn();
          await tester.pumpWidget(
            DemoScope(
              store: store,
              child: MaterialApp(
                theme: Brand.theme(Brightness.light),
                home: Scaffold(body: SafeArea(child: screen.value())),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
