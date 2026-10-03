import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/demo_store.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'account.dart';
import 'discovery.dart';
import 'settings.dart';

void shareDemo(BuildContext context, String id) {
  Clipboard.setData(ClipboardData(text: 'demo://advertising/anzeigen/$id'));
  toast(context, 'Lokaler Demo-Link kopiert');
}

void demoCall(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Kontakt aufnehmen'),
    content: const Text(
      'Telefonkontakt wird in dieser lokalen Demo nicht ausgelöst. Du kannst stattdessen eine Demo-Nachricht schreiben.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Schließen'),
      ),
    ],
  ),
);

class ListingPage extends StatefulWidget {
  const ListingPage({super.key, required this.listing});
  final Listing listing;
  @override
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  bool expanded = false, translated = false;
  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final store = DemoScope.of(context);
    final attributes = {
      if (l.category == 'Fahrräder & Zubehör')
        'Art': l.kind
      else
        'Kategorie': l.category,
      'Typ': l.type,
      'Zustand': l.condition,
    };
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 258,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: IconButton.filled(
                tooltip: 'Zurück',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Brand.green,
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FavoriteButton(
                  active: store.favorites.contains(l.id),
                  onPressed: () => favoriteListing(context, l),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton.filled(
                  tooltip: 'Anzeige teilen',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Brand.green,
                  ),
                  onPressed: () => shareDemo(context, l.id),
                  icon: const Icon(Icons.share_outlined, size: 22),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: InkWell(
                      onTap: () => go(context, GalleryPage(listing: l)),
                      child: ProductImage(l.image),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      color: Colors.black54,
                      child: Text(
                        '1/${l.gallery.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () =>
                                go(context, ListingLocationPage(listing: l)),
                            child: Text(
                              '${l.district}, ${l.city}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${l.formattedPrice}${l.price > 100 ? ' VB' : ''}',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                color: Brand.background,
                                child: Text(
                                  l.shipping
                                      ? 'Versand möglich'
                                      : 'Nur Abholung',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 15),
                          const SizedBox(width: 6),
                          Text(l.date, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 16),
                          const Icon(Icons.visibility_outlined, size: 16),
                          const SizedBox(width: 5),
                          const Text('124', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 16),
                          const Icon(Icons.favorite_border, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            store.favorites.contains(l.id) ? '13' : '12',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(50, 0, 50, 12),
              child: DemoSearchAd(),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeading('Details')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final a in attributes.entries)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.key,
                              style: const TextStyle(
                                color: Brand.muted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              a.value,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => setState(() => translated = !translated),
                    icon: const Icon(Icons.translate, size: 15),
                    label: Text(
                      translated ? 'Original anzeigen' : 'See translation',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    translated
                        ? 'This fictional listing is in good condition and ready for a new home. '
                              'Collection by appointment. No real transaction is possible in this offline demo.'
                        : l.description,
                    maxLines: expanded ? null : 5,
                    overflow: expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Ausstattung und Hinweise',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✓ Sorgfältig gepflegt\n✓ Weitere Fotos in der Galerie\n✓ Abholung nach Vereinbarung\n✓ Fiktive Daten – keine echte Anzeige',
                      style: TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ],
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => setState(() => expanded = !expanded),
                    child: Text(
                      expanded ? 'Weniger anzeigen' : 'Mehr anzeigen',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 6,
              color: Theme.of(context).dividerColor.withValues(alpha: .3),
            ),
          ),
          SliverToBoxAdapter(
            child: RowLink(
              l.seller,
              subtitle:
                  '${l.commercial ? 'Gewerblicher' : 'Privater'} Anbieter · Aktiv seit 2022',
              icon: Icons.account_circle_outlined,
              onTap: () => go(context, SellerPage(listing: l)),
            ),
          ),
          SliverToBoxAdapter(
            child: RowLink(
              'Alle Anzeigen von ${l.seller}',
              onTap: () => go(context, SellerPage(listing: l)),
            ),
          ),
          SliverToBoxAdapter(
            child: RowLink(
              'Anzeige melden',
              icon: Icons.flag_outlined,
              onTap: () => go(
                context,
                FeedbackPage(title: 'Anzeige melden', subject: l.title),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Anzeigen-ID: ${l.id} · Lokale Demo',
                style: const TextStyle(color: Brand.muted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => demoCall(context),
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Anrufen'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  'Nachricht',
                  icon: Icons.chat_bubble_outline,
                  onPressed: () => go(
                    context,
                    store.signedIn
                        ? MessagePage(listing: l)
                        : const GuestPage(variant: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.listing});
  final Listing listing;
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  int index = 0;
  final page = PageController();
  @override
  void dispose() {
    page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      leading: IconButton(
        tooltip: 'Galerie schließen',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      title: Text(
        '${index + 1}/${widget.listing.gallery.length}',
        style: const TextStyle(color: Colors.white),
      ),
      centerTitle: true,
    ),
    body: Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: page,
            itemCount: widget.listing.gallery.length,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: ProductImage(
                  widget.listing.gallery[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filled(
                tooltip: 'Vorheriges Foto',
                onPressed: index == 0
                    ? null
                    : () => page.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton.filled(
                tooltip: 'Nächstes Foto',
                onPressed: index == widget.listing.gallery.length - 1
                    ? null
                    : () => page.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SellerPage extends StatefulWidget {
  const SellerPage({super.key, required this.listing});
  final Listing listing;
  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  bool followed = false;
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final items = listings
        .where(
          (a) =>
              a.seller == l.seller &&
              a.title.toLowerCase().contains(search.text.toLowerCase()),
        )
        .toList();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PageHeader(
          l.seller,
          actions: [
            IconButton(
              tooltip: 'Profil teilen',
              onPressed: () => shareDemo(context, 'seller-${l.seller}'),
              icon: const Icon(Icons.share_outlined, color: Brand.green),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Brand.pale,
                    child: Icon(
                      Icons.person_outline,
                      color: Brand.deep,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.seller,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${l.commercial ? 'Gewerblicher' : 'Privater'} Anbieter · Aktiv seit 2022',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Brand.muted,
                          ),
                        ),
                        Text(
                          '${listings.where((a) => a.seller == l.seller).length} Anzeigen online · 12 Follower',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Brand.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 4,
                children: [
                  _SellerBadge('☺ TOP Zufriedenheit'),
                  _SellerBadge('♧ Sehr freundlich'),
                  _SellerBadge('♧ Sehr zuverlässig'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        if (!DemoScope.of(context).signedIn) {
                          go(context, const GuestPage(variant: 1));
                        } else {
                          setState(() => followed = !followed);
                        }
                      },
                      icon: Icon(
                        followed ? Icons.check : Icons.person_add_alt,
                        size: 16,
                      ),
                      label: Text(
                        followed ? 'Gefolgt' : 'Folgen',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => go(
                        context,
                        InformationPage(
                          title: 'Webseite',
                          paragraphs: [
                            'Demo-Profil von ${l.seller}',
                            'Diese Vorschau führt nicht zu einer echten Verkäufer-Webseite. Alle Profildaten sind fiktiv.',
                          ],
                        ),
                      ),
                      child: const Text(
                        'Webseite',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => demoCall(context),
                      child: const Text(
                        'Anrufen',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 5),
            const TabBar(
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'Anzeigen'),
                Tab(text: 'Über'),
                Tab(text: 'Kontakt'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          controller: search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 18),
                            hintText: 'Such in Anzeigen von ${l.seller}',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(
                                child: Text('Keine Anzeigen gefunden'),
                              )
                            : ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, i) => ListingCard(
                                  listing: items[i],
                                  compact: true,
                                  onOpen: () => go(
                                    context,
                                    ListingPage(listing: items[i]),
                                  ),
                                  onFavorite: () =>
                                      favoriteListing(context, items[i]),
                                ),
                              ),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Unternehmensbeschreibung',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Willkommen bei ${l.seller}. Wir mögen schöne Dinge und geben ihnen gerne ein zweites Zuhause. '
                        'Dies ist ein fiktives Profil für die lokale Demo.',
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                      TextButton(
                        onPressed: () => go(
                          context,
                          InformationPage(
                            title: 'Über ${l.seller}',
                            paragraphs: [
                              'Lieblingsstücke weitergeben',
                              'Dieses Verkäuferprofil zeigt ausschließlich fiktive Beispieldaten. '
                                  'Hier gibt es keine echten Angebote und keine Transaktionen.',
                            ],
                          ),
                        ),
                        child: const Text('Weiterlesen'),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Rechtliche Angaben',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Impressum\nDemo Anbieter\nMusterstraße 12\n10115 Berlin',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      for (final doc in [
                        'Widerrufsbelehrung & Muster-Widerrufsformular',
                        'Allgemeine Geschäftsbedingungen',
                        'Datenschutzerklärung',
                      ])
                        RowLink(
                          doc,
                          icon: Icons.description_outlined,
                          onTap: () => go(
                            context,
                            InformationPage(
                              title: doc,
                              paragraphs: [
                                'Dokumentvorschau',
                                'Lokaler Beispieltext. Kein rechtsverbindliches Dokument und kein echter Anbieter.',
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  ListView(
                    children: [
                      RowLink(
                        'Musterstraße 12\n10115 ${l.city} · ${l.district}',
                        icon: Icons.location_on_outlined,
                        onTap: () =>
                            go(context, ListingLocationPage(listing: l)),
                      ),
                      const Divider(),
                      const RowLink(
                        'Mo.–Fr.: 13:00–19:00',
                        icon: Icons.schedule,
                        trailing: SizedBox.shrink(),
                      ),
                      const Divider(),
                      RowLink(
                        'demo.example.test',
                        icon: Icons.language,
                        onTap: () => go(
                          context,
                          InformationPage(
                            title: 'Webseite',
                            paragraphs: [
                              'Fiktive Kontaktadresse',
                              'Diese Adresse ist nur ein Beispiel und öffnet keinen externen Dienst.',
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      RowLink(
                        'Rechtliche Angaben',
                        onTap: () => go(
                          context,
                          InformationPage(
                            title: 'Rechtliche Angaben',
                            paragraphs: [
                              'Demo Anbieter',
                              'Musterstraße 12 · 10115 Berlin\nKeine reale Firma.',
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerBadge extends StatelessWidget {
  const _SellerBadge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xffece0ff),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xff6031a2),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class ListingLocationPage extends StatelessWidget {
  const ListingLocationPage({super.key, required this.listing});
  final Listing listing;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Standort'),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${listing.district}, ${listing.city}'),
        ),
        Expanded(child: DemoMap(city: listing.city)),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Ungefähre Lage mit fiktiven Daten. Keine echte Anbieteradresse.',
            style: TextStyle(color: Brand.muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
