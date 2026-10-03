import 'package:advertising/data/demo_store.dart';
import 'package:advertising/app.dart';
import 'package:advertising/features/account.dart';
import 'package:advertising/features/discovery.dart';
import 'package:advertising/features/filters.dart';
import 'package:advertising/features/listing.dart';
import 'package:advertising/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_fonts.dart';

void main() {
  setUpAll(loadTestFonts);
  final pages = <String, Widget Function(DemoStore)>{
    'home': (_) => const MarketplaceShell(),
    'search': (store) {
      store.search('Fahrrad');
      return const SearchPage();
    },
    'filters': (store) => FiltersPage(
      initial: SearchFilters(
        city: 'Berlin',
        minimum: 50,
        maximum: 200,
        category: 'Fahrräder & Zubehör',
      ),
    ),
    'guest': (_) => const GuestPage(),
    'listing': (_) => ListingPage(listing: listings.first),
  };
  for (final entry in pages.entries) {
    testWidgets('${entry.key} visual baseline', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = DemoStore()..acceptConsent();
      final page = entry.value(store);
      await tester.pumpWidget(
        DemoScope(
          store: store,
          child: MaterialApp(
            theme: Brand.theme(Brightness.light),
            home: RepaintBoundary(
              key: const ValueKey('screen'),
              child: Scaffold(body: SafeArea(child: page)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byKey(const ValueKey('screen')));
        for (final name in [
          'bike',
          'bike_city',
          'bike_road',
          'sofa',
          'camera',
          'plant',
          'books',
        ]) {
          await precacheImage(AssetImage('assets/images/$name.jpg'), context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('screen')),
        matchesGoldenFile('goldens/${entry.key}.png'),
      );
    });
  }
}
