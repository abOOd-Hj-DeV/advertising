import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.category,
    this.city = 'Berlin',
    this.district = 'Prenzlauer Berg',
    this.distance = 4,
    this.type = 'Cityräder',
    this.kind = 'Unisex',
    this.carrier = 'DHL',
    this.ageHours = 2,
    this.condition = 'Sehr gut',
    this.shipping = true,
    this.direct = false,
    this.commercial = false,
    this.wanted = false,
    this.featured = false,
    this.seller = 'Lena',
    this.date = 'Heute, 10:42',
    this.images = const [],
    this.description =
        'Gut erhalten und bereit für ein neues Zuhause. '
        'Wir geben diesen schönen Artikel ab, weil wir Platz schaffen möchten. '
        'Bei Fragen melde dich gerne. Abholung nach Vereinbarung. '
        'Dies ist eine fiktive Anzeige für die lokale UI-Demo.',
  });
  final String id,
      title,
      image,
      category,
      city,
      district,
      type,
      kind,
      carrier,
      condition,
      seller,
      date,
      description;
  final double price, distance;
  final int ageHours;
  final bool shipping, direct, commercial, wanted, featured;
  final List<String> images;
  List<String> get gallery => images.isEmpty ? [image] : images;
  String get formattedPrice =>
      '${price.toStringAsFixed(price % 1 == 0 ? 0 : 2).replaceAll('.', ',')} €';
}

const listings = <Listing>[
  Listing(
    id: 'b1',
    title: 'Citybike – leicht, gepflegt und sofort startklar',
    price: 180,
    image: 'bike_city',
    category: 'Fahrräder & Zubehör',
    direct: true,
    kind: 'Damen',
    ageHours: 1,
    featured: true,
    images: ['bike_city', 'bike', 'bike_road'],
  ),
  Listing(
    id: 'b2',
    title: 'Klassisches Fahrrad mit 7 Gängen',
    price: 95,
    image: 'bike',
    category: 'Fahrräder & Zubehör',
    district: 'Mitte',
    distance: 2,
    seller: 'Paul',
    condition: 'Gut',
    kind: 'Herren',
    carrier: 'Hermes',
    ageHours: 6,
    images: ['bike', 'bike_city'],
  ),
  Listing(
    id: 'b3',
    title: 'Trekkingrad für Stadt und kleine Abenteuer',
    price: 320,
    image: 'bike_road',
    category: 'Fahrräder & Zubehör',
    district: 'Kreuzberg',
    type: 'Trekkingräder',
    featured: true,
    seller: 'Mira',
    distance: 9,
    images: ['bike_road', 'bike', 'bike_city'],
  ),
  Listing(
    id: 'b4',
    title: 'Fahrrad für Kinder, guter Zustand',
    price: 70,
    image: 'bike_city',
    category: 'Fahrräder & Zubehör',
    type: 'Kinderräder',
    kind: 'Kinder',
    district: 'Pankow',
    seller: 'Jonas',
    distance: 12,
    shipping: false,
  ),
  Listing(
    id: 'b5',
    title: 'Sportliches Rennrad – neue Reifen',
    price: 550,
    image: 'bike_road',
    category: 'Fahrräder & Zubehör',
    type: 'Rennräder',
    city: 'Hamburg',
    district: 'Altona',
    distance: 3,
    seller: 'Finn',
    direct: true,
  ),
  Listing(
    id: 'b6',
    title: 'Fahrrad Retro – schönes Alltagsrad',
    price: 125,
    image: 'bike',
    category: 'Fahrräder & Zubehör',
    district: 'Charlottenburg',
    distance: 10,
    seller: 'Sophie',
    condition: 'Gut',
    kind: 'Damen',
    carrier: 'DPD',
  ),
  Listing(
    id: 'b7',
    title: 'E-Bike mit Zubehör und Rechnung',
    price: 1290,
    image: 'bike_city',
    category: 'Fahrräder & Zubehör',
    type: 'E-Bikes',
    kind: 'Herren',
    district: 'Friedrichshain',
    direct: true,
    commercial: true,
    seller: 'Radhaus Demo',
  ),
  Listing(
    id: 'b8',
    title: 'Suche Fahrrad für den Weg zur Uni',
    price: 150,
    image: 'bike',
    category: 'Fahrräder & Zubehör',
    wanted: true,
    shipping: false,
    district: 'Neukölln',
    seller: 'Alex',
    distance: 8,
  ),
  Listing(
    id: 's1',
    title: 'Gemütliches Sofa in sattem Grün',
    price: 240,
    image: 'sofa',
    type: 'Sofas & Sitzgarnituren',
    category: 'Haus & Garten',
    featured: true,
    shipping: false,
    seller: 'Lena',
    images: ['sofa', 'room'],
  ),
  Listing(
    id: 'r1',
    title: 'Helle 2-Zimmer-Wohnung mit Balkon',
    price: 850,
    image: 'room',
    category: 'Immobilien',
    district: 'Mitte',
    shipping: false,
    type: 'Mieten',
    images: ['room', 'sofa'],
    seller: 'Mira',
  ),
  Listing(
    id: 'r2',
    title: 'Stilvolles Apartment im Grünen',
    price: 265000,
    image: 'room',
    category: 'Immobilien',
    type: 'Kaufen',
    shipping: false,
    district: 'Pankow',
    distance: 12,
    seller: 'Paul',
  ),
  Listing(
    id: 'c1',
    title: 'Sportwagen – gepflegt, neue Inspektion',
    price: 23900,
    image: 'car',
    type: 'Autos',
    category: 'Auto, Rad & Boot',
    shipping: false,
    seller: 'Paul',
  ),
  Listing(
    id: 'e1',
    title: 'Spiegelreflexkamera mit Objektiv',
    price: 290,
    image: 'camera',
    type: 'Kameras',
    category: 'Elektronik',
    direct: true,
    seller: 'Jonas',
  ),
  Listing(
    id: 'e2',
    title: 'Notebook 13 Zoll – ideal fürs Studium',
    price: 420,
    image: 'laptop',
    type: 'Notebooks',
    carrier: 'DPD',
    category: 'Elektronik',
    seller: 'Mira',
  ),
  Listing(
    id: 'f1',
    title: 'Sneaker in Rot, Größe 39',
    price: 45,
    image: 'shoes',
    type: 'Schuhe',
    carrier: 'Hermes',
    category: 'Mode & Beauty',
    district: 'Kreuzberg',
    seller: 'Sophie',
  ),
  Listing(
    id: 'p1',
    title: 'Große Zimmerpflanze mit Übertopf',
    price: 25,
    image: 'plant',
    type: 'Pflanzen',
    category: 'Haus & Garten',
    shipping: false,
    seller: 'Lena',
  ),
  Listing(
    id: 'm1',
    title: 'Bücherpaket – spannende Geschichten',
    price: 20,
    image: 'books',
    type: 'Bücher',
    category: 'Musik, Filme & Bücher',
    seller: 'Finn',
  ),
  Listing(
    id: 'h1',
    title: 'Hundebetreuung am Wochenende',
    price: 30,
    image: 'dog',
    type: 'Hundebetreuung',
    category: 'Haustiere',
    shipping: false,
    seller: 'Sophie',
  ),
];

class SearchFilters {
  SearchFilters({
    this.category = 'Alle Kategorien',
    this.city = '',
    this.radius = 15,
    this.minimum,
    this.maximum,
    this.extraBudget = false,
    this.sort = 'Empfohlen',
    this.type = 'Alle',
    this.kind = 'Alle',
    this.condition = 'Alle',
    this.shipping = 'Alle',
    this.carrier = 'Alle',
    this.seller = 'Privat & Gewerblich',
    this.offer = 'Angebote & Gesuche',
    this.direct = false,
  });
  String category,
      city,
      sort,
      type,
      kind,
      condition,
      shipping,
      carrier,
      seller,
      offer;
  double radius;
  double? minimum, maximum;
  bool extraBudget, direct;
  SearchFilters copy() => SearchFilters(
    category: category,
    city: city,
    radius: radius,
    minimum: minimum,
    maximum: maximum,
    extraBudget: extraBudget,
    sort: sort,
    type: type,
    kind: kind,
    condition: condition,
    shipping: shipping,
    carrier: carrier,
    seller: seller,
    offer: offer,
    direct: direct,
  );
  bool accepts(Listing l) =>
      (category == 'Alle Kategorien' ||
          l.category == category ||
          category == 'Auto, Rad & Boot' &&
              l.category == 'Fahrräder & Zubehör') &&
      (city.isEmpty || l.city == city && l.distance <= radius) &&
      (minimum == null || l.price >= minimum!) &&
      (maximum == null || l.price <= maximum! * (extraBudget ? 1.15 : 1)) &&
      (type == 'Alle' || l.type == type) &&
      (condition == 'Alle' || l.condition == condition) &&
      (kind == 'Alle' || kind == l.kind) &&
      (shipping == 'Alle' || l.shipping == (shipping == 'Versand möglich')) &&
      (carrier == 'Alle' || l.shipping && carrier == l.carrier) &&
      (seller == 'Privat & Gewerblich' ||
          l.commercial == (seller == 'Gewerblich')) &&
      (offer == 'Angebote & Gesuche' || l.wanted == (offer == 'Gesuche')) &&
      (!direct || l.direct);
  String get locationLabel =>
      city.isEmpty ? 'Ganz Deutschland' : '$city (+${radius.round()} km)';
  String get priceLabel => minimum == null && maximum == null
      ? 'Beliebig'
      : '${minimum?.round() ?? 0}–${maximum?.round() ?? '∞'} €';
  Map<String, Object?> toJson() => {
    'category': category,
    'city': city,
    'radius': radius,
    'minimum': minimum,
    'maximum': maximum,
    'extraBudget': extraBudget,
    'sort': sort,
    'type': type,
    'kind': kind,
    'condition': condition,
    'shipping': shipping,
    'carrier': carrier,
    'seller': seller,
    'offer': offer,
    'direct': direct,
  };
  factory SearchFilters.fromJson(Map<String, dynamic> json) => SearchFilters(
    category: json['category'] as String? ?? 'Alle Kategorien',
    city: json['city'] as String? ?? '',
    radius: (json['radius'] as num?)?.toDouble() ?? 15,
    minimum: (json['minimum'] as num?)?.toDouble(),
    maximum: (json['maximum'] as num?)?.toDouble(),
    extraBudget: json['extraBudget'] as bool? ?? false,
    sort: json['sort'] as String? ?? 'Empfohlen',
    type: json['type'] as String? ?? 'Alle',
    kind: json['kind'] as String? ?? 'Alle',
    condition: json['condition'] as String? ?? 'Alle',
    shipping: json['shipping'] as String? ?? 'Alle',
    carrier: json['carrier'] as String? ?? 'Alle',
    seller: json['seller'] as String? ?? 'Privat & Gewerblich',
    offer: json['offer'] as String? ?? 'Angebote & Gesuche',
    direct: json['direct'] as bool? ?? false,
  );
}

class SavedSearch {
  SavedSearch(this.query, SearchFilters filters) : filters = filters.copy();
  final String query;
  final SearchFilters filters;
  String get label =>
      '${query.isEmpty ? 'Alle Anzeigen' : query} · ${filters.locationLabel} · ${filters.priceLabel}';
  String encode() => jsonEncode({'query': query, 'filters': filters.toJson()});
  factory SavedSearch.decode(String encoded) {
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    return SavedSearch(
      json['query'] as String,
      SearchFilters.fromJson(json['filters'] as Map<String, dynamic>),
    );
  }
}

class DemoMessage {
  const DemoMessage({required this.listingId, required this.text});
  final String listingId;
  final String text;
}

class DemoStore extends ChangeNotifier {
  DemoStore({this.preferences}) {
    final savedMode = preferences?.getString('theme');
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == savedMode,
      orElse: () => ThemeMode.system,
    );
    consentAccepted = preferences?.getBool('consent') ?? false;
    personalized = preferences?.getBool('personalized') ?? false;
    analytics = preferences?.getBool('analytics') ?? false;
    favorites.addAll(preferences?.getStringList('favorites') ?? []);
    for (final encoded
        in preferences?.getStringList('saved_searches') ?? <String>[]) {
      try {
        savedSearches.add(SavedSearch.decode(encoded));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
  }
  final SharedPreferences? preferences;
  ThemeMode themeMode = ThemeMode.system;
  bool consentAccepted = false, personalized = false, analytics = false;
  bool signedIn = false;
  String name = 'Lena Demo';
  int selectedTab = 0;
  String query = '';
  SearchFilters filters = SearchFilters();
  final Set<String> favorites = {};
  final List<SavedSearch> savedSearches = [];
  final List<String> searchHistory = [];
  final List<DemoMessage> messages = [];
  final List<Listing> ownListings = [];
  List<Listing> results({SearchFilters? using}) {
    final f = using ?? filters;
    final words = _searchText(query.trim()).split(RegExp(r'\s+'));
    final result = [...ownListings, ...listings]
        .where(
          (l) =>
              f.accepts(l) &&
              words.every(
                (w) => _searchText(
                  '${l.title} ${l.category} ${l.description}',
                ).contains(w),
              ),
        )
        .toList();
    switch (f.sort) {
      case 'Niedrigster Preis':
        result.sort((a, b) => a.price.compareTo(b.price));
      case 'Höchster Preis':
        result.sort((a, b) => b.price.compareTo(a.price));
      case 'Neueste':
        result.sort((a, b) => a.ageHours.compareTo(b.ageHours));
      default:
        result.sort(
          (a, b) => (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0),
        );
    }
    return result;
  }

  void changeFilters(SearchFilters value) {
    filters = value.copy();
    notifyListeners();
  }

  void search(String value) {
    query = value.trim();
    if (query.isNotEmpty) {
      searchHistory.remove(query);
      searchHistory.insert(0, query);
    }
    notifyListeners();
  }

  void changeTab(int value) {
    selectedTab = value;
    notifyListeners();
  }

  void toggleFavorite(String id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    preferences?.setStringList('favorites', favorites.toList());
    notifyListeners();
  }

  void saveSearch() {
    final saved = SavedSearch(query, filters);
    if (!savedSearches.any((s) => s.encode() == saved.encode())) {
      savedSearches.insert(0, saved);
    }
    preferences?.setStringList(
      'saved_searches',
      savedSearches.map((s) => s.encode()).toList(),
    );
    notifyListeners();
  }

  void restoreSearch(SavedSearch saved) {
    query = saved.query;
    filters = saved.filters.copy();
    notifyListeners();
  }

  void setTheme(ThemeMode value) {
    themeMode = value;
    preferences?.setString('theme', value.name);
    notifyListeners();
  }

  void acceptConsent({bool all = false}) {
    consentAccepted = true;
    personalized = all;
    analytics = all;
    preferences?.setBool('consent', true);
    preferences?.setBool('personalized', personalized);
    preferences?.setBool('analytics', analytics);
    notifyListeners();
  }

  void setPrivacy({required bool personalized, required bool analytics}) {
    this.personalized = personalized;
    this.analytics = analytics;
    preferences?.setBool('personalized', personalized);
    preferences?.setBool('analytics', analytics);
    notifyListeners();
  }

  void signIn() {
    signedIn = true;
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    selectedTab = 0;
    messages.clear();
    notifyListeners();
  }

  List<String> messagesFor(String listingId) => messages
      .where((message) => message.listingId == listingId)
      .map((message) => message.text)
      .toList();

  void addMessage(String listingId, String text) {
    if (text.trim().isEmpty) return;
    messages.add(DemoMessage(listingId: listingId, text: text.trim()));
    notifyListeners();
  }

  void publish(Listing l) {
    ownListings.insert(0, l);
    selectedTab = 4;
    notifyListeners();
  }

  void clearHistory() {
    searchHistory.clear();
    notifyListeners();
  }

  static String _searchText(String value) => value
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss');
}

class DemoScope extends InheritedNotifier<DemoStore> {
  const DemoScope({super.key, required DemoStore store, required super.child})
    : super(notifier: store);
  static DemoStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DemoScope>()!.notifier!;
}
