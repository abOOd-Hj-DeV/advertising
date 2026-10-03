import 'package:flutter/material.dart';
import '../data/demo_store.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'account.dart';
import 'filters.dart';
import 'listing.dart';

const homeCategories = [
  'Für dich',
  'Immobilien',
  'Haus & Garten',
  'Auto, Rad & Boot',
  'Mode & Beauty',
  'Jobs',
  'Elektronik',
];
const categoryIcons = [
  Icons.home_outlined,
  Icons.home_outlined,
  Icons.chair_outlined,
  Icons.directions_car_outlined,
  Icons.checkroom,
  Icons.work_outline,
  Icons.devices_outlined,
];

void favoriteListing(BuildContext context, Listing listing) {
  final store = DemoScope.of(context);
  if (store.signedIn) {
    store.toggleFavorite(listing.id);
  } else {
    go(context, GuestPage(variant: 0, favoriteId: listing.id));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String category = 'Für dich';
  String propertyTab = 'Entdecken';
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    var items = [...store.ownListings, ...listings]
        .where(
          (l) =>
              category == 'Für dich' ||
              l.category == category ||
              category == 'Auto, Rad & Boot' &&
                  l.category == 'Fahrräder & Zubehör',
        )
        .toList();
    if (category == 'Immobilien' && propertyTab != 'Entdecken') {
      items = items.where((l) => l.type == propertyTab).toList();
    }
    final gallery = [listings[8], listings[12], listings[15], listings[16]];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => go(context, const SearchPage(autofocus: true)),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xff30322a)
                          : Brand.background,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            store.filters.city.isEmpty
                                ? 'Suche in ganz Deutschland'
                                : 'Suche in ${store.filters.locationLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Suchort ändern',
                          onPressed: () => editFilter(context, 'Ort'),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                          ),
                          icon: Icon(
                            Icons.location_on_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Benachrichtigungen',
                onPressed: () => go(
                  context,
                  store.signedIn
                      ? const NotificationsPage()
                      : const GuestPage(variant: 2),
                ),
                icon: Icon(
                  Icons.notifications_none,
                  color: Theme.of(context).colorScheme.primary,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 94,
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: homeCategories.length,
                  itemBuilder: (context, i) {
                    final name = homeCategories[i];
                    return InkWell(
                      onTap: () => setState(() => category = name),
                      child: Container(
                        width: 76,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: category == name
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Brand.pale,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: i == 0
                                  ? const Logo(
                                      size: 25,
                                      wordmark: false,
                                      color: Brand.deep,
                                    )
                                  : Icon(
                                      categoryIcons[i],
                                      size: 27,
                                      color: Brand.deep,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name.replaceAll(' & ', '\n& '),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.1,
                                fontWeight: category == name
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: category == name
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Alle Kategorien',
                  onPressed: () => go(context, const HomeCategoriesPage()),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 22),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              if (category == 'Immobilien')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        for (final tab in ['Entdecken', 'Mieten', 'Kaufen'])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: ChoiceChip(
                                label: Text(tab),
                                selected: propertyTab == tab,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => propertyTab = tab),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(42, 0, 42, 4),
                  child: Container(
                    height: 142,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xfff7f3e8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Demo-Anzeige',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xff76715c),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Lieblingsstücke.\nNeue Geschichten.',
                          style: TextStyle(
                            fontSize: 23,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff59542b),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => go(context, const SearchPage()),
                          child: const Row(
                            children: [
                              Text(
                                'Jetzt entdecken',
                                style: TextStyle(
                                  color: Color(0xff59542b),
                                  fontSize: 13,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_forward,
                                size: 19,
                                color: Color(0xff59542b),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (category == 'Für dich') ...[
                const SliverToBoxAdapter(child: SectionHeading('Galerie')),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        112 + 90 * MediaQuery.textScalerOf(context).scale(1),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: gallery.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => SizedBox(
                        width: 145,
                        child: ListingCard(
                          listing: gallery[i],
                          gallery: true,
                          onOpen: () =>
                              go(context, ListingPage(listing: gallery[i])),
                          onFavorite: () =>
                              favoriteListing(context, gallery[i]),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: .25),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SectionHeading(
                  category == 'Für dich'
                      ? 'Gerade neu reingekommen'
                      : '$category entdecken',
                ),
              ),
              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 48,
                          color: Brand.muted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Hier ist gerade nichts dabei. Schau in allen Kategorien.',
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => category = 'Für dich'),
                          child: const Text('Alle Anzeigen ansehen'),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ListingCard(
                      listing: items[i],
                      onOpen: () => go(context, ListingPage(listing: items[i])),
                      onFavorite: () => favoriteListing(context, items[i]),
                    ),
                    childCount: items.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 16,
                    mainAxisExtent:
                        (MediaQuery.sizeOf(context).width - 24) / 2 +
                        110 * MediaQuery.textScalerOf(context).scale(1),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ],
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.autofocus = false});
  final bool autofocus;
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final text = TextEditingController(text: DemoScope.of(context).query);
  bool typing = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  void submit(String value) {
    DemoScope.of(context).search(value);
    FocusScope.of(context).unfocus();
    setState(() => typing = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final results = store.results();
    final chips = {
      'Ort': store.filters.city.isEmpty ? 'Ort' : store.filters.locationLabel,
      'Kategorie': store.filters.category == 'Alle Kategorien'
          ? 'Kategorie'
          : store.filters.category,
      'Preis': store.filters.priceLabel == 'Beliebig'
          ? 'Preis'
          : store.filters.priceLabel,
      if (store.filters.category == 'Fahrräder & Zubehör')
        'Art': store.filters.kind == 'Alle' ? 'Art' : store.filters.kind,
      if (store.filters.category == 'Fahrräder & Zubehör')
        'Typ': store.filters.type == 'Alle' ? 'Typ' : store.filters.type,
      'Zustand': store.filters.condition == 'Alle'
          ? 'Zustand'
          : store.filters.condition,
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Zurück',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Brand.green),
                  ),
                  Expanded(
                    child: TextField(
                      controller: text,
                      autofocus: widget.autofocus,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() => typing = true),
                      onSubmitted: submit,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Was suchst du?',
                        prefixIcon: const Icon(Icons.search, size: 22),
                        suffixIcon: IconButton(
                          tooltip: 'Suche löschen',
                          onPressed: () {
                            text.clear();
                            submit('');
                          },
                          icon: const Icon(Icons.close, size: 19),
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xff30322a)
                            : Brand.background,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      submit(text.text);
                      final result = await go<SearchFilters>(
                        context,
                        FiltersPage(initial: store.filters),
                      );
                      if (result != null) store.changeFilters(result);
                    },
                    icon: const Icon(Icons.tune, size: 23),
                    label: const Text('Filter', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
            if (typing)
              Expanded(
                child: ListView(
                  children: [
                    RowLink(
                      text.text.isEmpty ? 'Alle Anzeigen' : text.text,
                      icon: Icons.search,
                      onTap: () => submit(text.text),
                    ),
                    for (final q
                        in {
                          ...store.searchHistory,
                          'Fahrrad',
                          'Sofa',
                          'Wohnung',
                          'Kamera',
                        }.where(
                          (q) =>
                              text.text.isEmpty ||
                              q.toLowerCase().contains(text.text.toLowerCase()),
                        ))
                      RowLink(
                        q,
                        icon: Icons.history,
                        onTap: () {
                          text.text = q;
                          submit(q);
                        },
                      ),
                  ],
                ),
              )
            else ...[
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  children: [
                    for (final entry in chips.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 14),
                          ),
                          backgroundColor: Brand.background.withValues(
                            alpha: .03,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: Brand.muted),
                          ),
                          onPressed: () => editFilter(context, entry.key),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${results.length} Ergebnisse',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    if (results.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Logo(
                                size: 68,
                                wordmark: false,
                                color: Brand.muted,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Keine Anzeigen gefunden',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Probiere einen anderen Suchbegriff oder passe deine Filter an.',
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: () {
                                  store.changeFilters(SearchFilters());
                                  text.clear();
                                  submit('');
                                },
                                child: const Text('Suche zurücksetzen'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        padding: const EdgeInsets.only(bottom: 84),
                        itemCount: results.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return const Padding(
                              padding: EdgeInsets.fromLTRB(45, 8, 45, 14),
                              child: DemoSearchAd(),
                            );
                          }
                          final l = results[i - 1];
                          return ListingCard(
                            listing: l,
                            compact: true,
                            onOpen: () => go(context, ListingPage(listing: l)),
                            onFavorite: () => favoriteListing(context, l),
                          );
                        },
                      ),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SizedBox(
                          width: 212,
                          child: PrimaryButton(
                            'Suche speichern',
                            icon: Icons.favorite_border,
                            onPressed: () {
                              if (store.signedIn) {
                                store.saveSearch();
                                toast(context, 'Suche lokal gespeichert');
                              } else {
                                go(context, const GuestPage(variant: 0));
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomTabs(
        selected: 0,
        onTap: (i) {
          if (i == 0) {
            Navigator.popUntil(context, (r) => r.isFirst);
            store.changeTab(0);
          } else if (!store.signedIn) {
            go(
              context,
              GuestPage(
                variant: i == 1
                    ? 0
                    : i == 3
                    ? 2
                    : i == 2
                    ? 3
                    : 1,
              ),
            );
          } else {
            store.changeTab(i);
            Navigator.popUntil(context, (r) => r.isFirst);
          }
        },
      ),
    );
  }
}

class DemoSearchAd extends StatelessWidget {
  const DemoSearchAd({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Row(
      children: [
        const SizedBox(width: 65, height: 65, child: ProductImage('camera')),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demo-Anzeige',
                style: TextStyle(fontSize: 10, color: Brand.muted),
              ),
              const Text(
                'Gute Dinge verdienen eine zweite Chance.',
                maxLines: 2,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                'Entdecke mehr',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class HomeCategoriesPage extends StatelessWidget {
  const HomeCategoriesPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Alle Kategorien', close: true),
    body: ListView(
      children: [
        for (var i = 0; i < categoryNames.length; i++)
          Column(
            children: [
              RowLink(
                categoryNames[i],
                icon: [
                  Icons.grid_view,
                  Icons.directions_car_outlined,
                  Icons.home_outlined,
                  Icons.chair_outlined,
                  Icons.checkroom,
                  Icons.devices_outlined,
                  Icons.pets,
                  Icons.child_care,
                  Icons.work_outline,
                  Icons.sports_soccer,
                  Icons.menu_book,
                  Icons.confirmation_number_outlined,
                  Icons.handyman_outlined,
                  Icons.card_giftcard,
                  Icons.school_outlined,
                  Icons.handshake_outlined,
                ][i],
                subtitle: [
                  'Alles auf einen Blick',
                  'Autos, Fahrräder und Zubehör',
                  'Dein neues Zuhause',
                  'Möbel, Garten und Haushalt',
                  'Kleidung und Accessoires',
                  'Technik für jeden Tag',
                  'Alles für Tiere',
                  'Für die ganze Familie',
                  'Deine nächste Chance',
                  'Zeit für deine Hobbys',
                  'Kultur zum Entdecken',
                  'Erlebnisse und Veranstaltungen',
                  'Hilfe von nebenan',
                  'Geben und Tauschen',
                  'Neues lernen',
                  'Gemeinsam mehr erreichen',
                ][i],
                onTap: () {
                  final store = DemoScope.of(context);
                  store.search('');
                  store.changeFilters(
                    SearchFilters(category: categoryNames[i]),
                  );
                  go(context, const SearchPage());
                },
              ),
              const Divider(),
            ],
          ),
      ],
    ),
    bottomNavigationBar: BottomAction(
      'Schließen',
      onPressed: () => Navigator.pop(context),
    ),
  );
}
