import 'package:flutter/material.dart';
import '../data/demo_store.dart';
import '../data/media.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'account.dart' show EditProfilePage;
import 'discovery.dart';
import 'listing.dart';
import 'listing_editor.dart';

class LocalEmpty extends StatelessWidget {
  const LocalEmpty(
    this.title,
    this.body, {
    super.key,
    this.action = 'Anzeigen entdecken',
    this.onAction,
  });
  final String title, body, action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search, size: 48),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        PrimaryButton(
          action,
          onPressed: onAction ?? () => go(context, const SearchPage()),
        ),
      ],
    ),
  );
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final items = store.catalog
        .where((l) => store.favorites.contains(l.id))
        .toList();
    final sellers = store.catalog
        .where((l) => store.followedSellers.contains(l.identity))
        .toList();
    final identities = <String>{};
    sellers.removeWhere((l) => !identities.add(l.identity));
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          AppBar(
            title: const Text('Favoriten'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Zuletzt angesehen',
                onPressed: () => go(context, const RecentPage()),
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Merkliste'),
              Tab(text: 'Suchaufträge'),
              Tab(text: 'Folge ich'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                items.isEmpty
                    ? const SingleChildScrollView(
                        child: LocalEmpty(
                          'Hier wohnen deine Lieblingsanzeigen',
                          'Tippe auf das Herz einer Anzeige, um sie lokal zu merken.',
                        ),
                      )
                    : ListView(
                        children: [
                          for (final l in items)
                            ListingCard(
                              listing: l,
                              compact: true,
                              onOpen: () =>
                                  go(context, ListingPage(listing: l)),
                              onFavorite: () => store.toggleFavorite(l.id),
                            ),
                        ],
                      ),
                store.savedSearches.isEmpty
                    ? const SingleChildScrollView(
                        child: LocalEmpty(
                          'Keine Suchaufträge',
                          'Speichere eine Suche, damit du sie hier wiederfindest.',
                        ),
                      )
                    : ListView(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Schalter steuern nur lokale Demo-Hinweise, keine E-Mails oder Push-Zustellung.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          for (final s in store.savedSearches)
                            Column(
                              children: [
                                RowLink(
                                  s.label,
                                  icon: Icons.search,
                                  onTap: () {
                                    store.restoreSearch(s);
                                    go(context, const SearchPage());
                                  },
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SwitchListTile(
                                        title: const Text('Lokale Hinweise'),
                                        value: s.alerts,
                                        onChanged: (_) =>
                                            store.toggleSearchAlerts(s),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Suchauftrag löschen',
                                      onPressed: () async {
                                        if (await confirmLocal(
                                          context,
                                          'Suchauftrag löschen?',
                                          'Nur dieser lokale Suchauftrag wird entfernt.',
                                        )) {
                                          store.deleteSearch(s);
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                                const Divider(),
                              ],
                            ),
                        ],
                      ),
                sellers.isEmpty
                    ? const SingleChildScrollView(
                        child: LocalEmpty(
                          'Du folgst noch niemandem',
                          'Öffne ein Verkäuferprofil und wähle Folgen.',
                        ),
                      )
                    : ListView(
                        children: [
                          for (final l in sellers)
                            RowLink(
                              l.seller,
                              icon: Icons.person_outline,
                              subtitle: 'Lokal gefolgt',
                              onTap: () => go(context, SellerPage(listing: l)),
                              trailing: IconButton(
                                tooltip: 'Nicht mehr folgen',
                                onPressed: () => store.toggleFollow(l.identity),
                                icon: const Icon(Icons.person_remove_outlined),
                              ),
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

class RecentPage extends StatelessWidget {
  const RecentPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final items = store.recentlyViewed
        .map(store.findListing)
        .whereType<Listing>();
    return Scaffold(
      appBar: PageHeader(
        'Zuletzt angesehen',
        actions: [
          IconButton(
            tooltip: 'Verlauf löschen',
            onPressed: () async {
              if (await confirmLocal(
                context,
                'Verlauf löschen?',
                'Nur zuletzt angesehene Anzeigen werden entfernt. Merkliste bleibt erhalten.',
              )) {
                store.clearRecent();
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: items.isEmpty
          ? const SingleChildScrollView(
              child: LocalEmpty(
                'Noch nichts angesehen',
                'Öffne eine Anzeige, um sie hier wiederzufinden.',
              ),
            )
          : ListView(
              children: [
                for (final l in items)
                  ListingCard(
                    listing: l,
                    compact: true,
                    onOpen: () => go(context, ListingPage(listing: l)),
                    onFavorite: () => favoriteListing(context, l),
                  ),
              ],
            ),
    );
  }
}

class OwnListingsPage extends StatelessWidget {
  const OwnListingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    if (!store.signedIn) {
      return const Scaffold(
        body: Center(child: Text('Lokaler Zugang erforderlich')),
      );
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: PageHeader(
          'Meine Anzeigen',
          actions: [
            IconButton(
              tooltip: 'Neue Anzeige',
              onPressed: () => go(context, const ListingEditor()),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final status in ListingStatus.values)
                  Tab(
                    text:
                        '${status.label} (${store.ownListings.where((l) => l.status == status).length})',
                  ),
                Tab(text: 'Entwürfe (${store.drafts.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final status in ListingStatus.values)
                    Builder(
                      builder: (context) {
                        final rows = store.ownListings
                            .where((l) => l.status == status)
                            .toList();
                        return rows.isEmpty
                            ? SingleChildScrollView(
                                child: LocalEmpty(
                                  'Keine ${status.label.toLowerCase()}n Anzeigen',
                                  'Deine Anzeigen und Status bleiben auf diesem Gerät.',
                                  action: 'Anzeige erstellen',
                                  onAction: () =>
                                      go(context, const ListingEditor()),
                                ),
                              )
                            : ListView(
                                children: [
                                  for (final l in rows)
                                    Column(
                                      children: [
                                        ListingCard(
                                          listing: l,
                                          compact: true,
                                          onOpen: () => go(
                                            context,
                                            ListingPage(listing: l),
                                          ),
                                          onFavorite: () =>
                                              store.toggleFavorite(l.id),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Wrap(
                                            spacing: 8,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => go(
                                                  context,
                                                  ListingEditor(
                                                    listingId: l.id,
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                                label: const Text('Bearbeiten'),
                                              ),
                                              ListingManagementMenu(
                                                listingId: l.id,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(),
                                      ],
                                    ),
                                ],
                              );
                      },
                    ),
                  store.drafts.isEmpty
                      ? SingleChildScrollView(
                          child: LocalEmpty(
                            'Keine Entwürfe',
                            'Noch nicht veröffentlichte Anzeigen findest du hier.',
                            action: 'Entwurf beginnen',
                            onAction: () => go(context, const ListingEditor()),
                          ),
                        )
                      : ListView(
                          children: [
                            for (final d in store.drafts)
                              RowLink(
                                (d.values['title'] as String?)?.isNotEmpty ==
                                        true
                                    ? d.values['title'] as String
                                    : 'Unbenannter Entwurf',
                                icon: Icons.edit_note,
                                subtitle: 'Nur lokal · Fortsetzen',
                                onTap: () => go(
                                  context,
                                  ListingEditor(
                                    listingId: d.editingId,
                                    draft: d,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Entwurf löschen',
                                  onPressed: () async {
                                    if (await confirmLocal(
                                      context,
                                      'Entwurf löschen?',
                                      'Dieser lokale Entwurf wird dauerhaft entfernt.',
                                    )) {
                                      store.deleteDraft(d.id);
                                      if (await store.flush()) {
                                        await MediaRepository.instance
                                            .removeUnused(usedMedia(store));
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline),
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

class ListingManagementMenu extends StatelessWidget {
  const ListingManagementMenu({super.key, required this.listingId});
  final String listingId;
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final l = store.findListing(listingId);
    if (!store.signedIn || l == null || !store.isOwn(listingId)) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      tooltip: 'Anzeige verwalten',
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Verwalten ⋮'),
      ),
      onSelected: (value) async {
        if (value == 'edit') {
          go(context, ListingEditor(listingId: listingId));
          return;
        }
        if (value == 'delete') {
          if (await confirmLocal(
            context,
            'Anzeige löschen?',
            'Die lokale Anzeige wird dauerhaft gelöscht. Gesprächsverlauf bleibt erhalten.',
          )) {
            store.deleteListing(listingId);
            if (await store.flush()) {
              await MediaRepository.instance.removeUnused(usedMedia(store));
            }
          }
        } else {
          final status = ListingStatus.values.byName(value);
          if (status == ListingStatus.sold &&
              !await confirmLocal(
                context,
                'Als verkauft markieren?',
                'Nur lokaler Verlauf. Es findet kein Verkauf oder Zahlung statt.',
                action: 'Als verkauft markieren',
              )) {
            return;
          }
          store.setListingStatus(listingId, status);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
        if (l.status != ListingStatus.reserved)
          const PopupMenuItem(value: 'reserved', child: Text('Reservieren')),
        if (l.status != ListingStatus.active)
          const PopupMenuItem(value: 'active', child: Text('Aktivieren')),
        if (l.status != ListingStatus.sold)
          const PopupMenuItem(
            value: 'sold',
            child: Text('Als verkauft markieren'),
          ),
        const PopupMenuItem(value: 'delete', child: Text('Anzeige löschen')),
      ],
    );
  }
}

class SelfProfilePage extends StatelessWidget {
  const SelfProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final items = store.sellerListings('self');
    return Scaffold(
      appBar: const PageHeader('Öffentliches Demo-Profil'),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person_outline),
                ),
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${store.commercial ? 'Gewerblicher' : 'Privater'} Demo-Anbieter',
                ),
                Text('${items.length} aktive lokale Anzeigen'),
                const Text(
                  'Keine echten Bewertungen oder Verifizierungen',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const LocalEmpty(
              'Noch keine aktiven Anzeigen',
              'Dein lokales Profil wird nicht veröffentlicht.',
            ),
          for (final l in items)
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

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool archived = false;
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final rows =
        store.conversations.where((c) => c.archived == archived).toList()
          ..sort((a, b) => b.activity.compareTo(a.activity));
    return Column(
      children: [
        AppBar(
          title: Text(archived ? 'Archiv' : 'Nachrichten'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () => setState(() => archived = !archived),
              child: Text(archived ? 'Posteingang' : 'Archiv'),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Fiktive Gespräche · keine Übertragung',
            style: TextStyle(fontSize: 12, color: Brand.muted),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      const LocalEmpty(
                        'Alles an einem Ort',
                        'Starte einen lokalen Chat über eine Anzeige.',
                      ),
                      if (!archived && store.conversations.isEmpty)
                        TextButton(
                          onPressed: store.seedConversations,
                          child: const Text('Fiktive Beispiele laden'),
                        ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    for (final c in rows)
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(
                          c.participant,
                          style: TextStyle(
                            fontWeight: c.unread > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${store.findListing(c.listingId)?.title ?? c.listingTitle}\n${c.draft.isNotEmpty ? 'Entwurf: ${c.draft}' : c.messages.lastOrNull?.text ?? 'Noch keine Nachricht'}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c.messages.isEmpty ? '' : timeLabel(c.activity),
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (c.unread > 0)
                              Badge(
                                label: Text('${c.unread}'),
                                child: const SizedBox(width: 20, height: 20),
                              ),
                          ],
                        ),
                        onTap: () => go(context, MessagePage(threadId: c.id)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

String timeLabel(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key, this.listing, this.threadId});
  final Listing? listing;
  final String? threadId;
  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final text = TextEditingController();
  String? id;
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final store = DemoScope.of(context);
    if (!store.signedIn) return;
    final c = widget.threadId == null
        ? null
        : store.findConversation(widget.threadId!);
    id = c?.id;
    if (c != null) text.text = c.draft;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current =
          c ??
          (widget.listing == null
              ? null
              : store.ensureConversation(widget.listing!));
      if (current != null) {
        text.text = current.draft;
        store.markRead(current.id);
        setState(() => id = current.id);
      }
    });
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final c = id == null ? null : store.findConversation(id!);
    if (!store.signedIn || (initialized && id != null && c == null)) {
      return Scaffold(
        appBar: const PageHeader('Nachrichten'),
        body: const Center(
          child: Text('Gespräch nicht verfügbar oder lokaler Zugang beendet.'),
        ),
      );
    }
    if (c == null) {
      return const Scaffold(
        body: Center(child: Text('Lokales Gespräch wird geöffnet …')),
      );
    }
    final l = store.findListing(c.listingId);
    final blocked = store.blockedParticipants.contains(c.participantId);
    final enabled = !blocked && l?.status == ListingStatus.active;
    return Scaffold(
      appBar: PageHeader(
        c.participant,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Gespräch verwalten',
            onSelected: (action) async {
              if (action == 'archive') {
                store.archiveChat(c.id, !c.archived);
                if (context.mounted) Navigator.pop(context);
              }
              if (action == 'delete' &&
                  await confirmLocal(
                    context,
                    'Gespräch löschen?',
                    'Verlauf und Entwurf werden nur lokal dauerhaft gelöscht. Andere Gespräche bleiben erhalten.',
                  )) {
                store.deleteChat(c.id);
                if (context.mounted) Navigator.pop(context);
              }
              if (action == 'block') {
                if (!context.mounted) return;
                if (await confirmLocal(
                  context,
                  blocked ? 'Lokal entsperren?' : 'Lokal blockieren?',
                  blocked
                      ? 'Die lokale Eingabe wird wieder aktiviert. Keine externe Kontaktaufnahme.'
                      : 'Deaktiviert Nachrichten und Simulation für diesen Demo-Teilnehmer.',
                  action: blocked ? 'Entsperren' : 'Blockieren',
                )) {
                  store.toggleBlock(c.participantId);
                }
              }
              if (action == 'report' && context.mounted) {
                go(context, LocalReportPage(target: c.participantId));
              }
              if (action == 'simulate') {
                store.sendMessage(
                  c.id,
                  'Fiktive Antwort: Danke für deine Demo-Nachricht!',
                  incoming: true,
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(c.archived ? 'Wiederherstellen' : 'Archivieren'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Gespräch löschen'),
              ),
              PopupMenuItem(
                value: 'block',
                child: Text(blocked ? 'Lokal entsperren' : 'Lokal blockieren'),
              ),
              const PopupMenuItem(value: 'report', child: Text('Lokal melden')),
              PopupMenuItem(
                value: 'simulate',
                enabled: enabled,
                child: const Text('Fiktive Antwort simulieren'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          RowLink(
            l?.title ?? '${c.listingTitle} · Nicht mehr verfügbar',
            subtitle:
                l?.formattedPrice ?? 'Gesprächsverlauf bleibt lokal erhalten',
            icon: Icons.sell_outlined,
            onTap: l == null
                ? null
                : () => go(context, ListingPage(listing: l)),
          ),
          if (l != null)
            TextButton(
              onPressed: () => go(
                context,
                l.identity == 'self'
                    ? const SelfProfilePage()
                    : SellerPage(listing: l),
              ),
              child: Text('Profil von ${c.participant}'),
            ),
          if (!enabled)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                blocked
                    ? 'Lokal blockiert – Entsperren im Menü'
                    : 'Anzeige nicht aktiv. Neue Nachrichten sind deaktiviert.',
              ),
            ),
          const Text(
            'Nur auf diesem Gerät · nicht zugestellt',
            style: TextStyle(fontSize: 11, color: Brand.muted),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: c.messages.length,
              itemBuilder: (context, i) {
                final m = c.messages[c.messages.length - i - 1];
                return Align(
                  alignment: m.incoming
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * .78,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.incoming
                          ? Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest
                          : Brand.pale,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          m.text,
                          style: TextStyle(
                            color: m.incoming ? null : Brand.deep,
                          ),
                        ),
                        Text(
                          '${timeLabel(m.at)} · ${m.incoming ? 'fiktiv empfangen' : 'lokal'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: m.incoming ? null : Brand.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: text,
                      enabled: enabled,
                      maxLength: 2000,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Nachricht schreiben',
                        counterText: '',
                      ),
                      onChanged: (v) {
                        store.setChatDraft(c.id, v);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Demo-Nachricht senden',
                    onPressed: !enabled || text.text.trim().isEmpty
                        ? null
                        : () {
                            if (store.sendMessage(c.id, text.text)) {
                              text.clear();
                              setState(() {});
                            }
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

class LocalReportPage extends StatefulWidget {
  const LocalReportPage({super.key, required this.target});
  final String target;
  @override
  State<LocalReportPage> createState() => _LocalReportPageState();
}

class _LocalReportPageState extends State<LocalReportPage> {
  String reason = 'Verdächtiger Inhalt';
  final details = TextEditingController();
  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Lokal melden'),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Diese Meldung wird nur auf diesem Gerät dokumentiert. Sie wird nicht an Kleinanzeigen, Behörden oder andere Personen gesendet.',
        ),
        for (final value in [
          'Verdächtiger Inhalt',
          'Unangemessene Nachricht',
          'Betrugsverdacht',
          'Sonstiges',
        ])
          ListTile(
            title: Text(value),
            leading: Icon(
              reason == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            onTap: () => setState(() => reason = value),
          ),
        TextField(
          controller: details,
          maxLength: 1000,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Details (optional, keine sensiblen Daten)',
          ),
        ),
        PrimaryButton(
          'Nur lokal dokumentieren',
          onPressed: () {
            DemoScope.of(context).report(
              target: widget.target,
              reason: reason,
              details: details.text,
            );
            Navigator.pop(context);
            toast(context, 'Lokal dokumentiert. Nichts wurde gesendet.');
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ],
    ),
  );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      appBar: PageHeader(
        'Benachrichtigungen',
        actions: [
          IconButton(
            tooltip: 'Benachrichtigungen einstellen',
            onPressed: () => go(context, const NotificationPreferencesPage()),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: store.notifications.isEmpty
          ? SingleChildScrollView(
              child: Column(
                children: [
                  const LocalEmpty(
                    'Keine lokalen Hinweise',
                    'Hier erscheinen lokale Erstellungs- und simulierte Nachrichtenereignisse.',
                  ),
                  TextButton(
                    onPressed: store.seedNotice,
                    child: const Text('Demo-Hinweis hinzufügen'),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                for (final n in store.notifications)
                  ListTile(
                    leading: Icon(
                      n.read
                          ? Icons.notifications_none
                          : Icons.notifications_active_outlined,
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: n.read
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text('Lokales Ereignis'),
                    trailing: IconButton(
                      tooltip: 'Hinweis entfernen',
                      onPressed: () => store.dismissNotice(n),
                      icon: const Icon(Icons.close),
                    ),
                    onTap: () {
                      store.readNotice(n);
                      if (n.threadId != null &&
                          store.findConversation(n.threadId!) != null) {
                        go(context, MessagePage(threadId: n.threadId));
                      } else if (n.listingId != null) {
                        final l = store.findListing(n.listingId!);
                        if (l != null) {
                          go(context, ListingPage(listing: l));
                        } else {
                          toast(context, 'Anzeige nicht mehr verfügbar');
                        }
                      } else {
                        go(context, const SearchPage());
                      }
                    },
                  ),
              ],
            ),
    );
  }
}

class NotificationPreferencesPage extends StatelessWidget {
  const NotificationPreferencesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      appBar: const PageHeader('Benachrichtigungen'),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Nur lokale Einstellungen. Keine echten E-Mails, Push-Nachrichten oder Änderungen an Android-/Browser-Berechtigungen.',
            ),
          ),
          SwitchListTile(
            title: const Text('Lokale In-App-Hinweise'),
            value: store.localAlerts,
            onChanged: (v) => store.setNotifications(alerts: v),
          ),
          SwitchListTile(
            title: const Text('E-Mail-Präferenz (nur gespeichert)'),
            subtitle: const Text('Es wird keine E-Mail versendet.'),
            value: store.emailPreference,
            onChanged: (v) => store.setNotifications(email: v),
          ),
        ],
      ),
    );
  }
}

class RecoveryPage extends StatelessWidget {
  const RecoveryPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Passwort vergessen'),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Kein echtes Passwort gespeichert',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        const Text(
          'Diese Offline-Demo authentifiziert niemanden. E-Mail und Passwort werden weder gespeichert noch gesendet. Daher gibt es keine Wiederherstellung, keinen Code und keine E-Mail/SMS. Verwende beim lokalen Einstieg ausschließlich erfundene Angaben.',
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          'Zurück zum lokalen Einstieg',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

class LocalDataPage extends StatelessWidget {
  const LocalDataPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      appBar: const PageHeader('Lokale Daten & Grenzen'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Offline-Demo, kein echter Marktplatz',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Anzeigen, Entwürfe, Bilder, Profil, Gespräche, Merkliste, Suchaufträge, Verlauf und Einstellungen bleiben lokal auf diesem Gerät bzw. dieser Browser-Origin. Ausloggen versteckt private Funktionen, löscht aber keine Daten. Ein erneuter lokaler Einstieg öffnet dasselbe Demo-Profil; das ist keine sichere Kontotrennung.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Keine echten Konten, Nachrichten, E-Mails, Push-Zustellung, Veröffentlichungen, Moderation, Verifizierung, Zahlungen, Lieferung oder Cloud-Synchronisierung. Nicht für vertrauliche oder wichtige Daten. Browser-Löschung, privater Modus und Deinstallation können Daten entfernen. Web braucht eine erste vollständige Online-Installation; ein leerer Offline-Cache kann diese App nicht starten.',
          ),
          const SizedBox(height: 12),
          Text(
            store.storageError ??
                (store.persistenceAvailable
                    ? 'Lokaler Speicher verfügbar. Schreibvorgänge werden geordnet abgewartet; keine absolute Absturz-Dauerhaftigkeit.'
                    : 'Nur Arbeitsspeicher – ohne verfügbaren Gerätespeicher gehen Änderungen beim Neustart verloren.'),
          ),
          if (MediaRepository.instance.cleanupWarning != null)
            Text(MediaRepository.instance.cleanupWarning!),
          TextButton(
            onPressed: () async {
              final ok = await store.retrySave();
              if (context.mounted) {
                toast(
                  context,
                  ok
                      ? 'Lokales Speichern abgeschlossen'
                      : 'Speichern fehlgeschlagen; Daten bleiben im Speicher.',
                );
              }
            },
            child: const Text('Speichern erneut versuchen'),
          ),
          RowLink(
            'Profilinformationen',
            icon: Icons.person_outline,
            onTap: store.signedIn
                ? () => go(context, EditProfilePage(initial: store.name))
                : null,
            subtitle: store.signedIn
                ? null
                : 'Lokalen Einstieg über Meins verwenden',
          ),
          RowLink(
            'Lokale Sicherheit',
            icon: Icons.shield_outlined,
            onTap: () => go(context, const LocalSafetyPage()),
          ),
          const Divider(),
          TextButton(
            onPressed: () async {
              if (!await confirmLocal(
                context,
                'Lokale Demo-Daten zurücksetzen?',
                'Entfernt Profil, Anzeigen, Entwürfe, importierte Bilder, Gespräche, Meldungen, Hinweise, Favoriten, Suchaufträge, Folgen, Verlauf, Datenschutz und Design auf diesem Gerät. Keine echten Konten und keine fremden App-Schlüssel. Du wirst lokal ausgeloggt.',
                action: 'Alles lokal zurücksetzen',
              )) {
                return;
              }
              final ok = await store.resetLocalData();
              if (ok) {
                MediaRepository.instance.pending.clear();
                await MediaRepository.instance.removeUnused({});
              }
              if (context.mounted) {
                if (ok) {
                  Navigator.popUntil(context, (r) => r.isFirst);
                } else {
                  toast(
                    context,
                    'Zurücksetzen konnte nicht dauerhaft gespeichert werden. Bitte erneut versuchen.',
                  );
                }
              }
            },
            child: const Text('Lokale Demo-Daten zurücksetzen'),
          ),
        ],
      ),
    );
  }
}

class LocalSafetyPage extends StatelessWidget {
  const LocalSafetyPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      appBar: const PageHeader('Lokale Sicherheit'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Keine sensiblen Daten eingeben. Melden protokolliert nur lokal; lokale Sperren sind hier bewusst rückgängig zu machen. Dies ist kein Ersatz für echte Moderation oder Notfallhilfe.',
          ),
          const SectionHeading('Lokal blockierte Teilnehmer'),
          if (store.blockedParticipants.isEmpty)
            const Text('Keine lokalen Sperren.'),
          for (final id in store.blockedParticipants)
            RowLink(
              store.conversations
                      .where((c) => c.participantId == id)
                      .firstOrNull
                      ?.participant ??
                  id,
              icon: Icons.block,
              trailing: TextButton(
                onPressed: () => store.toggleBlock(id),
                child: const Text('Entsperren'),
              ),
            ),
          SectionHeading('Lokale Meldungen (${store.reports.length})'),
          for (final r in store.reports)
            ListTile(
              title: Text(r['reason'] as String? ?? 'Meldung'),
              subtitle: Text('Nur lokal · ${r['details'] ?? ''}'),
            ),
        ],
      ),
    );
  }
}
