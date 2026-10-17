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
  await tapVisible(tester, 'Einloggen');
  await tester.enterText(find.byType(TextFormField).first, 'demo@example.test');
  await tapVisible(tester, 'Weiter');
  await tester.enterText(find.byType(TextFormField).at(1), 'fiktiv-12345');
  final login = find.widgetWithText(FilledButton, 'Einloggen');
  await tester.ensureVisible(login);
  await tester.tap(login);
  await tester.pumpAndSettle();
  expect(find.text('Bitte eine gültige E-Mail eingeben'), findsNothing);
  expect(find.text('Mindestens 8 Zeichen verwenden'), findsNothing);
}

Listing own(String id) => Listing(
  id: id,
  title: 'Mein lokales Sofa',
  price: 90,
  image: 'sofa',
  category: 'Haus & Garten',
  description: 'Eine ausreichend lange lokale Beschreibung.',
);
void main() {
  setUpAll(loadTestFonts);
  for (final choice in [
    'Entwurf speichern',
    'Verwerfen',
    'Weiter bearbeiten',
  ]) {
    testWidgets('root editor Android back safely handles $choice', (
      tester,
    ) async {
      MediaRepository.instance = MediaRepository(MemoryMediaStorage());
      final s = ready()..changeTab(2);
      await page(tester, s, const Scaffold());
      await tester.pumpWidget(MarketplaceApp(store: s));
      await tester.pumpAndSettle();
      await tester.enterText(field('Titel'), 'Android Durable Draft');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Änderungen behalten?'), findsOneWidget);
      await tapVisible(tester, choice);
      expect(find.byType(MarketplaceShell), findsOneWidget);
      expect(s.selectedTab, choice == 'Weiter bearbeiten' ? 2 : 4);
      if (choice == 'Entwurf speichern') {
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
      find.text('Nachrichten'),
    );
    final lines = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 11),
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
      await tester.tap(find.byTooltip('Benachrichtigungen'));
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
      await tester.tap(find.text('Nachricht'));
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
      await tester.enterText(field('Lokaler Profilname'), 'Lokal Team');
      await tapVisible(tester, 'Gewerblich');
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tapVisible(tester, 'Registrieren');
      await s.flush();
      expect(s.name, 'Lokal Team');
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
      await tester.enterText(field('Titel'), 'Ein lokaler Entwurf');
      await tester.tap(find.text('Meins'));
      await tester.pumpAndSettle();
      expect(find.text('Änderungen behalten?'), findsOneWidget);
      await tapVisible(tester, 'Weiter bearbeiten');
      expect(s.selectedTab, 2);
      await tester.tap(find.text('Meins'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Entwurf speichern');
      expect(s.selectedTab, 4);
      await s.flush();
      final restored = DemoStore(preferences: p)
        ..acceptConsent()
        ..signIn();
      expect(restored.drafts.single.values['title'], 'Ein lokaler Entwurf');
      await page(
        tester,
        restored,
        ListingEditor(draft: restored.drafts.single),
      );
      await tester.enterText(field('Preis'), '123,45');
      await tester.enterText(
        field('Beschreibung'),
        'Nur lokal, eine vollständige Beschreibung.',
      );
      await tapVisible(tester, 'Vorschau');
      expect(find.byType(ListingPreviewPage), findsOneWidget);
      expect(restored.ownListings, isEmpty);
      await tapVisible(tester, 'Weiter bearbeiten');
      expect(restored.ownListings, isEmpty);
      expect(field('Titel'), findsOneWidget);
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
      await tester.enterText(field('Titel'), 'Bearbeitetes lokales Sofa');
      await tapVisible(tester, 'Vorschau');
      expect(s.findListing('own')!.title, 'Mein lokales Sofa');
      await tapVisible(tester, 'Änderungen lokal speichern');
      expect(s.ownListings.single.id, 'own');
      expect(s.ownListings.single.title, 'Bearbeitetes lokales Sofa');
      final value = s.ownListings.single;
      await page(tester, s, ListingPage(listing: value));
      s.deleteListing('own');
      await tester.pumpAndSettle();
      expect(find.text('Anzeige nicht verfügbar'), findsOneWidget);
      expect(find.text('Nachricht'), findsNothing);
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
      s.sendMessage(a.id, 'Nur im ersten Thread', incoming: true);
      s.sendMessage(b.id, 'Nur im zweiten Thread', incoming: true);
      await page(tester, s, MessagePage(threadId: a.id));
      expect(a.unread, 0);
      expect(b.unread, 1);
      expect(find.text('Nur im ersten Thread'), findsOneWidget);
      expect(find.text('Nur im zweiten Thread'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Ungesendeter Entwurf');
      expect(a.draft, 'Ungesendeter Entwurf');
      expect(b.draft, isEmpty);
      await tester.tap(find.byTooltip('Gespräch verwalten'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Lokal blockieren');
      await tapVisible(tester, 'Blockieren');
      expect(s.blockedParticipants, contains(a.participantId));
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Demo-Nachricht senden',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Gespräch verwalten'));
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Lokal entsperren');
      await tapVisible(tester, 'Entsperren');
      await tester.tap(find.byTooltip('Demo-Nachricht senden'));
      await tester.pumpAndSettle();
      expect(a.messages.last.text, 'Ungesendeter Entwurf');
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
      await tapVisible(tester, 'Lokale Demo-Daten zurücksetzen');
      await tapVisible(tester, 'Abbrechen');
      expect(s.ownListings.single.id, 'keep');
      expect(s.favorites, {'b1'});
      await tapVisible(tester, 'Lokale Demo-Daten zurücksetzen');
      await tapVisible(tester, 'Alles lokal zurücksetzen');
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
      await tapVisible(tester, 'Passwort vergessen?');
      expect(find.byType(RecoveryPage), findsOneWidget);
      expect(find.text('Kein echtes Passwort gespeichert'), findsOneWidget);
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
          ListingDraft(id: 'pending', values: {'title': 'Unfertige Anzeige'}),
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
