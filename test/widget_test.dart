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
    expect(find.text('Wie möchtest du Kleinanzeigen nutzen?'), findsOneWidget);
    await tester.tap(find.text('Alle ablehnen und fortfahren'));
    await tester.pumpAndSettle();
    for (final tab in [
      'Suchen',
      'Favoriten',
      'Inserieren',
      'Nachrichten',
      'Meins',
    ]) {
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
      await tester.tap(find.text('Favoriten'));
      await tester.pumpAndSettle();
      expect(find.text('All deine Lieblinge auf einen Blick'), findsOneWidget);
      await tester.tap(find.text('Registrieren'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'demo@example.test',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'demo-only-password',
      );
      await tester.ensureVisible(find.text('Registrieren'));
      await tester.tap(find.text('Registrieren'));
      await tester.pumpAndSettle();
      expect(store.signedIn, isTrue);
      expect(store.selectedTab, 1);
      expect(find.text('Merkliste'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'search, nested price and category preserve filters and show matching results',
    (tester) async {
      final store = readyStore();
      await start(tester, store);
      await tester.tap(find.text('Suche in ganz Deutschland'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Fahrrad');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('8 Ergebnisse'), findsOneWidget);
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preis'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '50');
      await tester.enterText(find.byType(TextFormField).at(1), '200');
      await tester.tap(find.text('Ergebnisse anzeigen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kategorie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auto, Rad & Boot'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fahrräder & Zubehör'));
      await tester.pumpAndSettle();
      expect(find.text('50–200 €'), findsOneWidget);
      await tester.tap(find.text('5 Ergebnisse anzeigen'));
      await tester.pumpAndSettle();
      expect(store.filters.maximum, 200);
      expect(store.filters.category, 'Fahrräder & Zubehör');
      expect(find.text('5 Ergebnisse'), findsOneWidget);
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
      await tester.tap(find.text('Preis'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '200');
      await tester.enterText(find.byType(TextFormField).at(1), '50');
      await tester.tap(find.text('Ergebnisse anzeigen'));
      await tester.pumpAndSettle();
      expect(find.text('Minimum liegt über Maximum'), findsWidgets);
      await tester.tap(find.byTooltip('Schließen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Zurück'));
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
    await tester.tap(find.text('Meins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HILFE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Design'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dunkles Design'));
    await tester.pumpAndSettle();
    expect(store.themeMode, ThemeMode.dark);
    expect(find.text('Helles Design'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Design'))).brightness,
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
    await tester.tap(find.byTooltip('Nächstes Foto'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.tap(find.byTooltip('Galerie schließen'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Alle Anzeigen von Lena'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Alle Anzeigen von Lena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Über'));
    await tester.pumpAndSettle();
    expect(find.text('Unternehmensbeschreibung'), findsOneWidget);
    await tester.tap(find.text('Kontakt'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Musterstraße 12'), findsOneWidget);
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
      'Hallo, ist das Fahrrad noch da?',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Demo-Nachricht senden'));
    await tester.pumpAndSettle();
    expect(store.messagesFor('b1'), ['Hallo, ist das Fahrrad noch da?']);
    expect(find.text('Hallo, ist das Fahrrad noch da?'), findsOneWidget);
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
        'Test Sofa zu verkaufen',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '55,50');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Eine lokale Testanzeige ohne echtes Inserieren.',
      );
      await tester.ensureVisible(find.text('Lokal veröffentlichen'));
      await tester.tap(find.text('Lokal veröffentlichen'));
      await tester.pumpAndSettle();
      expect(store.ownListings.single.title, 'Test Sofa zu verkaufen');
      expect(store.ownListings.single.price, 55.5);
      expect(store.ownListings.single.ageHours, 0);
      expect(store.selectedTab, 4);
      await tester.tap(find.text('Meine Anzeigen'));
      await tester.pumpAndSettle();
      expect(find.text('Test Sofa zu verkaufen'), findsOneWidget);
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

  final screens = <String, Widget Function()>{
    'home': () => const HomePage(),
    'search': () => const SearchPage(),
    'filters': () => FiltersPage(initial: SearchFilters()),
    'categories': () => const CategoryPage(),
    'bicycle categories': () => const CategoryPage(parent: 'Auto, Rad & Boot'),
    'sort': () => const OptionPage(
      title: 'Sortierung',
      selected: 'Empfohlen',
      options: ['Empfohlen', 'Neueste', 'Niedrigster Preis', 'Höchster Preis'],
    ),
    'location': () => LocationPage(initial: SearchFilters(city: 'Berlin')),
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
    'help articles': () => const HelpTopicPage(topic: 'Anzeigen'),
    'resolution error': () => const ErrorPage(),
    'privacy policy': () => const LegalPage(kind: 'Datenschutzerklärung'),
    'terms': () => const LegalPage(kind: 'Messaging-Nutzungsbedingungen'),
    'imprint': () => const LegalPage(kind: 'Impressum'),
    'copyright': () => const LegalPage(kind: 'Copyright'),
    'web consent': () => const WebConsentPage(title: 'Karriereseite'),
    'favorites': () => const FavoritesPage(),
    'account': () => const AccountPage(),
    'messages': () => const MessagesPage(),
    'create': () => const NewListingPage(),
    'notifications': () => const NotificationsPage(),
    'feedback': () => const FeedbackPage(title: 'Gib uns Feedback'),
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
