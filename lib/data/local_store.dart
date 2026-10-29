part of 'demo_store.dart';

class DemoStore extends ChangeNotifier {
  DemoStore({this.preferences, this.writeSnapshot, String? startupError}) {
    _temporaryStorage =
        preferences == null && writeSnapshot == null && startupError != null;
    storageError = startupError;
    final raw = preferences?.get(storageKey);
    if (raw is String) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final version = data['version'] as int? ?? 1;
        if (version > 2) {
          readOnlyStorage = true;
          storageError =
              'إصدار بيانات أحدث. حدّث التطبيق؛ البيانات تبقى كما هي.';
        } else {
          _restore(data);
        }
      } catch (_) {
        storageError =
            'بعض البيانات المحلية غير مقروءة. البيانات الصالحة محفوظة، ويمكن إعادة التعيين من الإعدادات.';
        _legacy();
      }
    } else {
      if (raw != null) {
        storageError =
            'سجل بيانات محلي غير صالح؛ تم فحص الإعدادات القديمة.';
      }
      _legacy();
    }
    _recoveryWarning = storageError;
  }

  static const storageKey = 'marketplace.v2';
  static const legacyKeys = [
    'theme',
    'consent',
    'personalized',
    'analytics',
    'favorites',
    'saved_searches',
  ];
  final SharedPreferences? preferences;
  final Future<bool> Function(String)? writeSnapshot;
  bool _temporaryStorage = false;
  ThemeMode themeMode = ThemeMode.system;
  bool consentAccepted = false, personalized = false, analytics = false;
  bool signedIn = false, commercial = false, newsletter = false;
  bool get isLive => false; // BackendStore overrides → real API mode
  bool localAlerts = true, emailPreference = false;
  bool readOnlyStorage = false;
  String name = 'بائع تجريبي';
  int selectedTab = 0;
  String query = '';
  SearchFilters filters = SearchFilters();
  final Set<String> favorites = {},
      followedSellers = {},
      blockedParticipants = {};
  final List<SavedSearch> savedSearches = [];
  final List<String> searchHistory = [], recentlyViewed = [];
  final List<Listing> ownListings = [];
  final List<ListingDraft> drafts = [];
  final List<Conversation> conversations = [];
  final List<LocalNotice> notifications = [];
  final List<Map<String, dynamic>> reports = [];
  String? storageError;
  String? _recoveryWarning;
  bool _writeFailed = false;
  Future<void> _writes = Future.value();
  bool _disposed = false;
  int _sequence = 0;
  String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _legacy() {
    T? read<T>(String key) {
      final value = preferences?.get(key);
      if (value == null || value is T) return value as T?;
      storageError =
          'بعض الإعدادات القديمة غير مقروءة وتم تجاوزها.';
      return null;
    }

    themeMode =
        ThemeMode.values
            .where((m) => m.name == read<String>('theme'))
            .firstOrNull ??
        ThemeMode.system;
    consentAccepted = read<bool>('consent') ?? false;
    personalized = read<bool>('personalized') ?? false;
    analytics = read<bool>('analytics') ?? false;
    favorites.addAll(read<List<String>>('favorites') ?? []);
    for (final encoded in read<List<String>>('saved_searches') ?? <String>[]) {
      try {
        savedSearches.add(SavedSearch.decode(encoded));
      } catch (_) {
        storageError =
            'بحث محفوظ قديم غير مقروء وتم تجاوزه.';
      }
    }
  }

  void _restore(Map<String, dynamic> j) {
    void field(String key, void Function(dynamic) apply) {
      if (!j.containsKey(key)) return;
      try {
        apply(j[key]);
      } catch (_) {
        storageError =
            'بعض العناصر المحلية غير مقروءة وتم تجاوزها.';
      }
    }

    void records<T>(String key, List<T> target, T Function(dynamic) parse) {
      field(key, (v) {
        for (final row in v as List) {
          try {
            target.add(parse(row));
          } catch (_) {
            storageError =
                'بعض العناصر المحلية غير مقروءة وتم تجاوزها.';
          }
        }
      });
    }

    void strings(String key, dynamic target) => field(key, (v) {
      for (final item in v as List) {
        if (item is String) {
          target.add(item);
        } else {
          storageError = 'تم تجاوز عنصر غير صالح.';
        }
      }
    });
    field('theme', (v) => themeMode = ThemeMode.values.byName(v as String));
    field('consent', (v) => consentAccepted = v as bool);
    field('personalized', (v) => personalized = v as bool);
    field('analytics', (v) => analytics = v as bool);
    field('name', (v) {
      if (validateProfileName(v as String) != null) {
        throw const FormatException();
      }
      name = v;
    });
    field('commercial', (v) => commercial = v as bool);
    field('newsletter', (v) => newsletter = v as bool);
    field('localAlerts', (v) => localAlerts = v as bool);
    field('emailPreference', (v) => emailPreference = v as bool);
    strings('favorites', favorites);
    strings('following', followedSellers);
    strings('blocked', blockedParticipants);
    strings('history', searchHistory);
    strings('recent', recentlyViewed);
    records('searches', savedSearches, (v) => SavedSearch.decode(v as String));
    records(
      'listings',
      ownListings,
      (v) => Listing.fromJson(Map<String, dynamic>.from(v as Map)),
    );
    records(
      'drafts',
      drafts,
      (v) => ListingDraft.fromJson(Map<String, dynamic>.from(v as Map)),
    );
    records(
      'conversations',
      conversations,
      (v) => Conversation.fromJson(Map<String, dynamic>.from(v as Map)),
    );
    records(
      'notices',
      notifications,
      (v) => LocalNotice.fromJson(Map<String, dynamic>.from(v as Map)),
    );
    records('reports', reports, (v) => Map<String, dynamic>.from(v as Map));
    final ids = <String>{};
    ownListings.removeWhere(
      (l) => !ids.add(l.id) || listings.any((f) => f.id == l.id),
    );
    final threads = <String>{};
    conversations.removeWhere((c) => !threads.add(c.id));
    favorites.removeWhere((id) => findListing(id) == null);
    recentlyViewed.removeWhere((id) => findListing(id) == null);
  }

  Map<String, dynamic> snapshot() => {
    'version': 2,
    'theme': themeMode.name,
    'consent': consentAccepted,
    'personalized': personalized,
    'analytics': analytics,
    'name': name,
    'commercial': commercial,
    'newsletter': newsletter,
    'localAlerts': localAlerts,
    'emailPreference': emailPreference,
    'favorites': favorites.toList(),
    'following': followedSellers.toList(),
    'blocked': blockedParticipants.toList(),
    'history': searchHistory,
    'recent': recentlyViewed,
    'searches': savedSearches.map((s) => s.encode()).toList(),
    'listings': ownListings.map((l) => l.toJson()).toList(),
    'drafts': drafts.map((d) => d.toJson()).toList(),
    'conversations': conversations.map((c) => c.toJson()).toList(),
    'notices': notifications.map((n) => n.toJson()).toList(),
    'reports': reports,
  };

  void _save() {
    _notify();
    if (readOnlyStorage) return;
    final encoded = jsonEncode(snapshot());
    _writes = _writes.then((_) async {
      try {
        final ok = writeSnapshot != null
            ? await writeSnapshot!(encoded)
            : preferences != null
            ? await preferences!.setString(storageKey, encoded)
            : !_temporaryStorage;
        if (!ok) throw StateError('write rejected');
        _writeFailed = false;
        storageError = _recoveryWarning;
      } catch (_) {
        _writeFailed = true;
        storageError =
            'فشل الحفظ. التغييرات في الذاكرة مؤقتًا فقط. حاول مرة أخرى.';
      }
      _notify();
    });
  }

  Future<bool> flush() async {
    await _writes;
    return !_writeFailed && !readOnlyStorage;
  }

  Future<bool> retrySave() {
    _save();
    return flush();
  }

  bool get persistenceAvailable => preferences != null || writeSnapshot != null;
  Set<String> get mediaReferences => {
    for (final l in ownListings)
      ...l.gallery.where((s) => s.startsWith('media-')),
    for (final d in drafts)
      if (d.values['images'] is List)
        ...(d.values['images'] as List).whereType<String>().where(
          (s) => s.startsWith('media-'),
        ),
  };
  Iterable<Listing> get catalog => [...ownListings, ...listings];
  Listing? findListing(String id) =>
      catalog.where((l) => l.id == id).firstOrNull;
  bool isOwn(String id) => ownListings.any((l) => l.id == id);
  bool canContact(String id) =>
      findListing(id)?.status == ListingStatus.active && !isOwn(id);
  List<Listing> sellerListings(String identity) => catalog
      .where((l) => l.identity == identity && l.status == ListingStatus.active)
      .toList();
  List<DemoMessage> get messages =>
      signedIn ? conversations.expand((c) => c.messages).toList() : [];
  List<Listing> results({SearchFilters? using}) {
    final f = using ?? filters;
    final result = catalog
        .where(
          (l) =>
              l.status == ListingStatus.active &&
              f.accepts(l) &&
              _matchesQuery(l, query),
        )
        .toList();
    switch (f.sort) {
      case 'الأقل سعراً':
        result.sort((a, b) => a.price.compareTo(b.price));
      case 'الأعلى سعراً':
        result.sort((a, b) => b.price.compareTo(a.price));
      case 'الأحدث':
        result.sort((a, b) => a.ageHours.compareTo(b.ageHours));
      default:
        result.sort(
          (a, b) => (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0),
        );
    }
    return result;
  }

  bool _matchesQuery(Listing listing, String value) {
    final text = _searchText(
      '${listing.title} ${listing.category} ${listing.description}',
    );
    return _searchText(value.trim()).split(RegExp(r'\s+')).every(text.contains);
  }

  void changeFilters(SearchFilters value) {
    filters = value.copy();
    _notify();
  }

  void search(String value) {
    query = value.trim();
    if (query.isNotEmpty) {
      searchHistory.remove(query);
      searchHistory.insert(0, query);
      if (searchHistory.length > 30) searchHistory.removeLast();
    }
    _save();
  }

  void changeTab(int value) {
    selectedTab = value;
    _notify();
  }

  void toggleFavorite(String id) {
    if (findListing(id) == null) return;
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    _save();
  }

  void saveSearch({SavedSearch? snapshot}) {
    final saved = snapshot ?? SavedSearch(query, filters);
    if (!savedSearches.any(
      (s) =>
          s.query == saved.query &&
          jsonEncode(s.filters.toJson()) == jsonEncode(saved.filters.toJson()),
    )) {
      savedSearches.insert(0, saved);
    }
    _save();
  }

  void deleteSearch(SavedSearch s) {
    savedSearches.remove(s);
    _save();
  }

  void toggleSearchAlerts(SavedSearch s) {
    s.alerts = !s.alerts;
    _save();
  }

  void restoreSearch(SavedSearch saved) {
    query = saved.query;
    filters = saved.filters.copy();
    _notify();
  }

  void setTheme(ThemeMode value) {
    themeMode = value;
    _save();
  }

  void acceptConsent({bool all = false}) {
    consentAccepted = true;
    personalized = all;
    analytics = all;
    _save();
  }

  void setPrivacy({required bool personalized, required bool analytics}) {
    this.personalized = personalized;
    this.analytics = analytics;
    _save();
  }

  void signIn() {
    signedIn = true;
    _notify();
  }

  void registerLocal(
    String value, {
    required bool business,
    bool news = false,
  }) {
    updateProfile(value, business: business);
    newsletter = news;
    signedIn = true;
    _save();
  }

  bool updateProfile(String value, {bool? business}) {
    if (validateProfileName(value) != null) return false;
    name = value.trim();
    commercial = business ?? commercial;
    for (var i = 0; i < ownListings.length; i++) {
      ownListings[i] = ownListings[i].copyWith(
        seller: name,
        sellerId: 'self',
        commercial: commercial,
      );
    }
    _save();
    return true;
  }

  void signOut() {
    signedIn = false;
    selectedTab = 0;
    _notify();
  }

  void publish(Listing l, {String? draftId}) {
    if (ownListings.any((a) => a.id == l.id)) return;
    ownListings.insert(
      0,
      l.copyWith(seller: name, sellerId: 'self', commercial: commercial),
    );
    drafts.removeWhere((d) => d.id == draftId);
    selectedTab = 4;
    _notice('تم إنشاء الإعلان', listingId: l.id);
    final published = ownListings.first;
    for (final saved in savedSearches) {
      if (saved.alerts &&
          published.status == ListingStatus.active &&
          saved.filters.accepts(published) &&
          _matchesQuery(published, saved.query)) {
        _notice(
          'نتيجة جديدة لبحثك: ${saved.query.isEmpty ? saved.filters.category : saved.query}',
          listingId: l.id,
        );
      }
    }
    _save();
  }

  bool editListing(Listing l, {String? draftId}) {
    if (!signedIn) return false;
    final i = ownListings.indexWhere((a) => a.id == l.id);
    if (i < 0) return false;
    ownListings[i] = l.copyWith(
      seller: name,
      sellerId: 'self',
      commercial: commercial,
    );
    drafts.removeWhere((d) => d.id == draftId);
    _save();
    return true;
  }

  void setListingStatus(String id, ListingStatus status) {
    if (!signedIn) return;
    final l = findListing(id);
    if (l == null || !isOwn(id)) return;
    editListing(l.copyWith(status: status));
  }

  void deleteListing(String id) {
    if (!signedIn || !isOwn(id)) return;
    ownListings.removeWhere((l) => l.id == id);
    favorites.remove(id);
    recentlyViewed.remove(id);
    drafts.removeWhere((d) => d.editingId == id);
    _save();
  }

  void saveDraft(ListingDraft d) {
    drafts.removeWhere((a) => a.id == d.id);
    drafts.insert(0, d);
    _save();
  }

  void deleteDraft(String id) {
    drafts.removeWhere((d) => d.id == id);
    _save();
  }

  void viewListing(String id) {
    if (findListing(id) == null) return;
    recentlyViewed.remove(id);
    recentlyViewed.insert(0, id);
    if (recentlyViewed.length > 30) recentlyViewed.removeLast();
    _save();
  }

  void clearRecent() {
    recentlyViewed.clear();
    _save();
  }

  void clearHistory() {
    searchHistory.clear();
    _save();
  }

  void toggleFollow(String identity) {
    if (identity == 'self') return;
    followedSellers.contains(identity)
        ? followedSellers.remove(identity)
        : followedSellers.add(identity);
    _save();
  }

  Conversation ensureConversation(
    Listing l, {
    String? participantId,
    String? participant,
  }) {
    final pid = participantId ?? l.identity;
    final existing = conversations
        .where((c) => c.listingId == l.id && c.participantId == pid)
        .firstOrNull;
    if (existing != null) return existing;
    final c = Conversation(
      id: newId('chat'),
      listingId: l.id,
      participantId: pid,
      participant: participant ?? l.seller,
      listingTitle: l.title,
    );
    conversations.add(c);
    _save();
    return c;
  }

  Conversation? findConversation(String id) =>
      conversations.where((c) => c.id == id).firstOrNull;
  List<String> messagesFor(String listingId) => conversations
      .where((c) => c.listingId == listingId)
      .expand((c) => c.messages)
      .map((m) => m.text)
      .toList();
  void addMessage(String listingId, String text) {
    if (text.trim().isEmpty) return;
    final l = findListing(listingId);
    if (l == null) return;
    sendMessage(ensureConversation(l).id, text);
  }

  bool sendMessage(String id, String text, {bool incoming = false}) {
    final c = findConversation(id);
    if (c == null ||
        text.trim().isEmpty ||
        text.length > 2000 ||
        blockedParticipants.contains(c.participantId) ||
        findListing(c.listingId)?.status != ListingStatus.active) {
      return false;
    }
    c.messages.add(
      DemoMessage(
        listingId: c.listingId,
        text: text.trim(),
        incoming: incoming,
      ),
    );
    c.archived = false;
    if (incoming) {
      c.unread++;
      _notice('رسالة جديدة من ${c.participant}', threadId: c.id);
    } else {
      c.draft = '';
    }
    _save();
    return true;
  }

  void seedConversations() {
    if (conversations.isNotEmpty || !signedIn) return;
    final c = ensureConversation(listings.first);
    sendMessage(
      c.id,
      'مرحبًا! هذه رسالة تجريبية واردة.',
      incoming: true,
    );
    final d = ensureConversation(listings[8]);
    sendMessage(d.id, 'هل يمكن الاستلام شخصيًا؟ (تجريبي)');
  }

  void setChatDraft(String id, String text) {
    final c = findConversation(id);
    if (c == null) return;
    c.draft = text;
    _save();
  }

  void markRead(String id) {
    final c = findConversation(id);
    if (c == null || c.unread == 0) return;
    c.unread = 0;
    _save();
  }

  void archiveChat(String id, bool value) {
    final c = findConversation(id);
    if (c == null) return;
    c.archived = value;
    _save();
  }

  void deleteChat(String id) {
    conversations.removeWhere((c) => c.id == id);
    _save();
  }

  void toggleBlock(String participantId) {
    blockedParticipants.contains(participantId)
        ? blockedParticipants.remove(participantId)
        : blockedParticipants.add(participantId);
    _save();
  }

  void report({
    required String target,
    required String reason,
    String details = '',
  }) {
    reports.add({
      'id': newId('report'),
      'target': target,
      'reason': reason,
      'details': details.trim(),
      'at': DateTime.now().toIso8601String(),
    });
    _save();
  }

  void _notice(String title, {String? listingId, String? threadId}) {
    if (!localAlerts) return;
    notifications.insert(
      0,
      LocalNotice(
        id: newId('notice'),
        title: title,
        listingId: listingId,
        threadId: threadId,
      ),
    );
  }

  void seedNotice() {
    _notice('أهلًا بك في سوقنا');
    _save();
  }

  void readNotice(LocalNotice n) {
    n.read = true;
    _save();
  }

  void dismissNotice(LocalNotice n) {
    notifications.remove(n);
    _save();
  }

  void setNotifications({bool? alerts, bool? email}) {
    localAlerts = alerts ?? localAlerts;
    emailPreference = email ?? emailPreference;
    _save();
  }

  Future<bool> resetLocalData() async {
    if (readOnlyStorage) return false;
    ownListings.clear();
    drafts.clear();
    conversations.clear();
    notifications.clear();
    favorites.clear();
    savedSearches.clear();
    followedSellers.clear();
    blockedParticipants.clear();
    searchHistory.clear();
    recentlyViewed.clear();
    reports.clear();
    signedIn = false;
    selectedTab = 0;
    name = 'بائع تجريبي';
    commercial = false;
    newsletter = false;
    localAlerts = true;
    emailPreference = false;
    themeMode = ThemeMode.system;
    consentAccepted = false;
    personalized = false;
    analytics = false;
    query = '';
    filters = SearchFilters();
    _recoveryWarning = null;
    _save();
    final ok = await flush();
    if (ok && preferences != null) {
      for (final key in legacyKeys) {
        if (!await preferences!.remove(key)) {
          storageError = 'تعذّر حذف الإعدادات القديمة.';
          _notify();
          return false;
        }
      }
    }
    return ok;
  }

  static String _searchText(String value) => value
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp('[\u064B-\u0652\u0640]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
