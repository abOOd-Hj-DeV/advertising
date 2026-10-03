import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/demo_store.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'discovery.dart';
import 'filters.dart';
import 'listing.dart';
import 'settings.dart';

class GuestPage extends StatefulWidget {
  const GuestPage({super.key, this.variant = 0, this.favoriteId});
  final int variant;
  final String? favoriteId;
  @override
  State<GuestPage> createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> {
  late int variant = widget.variant;
  static const headlines = [
    'All deine Lieblinge auf einen Blick',
    'Dein Kleinanzeigen. Dein Überblick.',
    'Gute Gespräche beginnen hier',
    'Mach Platz für neue Lieblingsstücke',
  ];
  void openAuth(bool register) {
    final store = DemoScope.of(context);
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
                          tooltip: 'Schließen',
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
                          child: const Text('HILFE'),
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
                          tooltip: 'Einführung ${i + 1}',
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
                  PrimaryButton(
                    'Registrieren',
                    onPressed: () => openAuth(true),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => openAuth(false),
                    child: const Text('Einloggen'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lokale UI-Demo · keine echten Konten',
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
  bool passwordStage = false, hidden = true, newsletter = false;
  String accountType = 'Privat';
  @override
  void dispose() {
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
    store.signIn();
    widget.onSuccess?.call();
    Navigator.popUntil(context, (r) => r.isFirst);
    toast(
      context,
      'Demo-Konto geöffnet. Es wurden keine Zugangsdaten übertragen.',
    );
  }

  void info(String title, String body) =>
      go(context, InformationPage(title: title, paragraphs: [title, body]));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(
      widget.register ? '' : 'Einloggen',
      actions: [
        TextButton(
          onPressed: () => go(context, const SettingsPage()),
          child: const Text('HILFE'),
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
            const Center(child: Logo(size: widgetLogoSize)),
            const SizedBox(height: widgetLogoSpacing),
            if (widget.register) ...[
              const Text(
                'Wie möchtest du Kleinanzeigen nutzen?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final t in ['Privat', 'Gewerblich'])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: t == 'Privat' ? 8 : 0),
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
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => info(
                  'Wann handle ich gewerblich?',
                  'Wenn du regelmäßig und geschäftlich verkaufst, '
                      'wähle Gewerblich. Diese Demo erstellt keine rechtsverbindlichen Konten.',
                ),
                child: const Text('Wann handle ich gewerblich?'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => info(
                  'Unter 18? Sicher starten',
                  'Sprich vor echten Käufen oder Verkäufen mit deinen Erziehungsberechtigten. '
                      'In dieser Demo ist kein Kauf möglich.',
                ),
                child: const Text('Unter 18? Sicher starten'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deine Anmeldedaten',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Text(
                'Willkommen bei Kleinanzeigen!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              const Text(
                'Gut für deinen Geldbeutel, gut für die Umwelt – jetzt einloggen.',
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
                hintText: widget.register ? 'E-Mail Adresse' : 'E-mail*',
              ),
              validator: (v) =>
                  v != null && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)
                  ? null
                  : 'Bitte eine gültige E-Mail eingeben',
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
                  hintText: 'Passwort',
                  suffixIcon: IconButton(
                    tooltip: 'Passwort anzeigen',
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
                    : 'Mindestens 8 Zeichen verwenden',
              ),
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
                        'Ja, ich freue mich auf regelmäßige Neuigkeiten per Mail aus der Unternehmensgruppe – abmelden geht jederzeit.',
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
                  ? 'Registrieren'
                  : passwordStage
                  ? 'Einloggen'
                  : 'Weiter',
              onPressed: submit,
            ),
            const SizedBox(height: 22),
            if (widget.register) ...[
              const Text(
                'Es gelten unsere Nutzungsbedingungen. Informationen zur Verarbeitung deiner Daten findest du in unserer Datenschutzerklärung.',
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
                      'Nutzungsbedingungen',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => go(
                      context,
                      const LegalPage(kind: 'Datenschutzerklärung'),
                    ),
                    child: const Text(
                      'Datenschutzerklärung',
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
                    'Noch nicht registriert?',
                    style: TextStyle(fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () => go(
                      context,
                      AuthPage(register: true, onSuccess: widget.onSuccess),
                    ),
                    child: const Text(
                      'Erstelle ein Konto',
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
              'DEMO: Verwende fiktive Daten, z. B. demo@example.test. '
              'Es gibt keine echte Anmeldung. Das Passwort wird weder gespeichert noch gesendet.',
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

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final items = [
      ...store.ownListings,
      ...listings,
    ].where((l) => store.favorites.contains(l.id)).toList();
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          AppBar(
            title: const Text('Favoriten'),
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: () => go(context, const SettingsPage()),
                child: const Text('HILFE'),
              ),
            ],
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Merkliste'),
              Tab(text: 'Suchaufträge'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                items.isEmpty
                    ? const _EmptyState(
                        icon: Icons.favorite_border,
                        title: 'Hier wohnen deine Lieblingsanzeigen',
                        body:
                            'Tippe auf das Herz einer Anzeige, um sie lokal zu merken.',
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) => ListingCard(
                          listing: items[i],
                          compact: true,
                          onOpen: () =>
                              go(context, ListingPage(listing: items[i])),
                          onFavorite: () => store.toggleFavorite(items[i].id),
                        ),
                      ),
                store.savedSearches.isEmpty
                    ? const _EmptyState(
                        icon: Icons.manage_search,
                        title: 'Keine Suchaufträge',
                        body:
                            'Speichere eine Suche, damit du sie hier wiederfindest.',
                      )
                    : ListView(
                        children: [
                          for (final s in store.savedSearches)
                            RowLink(
                              s.label,
                              icon: Icons.search,
                              trailing: const Icon(Icons.bookmark_border),
                              onTap: () {
                                store.restoreSearch(s);
                                go(context, const SearchPage());
                              },
                            ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return ListView(
      children: [
        AppBar(
          title: const Text('Meins'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Einstellungen',
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
                    const Text(
                      'Privater Demo-Anbieter',
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
              'Lokale Demo-Ergänzung: Diese angemeldete Ansicht war im Referenztest nicht zugänglich.',
              style: TextStyle(color: Brand.deep, fontSize: 12),
            ),
          ),
        ),
        RowLink(
          'Profil bearbeiten',
          icon: Icons.edit_outlined,
          onTap: () async {
            final result = await go<String>(
              context,
              EditProfilePage(initial: store.name),
            );
            if (result != null && context.mounted) {
              store.name = result;
              store.signIn();
            }
          },
        ),
        const Divider(),
        RowLink(
          'Meine Anzeigen',
          subtitle: '${store.ownListings.length} lokale Anzeigen',
          icon: Icons.sell_outlined,
          onTap: () => go(context, const OwnListingsPage()),
        ),
        const Divider(),
        RowLink(
          'Einstellungen & Hilfe',
          icon: Icons.settings_outlined,
          onTap: () => go(context, const SettingsPage()),
        ),
        const Divider(),
        RowLink('Ausloggen', icon: Icons.logout, onTap: store.signOut),
      ],
    );
  }
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final threads = [...store.ownListings, ...listings]
        .where(
          (listing) =>
              listing.id == listings.first.id ||
              store.messages.any((message) => message.listingId == listing.id),
        )
        .toList();
    return Column(
      children: [
        AppBar(
          title: const Text('Nachrichten'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () => go(context, const SettingsPage()),
              child: const Text('HILFE'),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'Fiktive Unterhaltung – keine echten Nachrichten',
            style: TextStyle(color: Brand.muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final listing in threads) ...[
                RowLink(
                  '${listing.seller} · ${listing.title}',
                  icon: Icons.account_circle_outlined,
                  subtitle: store.messagesFor(listing.id).isEmpty
                      ? 'Schreibe deine erste Demo-Nachricht'
                      : store.messagesFor(listing.id).last,
                  onTap: () => go(context, MessagePage(listing: listing)),
                ),
                const Divider(),
              ],
              if (store.messages.isEmpty)
                const _EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'Alles an einem Ort',
                  body: 'Deine Demo-Nachrichten bleiben nur in dieser Sitzung.',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class MessagePage extends StatefulWidget {
  const MessagePage({super.key, required this.listing});
  final Listing listing;
  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final text = TextEditingController();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      appBar: PageHeader(widget.listing.seller),
      body: Column(
        children: [
          RowLink(
            widget.listing.title,
            subtitle: widget.listing.formattedPrice,
            icon: Icons.sell_outlined,
            onTap: () => go(context, ListingPage(listing: widget.listing)),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Lokaler Demo-Chat. Nachrichten werden nicht übertragen.',
              style: TextStyle(fontSize: 12, color: Brand.muted),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final message in store.messagesFor(widget.listing.id))
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(60, 5, 16, 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Brand.pale,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(color: Brand.deep),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: text,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Nachricht schreiben',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Demo-Nachricht senden',
                    onPressed: text.text.trim().isEmpty
                        ? null
                        : () {
                            store.addMessage(
                              widget.listing.id,
                              text.text.trim(),
                            );
                            text.clear();
                            setState(() {});
                          },
                    icon: const Icon(Icons.send_outlined),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewListingPage extends StatefulWidget {
  const NewListingPage({super.key});
  @override
  State<NewListingPage> createState() => _NewListingPageState();
}

class _NewListingPageState extends State<NewListingPage> {
  final key = GlobalKey<FormState>();
  final title = TextEditingController(),
      price = TextEditingController(),
      description = TextEditingController();
  String category = 'Haus & Garten', image = 'sofa';
  @override
  void dispose() {
    title.dispose();
    price.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppBar(
        title: const Text('Anzeige aufgeben'),
        automaticallyImplyLeading: false,
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Brand.pale,
                  child: const Text(
                    'Demo-Ergänzung: Die originale Erstellungsseite war nicht zugänglich. Diese Anzeige wird ausschließlich lokal hinzugefügt.',
                    style: TextStyle(color: Brand.deep, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () async {
                    final value = await showModalBottomSheet<String>(
                      context: context,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: [
                            for (final i in [
                              'sofa',
                              'bike',
                              'bike_city',
                              'room',
                              'plant',
                              'camera',
                              'books',
                              'car',
                              'shoes',
                            ])
                              InkWell(
                                onTap: () => Navigator.pop(context, i),
                                child: ProductImage(i),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (value != null && mounted) setState(() => image = value);
                  },
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 170,
                          width: double.infinity,
                          child: ProductImage(image),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 18),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Demo-Foto auswählen',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Titel'),
                  validator: (v) => v != null && v.trim().length >= 5
                      ? null
                      : 'Mindestens 5 Zeichen eingeben',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kategorie'),
                  items: [
                    for (final c in categoryNames.skip(1))
                      DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Preis',
                    suffixText: '€',
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    return n != null && n.isFinite && n >= 0
                        ? null
                        : 'Gültigen Preis eingeben';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: description,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Beschreibung'),
                  validator: (v) => v != null && v.trim().length >= 10
                      ? null
                      : 'Mindestens 10 Zeichen eingeben',
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  'Lokal veröffentlichen',
                  onPressed: () {
                    if (!key.currentState!.validate()) return;
                    final store = DemoScope.of(context);
                    store.publish(
                      Listing(
                        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
                        title: title.text.trim(),
                        price: double.parse(price.text.replaceAll(',', '.')),
                        image: image,
                        category: category,
                        type: category,
                        ageHours: 0,
                        date: 'Heute, gerade eben',
                        seller: store.name,
                        description: description.text.trim(),
                      ),
                    );
                    toast(
                      context,
                      'Anzeige wurde nur in der Demo hinzugefügt.',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class OwnListingsPage extends StatelessWidget {
  const OwnListingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      appBar: const PageHeader('Meine Anzeigen'),
      body: store.ownListings.isEmpty
          ? const _EmptyState(
              icon: Icons.sell_outlined,
              title: 'Noch keine eigenen Anzeigen',
              body: 'Über Inserieren kannst du eine fiktive Anzeige erstellen.',
            )
          : ListView(
              children: [
                for (final l in store.ownListings)
                  ListingCard(
                    listing: l,
                    compact: true,
                    onOpen: () => go(context, ListingPage(listing: l)),
                    onFavorite: () => store.toggleFavorite(l.id),
                  ),
              ],
            ),
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
    appBar: const PageHeader('Profil bearbeiten'),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: key,
        child: TextFormField(
          controller: text,
          decoration: const InputDecoration(labelText: 'Demo-Name'),
          validator: (v) =>
              v != null && v.trim().isNotEmpty ? null : 'Namen eingeben',
        ),
      ),
    ),
    bottomNavigationBar: BottomAction(
      'Speichern',
      onPressed: () {
        if (key.currentState!.validate()) {
          Navigator.pop(context, text.text.trim());
        }
      },
    ),
  );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Benachrichtigungen'),
    body: ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Fiktive Benachrichtigungen',
            style: TextStyle(color: Brand.muted, fontSize: 12),
          ),
        ),
        RowLink(
          'Willkommen in deiner Demo',
          subtitle: 'Entdecke Anzeigen und speichere deine Favoriten.',
          icon: Icons.notifications_none,
          onTap: () => go(context, const SearchPage()),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: Brand.green),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Brand.muted),
          ),
        ],
      ),
    ),
  );
}
