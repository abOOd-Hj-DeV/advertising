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
    this.action = 'تصفح الإعلانات',
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
            title: const Text('المفضلة'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'شوهدت مؤخراً',
                onPressed: () => go(context, const RecentPage()),
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'المفضلة'),
              Tab(text: 'البحوث المحفوظة'),
              Tab(text: 'أتابعهم'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                items.isEmpty
                    ? const SingleChildScrollView(
                        child: LocalEmpty(
                          'إعلاناتك المفضلة تجتمع هنا',
                          'اضغط على رمز القلب في الإعلان لحفظه محلياً.',
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
                          'لا بحوث محفوظة',
                          'احفظ بحثاً لتجده هنا لاحقاً.',
                        ),
                      )
                    : ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              store.isLive
                                  ? 'تتحكم المفاتيح بتنبيهاتك داخل التطبيق.'
                                  : 'المفاتيح تتحكم بالتنبيهات التجريبية المحلية فقط، لا بالبريد الإلكتروني أو الإشعارات الفورية.',
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
                                        title: const Text('تنبيهات محلية'),
                                        value: s.alerts,
                                        onChanged: (_) =>
                                            store.toggleSearchAlerts(s),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'حذف البحث المحفوظ',
                                      onPressed: () async {
                                        if (await confirmLocal(
                                          context,
                                          'حذف البحث المحفوظ؟',
                                          'سيُحذف هذا البحث المحفوظ.',
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
                          'لا تتابع أحداً بعد',
                          'افتح ملف بائع واختر «متابعة».',
                        ),
                      )
                    : ListView(
                        children: [
                          for (final l in sellers)
                            RowLink(
                              l.seller,
                              icon: Icons.person_outline,
                              subtitle: 'تتابعه',
                              onTap: () => go(context, SellerPage(listing: l)),
                              trailing: IconButton(
                                tooltip: 'إلغاء المتابعة',
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
        'شوهدت مؤخراً',
        actions: [
          IconButton(
            tooltip: 'مسح السجل',
            onPressed: () async {
              if (await confirmLocal(
                context,
                'مسح السجل؟',
                'ستُحذف الإعلانات المشاهَدة مؤخراً فقط، وتبقى المفضلة.',
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
                'لم تشاهد شيئاً بعد',
                'افتح إعلاناً لتجده هنا لاحقاً.',
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
        body: Center(child: Text('يلزم تسجيل الدخول المحلي')),
      );
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: PageHeader(
          'إعلاناتي',
          actions: [
            IconButton(
              tooltip: 'إعلان جديد',
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
                Tab(text: 'المسودات (${store.drafts.length})'),
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
                                  'لا توجد إعلانات بحالة «${status.label}»',
                                  'تبقى إعلاناتك وحالاتها على هذا الجهاز.',
                                  action: 'إنشاء إعلان',
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
                                                label: const Text('تعديل'),
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
                            'لا مسودات',
                            'تجد هنا الإعلانات التي لم تُنشر بعد.',
                            action: 'بدء مسودة',
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
                                    : 'مسودة بلا اسم',
                                icon: Icons.edit_note,
                                subtitle: 'متابعة',
                                onTap: () => go(
                                  context,
                                  ListingEditor(
                                    listingId: d.editingId,
                                    draft: d,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: 'حذف المسودة',
                                  onPressed: () async {
                                    if (await confirmLocal(
                                      context,
                                      'حذف المسودة؟',
                                      'ستُحذف هذه المسودة نهائياً.',
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
      tooltip: 'إدارة الإعلان',
      child: const Padding(padding: EdgeInsets.all(12), child: Text('إدارة ⋮')),
      onSelected: (value) async {
        if (value == 'edit') {
          go(context, ListingEditor(listingId: listingId));
          return;
        }
        if (value == 'delete') {
          if (await confirmLocal(
            context,
            'حذف الإعلان؟',
            'سيُحذف الإعلان المحلي نهائياً، ويبقى سجل المحادثة.',
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
                'وضع علامة «مُباع»؟',
                'ستُعلَّم الإعلان كمُباع ويخرج من نتائج البحث.',
                action: 'وضع علامة «مُباع»',
              )) {
            return;
          }
          store.setListingStatus(listingId, status);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('تعديل')),
        if (l.status != ListingStatus.reserved)
          const PopupMenuItem(value: 'reserved', child: Text('حجز')),
        if (l.status != ListingStatus.active)
          const PopupMenuItem(value: 'active', child: Text('تفعيل')),
        if (l.status != ListingStatus.sold)
          const PopupMenuItem(value: 'sold', child: Text('وضع علامة «مُباع»')),
        const PopupMenuItem(value: 'delete', child: Text('حذف الإعلان')),
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
      appBar: const PageHeader('الملف التجريبي العام'),
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
                  store.isLive
                      ? (store.commercial ? 'حساب تجاري' : 'حساب فردي')
                      : 'بائع تجريبي ${store.commercial ? 'تجاري' : 'فردي'}',
                ),
                Text('إعلانات نشطة: ${items.length}'),
                if (!store.isLive)
                  const Text(
                    'لا توجد تقييمات أو توثيقات حقيقية',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
          if (items.isEmpty)
            LocalEmpty(
              'لا إعلانات نشطة بعد',
              store.isLive ? 'انشر أول إعلان لك من «إعلان جديد».' : 'ملفك المحلي لن يُنشر.',
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
          title: Text(archived ? 'الأرشيف' : 'الرسائل'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () => setState(() => archived = !archived),
              child: Text(archived ? 'صندوق الوارد' : 'الأرشيف'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            store.isLive ? 'المحادثات' : 'محادثات افتراضية · لا تُرسَل',
            style: const TextStyle(fontSize: 12, color: Brand.muted),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      const LocalEmpty(
                        'كل شيء في مكان واحد',
                        'ابدأ محادثة من داخل إعلان.',
                      ),
                      if (!archived && !store.isLive && store.conversations.isEmpty)
                        TextButton(
                          onPressed: store.seedConversations,
                          child: const Text('تحميل أمثلة افتراضية'),
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
                          '${store.findListing(c.listingId)?.title ?? c.listingTitle}\n${c.draft.isNotEmpty ? 'مسودة: ${c.draft}' : c.messages.lastOrNull?.text ?? 'لا رسائل بعد'}',
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
        appBar: const PageHeader('الرسائل'),
        body: const Center(
          child: Text('المحادثة غير متاحة.'),
        ),
      );
    }
    if (c == null) {
      return const Scaffold(
        body: Center(child: Text('جارٍ فتح المحادثة…')),
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
            tooltip: 'إدارة المحادثة',
            onSelected: (action) async {
              if (action == 'archive') {
                store.archiveChat(c.id, !c.archived);
                if (context.mounted) Navigator.pop(context);
              }
              if (action == 'delete' &&
                  await confirmLocal(
                    context,
                    'حذف المحادثة؟',
                    'سيُحذف السجل والمسودة نهائياً من هذا الجهاز فقط، وتبقى المحادثات الأخرى.',
                  )) {
                store.deleteChat(c.id);
                if (context.mounted) Navigator.pop(context);
              }
              if (action == 'block') {
                if (!context.mounted) return;
                if (await confirmLocal(
                  context,
                  blocked ? 'إلغاء الحظر؟' : 'حظر؟',
                  blocked
                      ? 'سيُسمح لهذا المستخدم بمراسلتك مجدداً.'
                      : 'يمنع هذا المستخدم من مراسلتك.',
                  action: blocked ? 'إلغاء الحظر' : 'حظر',
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
                  'رد افتراضي: شكراً على رسالتك التجريبية!',
                  incoming: true,
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(c.archived ? 'استعادة' : 'أرشفة'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('حذف المحادثة')),
              PopupMenuItem(
                value: 'block',
                child: Text(blocked ? 'إلغاء الحظر' : 'حظر'),
              ),
              const PopupMenuItem(value: 'report', child: Text('إبلاغ')),
              if (!store.isLive)
                PopupMenuItem(
                  value: 'simulate',
                  enabled: enabled,
                  child: const Text('محاكاة رد افتراضي'),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          RowLink(
            l?.title ?? '${c.listingTitle} · لم يعد متاحاً',
            subtitle: l?.formattedPrice ??
                (store.isLive ? 'سجل المحادثة محفوظ.' : 'يبقى سجل المحادثة محفوظاً محلياً'),
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
              child: Text('ملف ${c.participant}'),
            ),
          if (!enabled)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                blocked
                    ? 'محظور — ألغِ الحظر من القائمة'
                    : 'الإعلان غير نشط، والرسائل الجديدة معطّلة.',
              ),
            ),
          if (!store.isLive)
            const Text(
              'على هذا الجهاز فقط · لا تُرسَل',
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
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.centerEnd,
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
                          '${timeLabel(m.at)} · ${m.incoming ? 'مستلمة' : 'مرسلة'}',
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
                        hintText: 'اكتب رسالة',
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
                    tooltip: 'إرسال',
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
  String reason = 'محتوى مشبوه';
  final details = TextEditingController();
  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(
      DemoScope.of(context).isLive ? 'إبلاغ' : 'إبلاغ محلي',
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          DemoScope.of(context).isLive
              ? 'يُرسَل هذا البلاغ إلى فريق إشراف «سوقنا» للمراجعة.'
              : 'يُوثَّق هذا الإبلاغ على هذا الجهاز فقط، ولن يُرسَل إلى «سوقنا» أو السلطات أو أي شخص آخر.',
        ),
        for (final value in [
          'محتوى مشبوه',
          'رسالة غير لائقة',
          'اشتباه بالاحتيال',
          'أخرى',
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
            labelText: 'التفاصيل (اختياري، بدون بيانات حساسة)',
          ),
        ),
        PrimaryButton(
          DemoScope.of(context).isLive ? 'إرسال البلاغ' : 'توثيق محلي فقط',
          onPressed: () {
            final live = DemoScope.of(context).isLive;
            DemoScope.of(context).report(
              target: widget.target,
              reason: reason,
              details: details.text,
            );
            Navigator.pop(context);
            if (!live) {
              toast(context, 'تم التوثيق محلياً، ولم يُرسَل شيء.');
            }
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
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
        'الإشعارات',
        actions: [
          IconButton(
            tooltip: 'إعدادات الإشعارات',
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
                    'لا تنبيهات',
                    'تظهر هنا أحداث الإنشاء المحلية ورسائل المحاكاة.',
                  ),
                  TextButton(
                    onPressed: store.seedNotice,
                    child: const Text('إضافة تنبيه تجريبي'),
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
                    subtitle: const Text('حدث محلي'),
                    trailing: IconButton(
                      tooltip: 'إزالة التنبيه',
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
                          toast(context, 'الإعلان لم يعد متاحاً');
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
      appBar: const PageHeader('الإشعارات'),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              store.isLive
                  ? 'تُطبق هذه الإعدادات على تنبيهاتك داخل التطبيق.'
                  : 'إعدادات محلية فقط: لا رسائل بريد إلكتروني أو إشعارات فورية حقيقية، ولا تغيير في أذونات أندرويد أو المتصفح.',
            ),
          ),
          SwitchListTile(
            title: const Text('تنبيهات محلية داخل التطبيق'),
            value: store.localAlerts,
            onChanged: (v) => store.setNotifications(alerts: v),
          ),
          SwitchListTile(
            title: const Text('تفضيل البريد الإلكتروني (يُحفَظ فقط)'),
            subtitle: const Text('لن يُرسَل أي بريد إلكتروني.'),
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
    appBar: const PageHeader('نسيت كلمة المرور'),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'لا تُحفَظ أي كلمة مرور حقيقية',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        const Text(
          'هذا العرض التجريبي بلا اتصال لا يتحقق من هوية أحد، ولا تُحفَظ أو تُرسَل كلمة المرور أو البريد الإلكتروني. لذلك لا توجد استعادة ولا رمز ولا بريد إلكتروني أو رسالة نصية. استخدم بيانات وهمية فقط عند الدخول المحلي.',
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          'العودة إلى الدخول المحلي',
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
      appBar: PageHeader(
        store.isLive ? 'البيانات والحدود' : 'البيانات المحلية والحدود',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            store.isLive
                ? 'بياناتك على «سوقنا»'
                : 'عرض تجريبي دون اتصال، وليس سوقاً حقيقياً',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            store.isLive
                ? 'تُحفَظ إعلاناتك وملفك ومحادثاتك ومفضلتك على خوادم «سوقنا». بعض التفضيلات (المظهر، التنبيهات، مسودات الرسائل) تبقى على هذا الجهاز. تسجيل الخروج يخفي الميزات الخاصة ولا يحذف بيانات حسابك.'
                : 'تبقى الإعلانات والمسودات والصور والملف الشخصي والمحادثات والمفضلة والبحوث المحفوظة والسجل والإعدادات محلية على هذا الجهاز أو على أصل هذا المتصفح. تسجيل الخروج يخفي الميزات الخاصة لكنه لا يحذف البيانات. الدخول المحلي مجدداً يفتح الملف التجريبي نفسه؛ وهذا ليس فصلاً آمناً بين الحسابات.',
          ),
          const SizedBox(height: 12),
          if (!store.isLive)
            const Text(
              'لا حسابات ولا رسائل ولا بريد إلكتروني ولا إشعارات فورية ولا نشر ولا إشراف ولا توثيق ولا مدفوعات ولا توصيل ولا مزامنة سحابية حقيقية. غير مناسب للبيانات السرية أو المهمة. مسح بيانات المتصفح ووضع التصفح الخاص وإزالة التثبيت قد تحذف البيانات. يحتاج الويب إلى تثبيت أول كامل وأنت متصل؛ فذاكرة التخزين المؤقت الفارغة دون اتصال لا تستطيع تشغيل التطبيق.',
            ),
          const SizedBox(height: 12),
          Text(
            store.storageError ??
                (store.persistenceAvailable
                    ? 'التخزين المحلي متاح. تُنفَّذ عمليات الكتابة بترتيبها، دون ضمان الصمود الكامل عند التعطل.'
                    : 'ذاكرة مؤقتة فقط — دون تخزين متاح على الجهاز تضيع التغييرات عند إعادة التشغيل.'),
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
                      ? 'اكتمل الحفظ المحلي'
                      : 'فشل الحفظ؛ تبقى البيانات في الذاكرة.',
                );
              }
            },
            child: const Text('إعادة محاولة الحفظ'),
          ),
          RowLink(
            'معلومات الملف الشخصي',
            icon: Icons.person_outline,
            onTap: store.signedIn
                ? () => go(context, EditProfilePage(initial: store.name))
                : null,
            subtitle: store.signedIn ? null : 'استخدم الدخول المحلي من «حسابي»',
          ),
          RowLink(
            store.isLive ? 'الأمان' : 'الأمان المحلي',
            icon: Icons.shield_outlined,
            onTap: () => go(context, const LocalSafetyPage()),
          ),
          const Divider(),
          TextButton(
            onPressed: () async {
              if (!await confirmLocal(
                context,
                store.isLive
                    ? 'إعادة تعيين بيانات التطبيق؟'
                    : 'إعادة تعيين بيانات العرض المحلية؟',
                store.isLive
                    ? 'يمسح الذاكرة المؤقتة والتفضيلات المحفوظة على هذا الجهاز، ويسجّل خروجك. لا يحذف حسابك أو إعلاناتك.'
                    : 'يزيل الملف الشخصي والإعلانات والمسودات والصور المستوردة والمحادثات والإبلاغات والتنبيهات والمفضلة والبحوث المحفوظة والمتابَعات والسجل والخصوصية والمظهر على هذا الجهاز. لا حسابات حقيقية ولا مفاتيح تطبيقات خارجية. سيتم تسجيل خروجك محلياً.',
                action: 'إعادة تعيين الكل',
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
                    'تعذّر حفظ إعادة التعيين بشكل دائم، يرجى المحاولة مجدداً.',
                  );
                }
              }
            },
            child: Text(
              store.isLive
                  ? 'إعادة تعيين بيانات التطبيق'
                  : 'إعادة تعيين بيانات العرض المحلية',
            ),
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
      appBar: const PageHeader('الأمان المحلي'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'لا تُدخل بيانات حساسة. الإبلاغ يُسجَّل محلياً فقط، والحظر المحلي هنا قابل للتراجع عن قصد. هذا ليس بديلاً عن إشراف حقيقي أو مساعدة طارئة.',
          ),
          const SectionHeading('المشاركون المحظورون محلياً'),
          if (store.blockedParticipants.isEmpty)
            const Text('لا يوجد حظر محلي.'),
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
                child: const Text('إلغاء الحظر'),
              ),
            ),
          SectionHeading('الإبلاغات المحلية (${store.reports.length})'),
          for (final r in store.reports)
            ListTile(
              title: Text(r['reason'] as String? ?? 'إبلاغ'),
              subtitle: Text('محلي فقط · ${r['details'] ?? ''}'),
            ),
        ],
      ),
    );
  }
}
