import 'package:advertising/data/demo_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('fictional catalogue has unique IDs and bundled photos', () {
    expect(listings.map((l) => l.id).toSet().length, listings.length);
    expect(listings.every((l) => l.price >= 0 && l.gallery.isNotEmpty), isTrue);
  });
  test('search is Arabic tolerant and matches bike fixtures', () {
    final store = DemoStore()..search('دراجة');
    expect(store.results().length, 8);
    expect(
      store.results().every((l) => l.category == 'دراجات وملحقات'),
      isTrue,
    );
    store.search('دراجه');
    expect(store.results().length, 8);
    store.search('كلمة-بحث-غير-موجودة');
    expect(store.results(), isEmpty);
  });
  test('price, city, radius and category combine without losing price', () {
    final store = DemoStore()..search('دراجة');
    store.changeFilters(
      SearchFilters(
        city: 'دمشق',
        radius: 15,
        minimum: 500000,
        maximum: 1500000,
      ),
    );
    expect(store.results().map((l) => l.id).toSet(), {
      'b1',
      'b2',
      'b4',
      'b6',
      'b8',
    });
    store.changeFilters(store.filters.copy()..category = 'دراجات وملحقات');
    expect(store.filters.maximum, 1500000);
    expect(store.results().length, 5);
    store.changeFilters(store.filters.copy()..radius = 3);
    expect(store.results().single.id, 'b2');
  });
  test('Aleppo radius is relative to the listing city', () {
    final store = DemoStore();
    store.changeFilters(SearchFilters(city: 'حلب', radius: 15));
    expect(store.results().single.id, 'b5');
  });
  test('15 percent budget allowance expands the upper bound', () {
    final f = SearchFilters(maximum: 1300000);
    expect(f.accepts(listings.first), isFalse);
    f.extraBudget = true;
    expect(f.accepts(listings.first), isTrue);
  });
  test('price sorting and newest sorting use real fields', () {
    final store = DemoStore();
    for (final sort in ['الأقل سعراً', 'الأعلى سعراً']) {
      store.changeFilters(SearchFilters(sort: sort));
      final prices = store.results().map((l) => l.price).toList();
      for (var i = 1; i < prices.length; i++) {
        expect(
          sort == 'الأقل سعراً'
              ? prices[i] >= prices[i - 1]
              : prices[i] <= prices[i - 1],
          isTrue,
        );
      }
    }
    store.changeFilters(SearchFilters(sort: 'الأحدث'));
    expect(store.results().first.ageHours, 1);
    store.publish(
      const Listing(
        id: 'new',
        title: 'إعلان جديد',
        price: 10,
        image: 'sofa',
        category: 'المنزل والحديقة',
        ageHours: 0,
      ),
    );
    expect(store.results().first.id, 'new');
  });
  test('bicycle type, kind and condition are independently functional', () {
    final store = DemoStore();
    store.changeFilters(
      SearchFilters(
        category: 'دراجات وملحقات',
        type: 'دراجات مدينة',
        kind: 'نسائي',
        condition: 'جيد',
      ),
    );
    expect(store.results().single.id, 'b6');
  });
  test('delivery provider only includes matching shippable listings', () {
    final store = DemoStore();
    for (final carrier in ['DHL', 'Hermes', 'DPD']) {
      store.changeFilters(SearchFilters(carrier: carrier));
      expect(store.results(), isNotEmpty);
      expect(
        store.results().every((l) => l.shipping && l.carrier == carrier),
        isTrue,
      );
    }
    store.changeFilters(SearchFilters(shipping: 'استلام شخصي فقط'));
    expect(store.results().every((l) => !l.shipping), isTrue);
  });
  test('commercial, wanted and direct purchase filters combine', () {
    final store = DemoStore();
    store.changeFilters(SearchFilters(seller: 'تجاري', direct: true));
    expect(store.results().single.id, 'b7');
    store.changeFilters(SearchFilters(offer: 'طلبات'));
    expect(store.results().single.id, 'b8');
  });
  test('draft filters do not mutate live state', () {
    final store = DemoStore();
    final draft = store.filters.copy()..maximum = 100;
    expect(store.filters.maximum, isNull);
    store.changeFilters(draft);
    draft.maximum = 300;
    expect(store.filters.maximum, 100);
  });
  test('saved searches retain and restore the complete filter snapshot', () {
    final store = DemoStore()..search('دراجة');
    store.changeFilters(
      SearchFilters(
        city: 'دمشق',
        category: 'دراجات وملحقات',
        minimum: 500000,
        maximum: 1500000,
        type: 'دراجات مدينة',
        sort: 'الأقل سعراً',
        direct: true,
      ),
    );
    final expected = store.filters.toJson();
    store.saveSearch();
    store.saveSearch();
    expect(store.savedSearches.length, 1);
    store.search('أريكة');
    store.changeFilters(SearchFilters());
    store.restoreSearch(store.savedSearches.single);
    expect(store.query, 'دراجة');
    expect(store.filters.toJson(), expected);
  });
  test(
    'theme, favorites, consent and saved searches persist locally',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = DemoStore(preferences: prefs);
      store.setTheme(ThemeMode.dark);
      store.toggleFavorite('b1');
      store.acceptConsent();
      store.setPrivacy(personalized: true, analytics: false);
      store.search('دراجة');
      store.saveSearch();
      await store.flush();
      final restored = DemoStore(preferences: prefs);
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.favorites, {'b1'});
      expect(restored.consentAccepted, isTrue);
      expect(restored.personalized, isTrue);
      expect(restored.analytics, isFalse);
      expect(restored.savedSearches.single.query, 'دراجة');
      expect(restored.signedIn, isFalse);
      expect(
        prefs.getKeys().any(
          (k) => k.contains('password') || k.contains('email'),
        ),
        isFalse,
      );
    },
  );
  test('corrupt saved searches do not break startup', () async {
    SharedPreferences.setMockInitialValues({
      'saved_searches': ['not-json', '{"query":12}', '{"filters":false}'],
    });
    final store = DemoStore(preferences: await SharedPreferences.getInstance());
    expect(store.savedSearches, isEmpty);
  });
  test('guest session signs out and clears message state', () {
    final store = DemoStore()..signIn();
    store.addMessage('b1', 'مرحباً');
    store.changeTab(3);
    store.signOut();
    expect(store.signedIn, isFalse);
    expect(store.selectedTab, 0);
    expect(store.messages, isEmpty);
  });
  test('search history deduplicates and can be cleared', () {
    final store = DemoStore()
      ..search('دراجة')
      ..search('أريكة')
      ..search('دراجة');
    expect(store.searchHistory, ['دراجة', 'أريكة']);
    store.clearHistory();
    expect(store.searchHistory, isEmpty);
  });
  test('messages stay isolated per listing and ignore empty sends', () {
    final store = DemoStore()..signIn();
    store.addMessage('b1', 'رسالة دراجة');
    store.addMessage('c1', 'رسالة سيارة');
    store.addMessage('b1', '  ');
    expect(store.messagesFor('b1'), ['رسالة دراجة']);
    expect(store.messagesFor('c1'), ['رسالة سيارة']);
    expect(store.messagesFor('s1'), isEmpty);
    expect(store.messages.length, 2);
  });
}
