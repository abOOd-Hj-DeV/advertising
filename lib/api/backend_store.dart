import 'dart:async';

import 'package:flutter/material.dart';

import '../data/demo_store.dart';
import '../data/media.dart';
import 'api_client.dart';
import 'api_store.dart';

/// DemoStore whose data paths go through the real /api/v1 backend.
///
/// Screens keep the synchronous DemoStore surface: mutations update local
/// state optimistically, then sync to the server; server loads replace the
/// cached collections and notify listeners. Local-only preferences (theme,
/// consent, history, drafts) keep using DemoStore persistence.
class BackendStore extends DemoStore {
  BackendStore(this.api, {super.preferences, super.writeSnapshot}) {
    signedIn = api.isAuthenticated;
    final user = api.user;
    if (user != null) _applyUser(user);
    unawaited(_bootstrap());
  }

  final ApiStore api;
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  final List<Listing> _remote = [];
  final Map<String, Listing> _cache = {};
  final Map<String, String> _categoryIds = {}; // Arabic name → id
  final Map<String, String> _leafFor = {}; // category id → publishable leaf id
  final Map<String, ({String id, String governorate})> _cities = {};
  final Map<String, String> _serverConversation = {}; // local id → server id
  final Map<String, String> _savedSearchIds = {}; // encode() → server id
  Timer? _poll;
  String? _cursor;
  bool loading = false, loadingMore = false;
  String? lastError;
  int _searchSeq = 0;

  ApiClient get _client => api.client;

  // ── Read paths ───────────────────────────────────────────
  @override
  Iterable<Listing> get catalog => [
    ...ownListings,
    ..._remote.where((l) => !isOwn(l.id)),
    ..._cache.values.where(
      (l) => !isOwn(l.id) && !_remote.any((r) => r.id == l.id),
    ),
  ];

  @override
  List<Listing> results({SearchFilters? using}) {
    if (using != null && !identical(using, filters)) {
      return super.results(using: using);
    }
    return _remote.where((l) => l.status == ListingStatus.active).toList();
  }

  bool get hasMore => _cursor != null;

  Future<void> _bootstrap() async {
    await Future.wait([_loadCatalog(), _loadLocations()]);
    await refreshResults();
    if (signedIn) await _loadAccount();
  }

  Future<void> _loadCatalog() async {
    try {
      final tree = await api.repos.categories();
      for (final node in tree.cast<Map<String, dynamic>>()) {
        final id = node['id'] as String;
        _categoryIds[node['name'] as String] = id;
        final children = (node['children'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        for (final child in children) {
          _categoryIds[child['name'] as String] = child['id'] as String;
          _categoryIds[child['slug'] as String] = child['id'] as String;
          _leafFor[child['id'] as String] = child['id'] as String;
        }
        _categoryIds[node['slug'] as String] = id;
        _leafFor[id] = children.isEmpty
            ? id
            : (children.last['id'] as String); // "other"-style leaf last
      }
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _loadLocations() async {
    try {
      final groups = await api.repos.locations();
      for (final g in groups.cast<Map<String, dynamic>>()) {
        final gov = g['governorate'] as String;
        for (final c in (g['cities'] as List).cast<Map<String, dynamic>>()) {
          _cities.putIfAbsent(
            c['city'] as String,
            () => (id: c['id'] as String, governorate: gov),
          );
        }
      }
    } catch (e) {
      _fail(e);
    }
  }

  /// UI category labels (app taxonomy) → backend category slugs.
  static const _categorySlugs = {
    'سيارات ودراجات وقوارب': 'vehicles',
    'سيارات': 'cars',
    'دراجات نارية': 'motorcycles',
    'دراجات نارية وسكوتر': 'motorcycles',
    'قطع غيار وإطارات': 'auto-parts',
    'عقارات': 'real-estate',
    'المنزل والحديقة': 'furniture',
    'أزياء وجمال': 'fashion',
    'إلكترونيات': 'electronics',
    'حيوانات أليفة': 'pets',
    'العائلة والأطفال': 'kids-clothing',
    'وظائف': 'jobs',
    'هوايات ومجتمع': 'hobbies',
    'موسيقى وأفلام وكتب': 'books-media',
    'دراجات وملحقات': 'sports',
    'خدمات': 'services',
    'دروس ودورات': 'education-services',
    'مساعدة الجيران': 'services',
  };

  String? _categoryId(String label) =>
      _categoryIds[label] ?? _categoryIds[_categorySlugs[label] ?? ''];

  static const _sorts = {
    'الأحدث': 'newest',
    'الأقل سعراً': 'price_asc',
    'الأعلى سعراً': 'price_desc',
  };

  Map<String, String> _searchQuery(SearchFilters f, String q) {
    final category = _categoryId(f.category);
    final city = _cities[f.city];
    final max = f.maximum == null
        ? null
        : f.maximum! * (f.extraBudget ? 1.15 : 1);
    return {
      if (q.trim().isNotEmpty) 'q': q.trim(),
      'category': ?category,
      if (city != null) 'governorate': city.governorate,
      if (city != null) 'city': f.city,
      if (f.minimum != null) 'price_min': '${(f.minimum! * 100).round()}',
      if (max != null) 'price_max': '${(max * 100).round()}',
      'sort': _sorts[f.sort] ?? 'recommended',
      if (f.seller == 'فردي') 'seller_type': 'private',
      if (f.seller == 'تجاري') 'seller_type': 'commercial',
      if (f.offer == 'عروض') 'offer_type': 'offer',
      if (f.offer == 'طلبات') 'offer_type': 'wanted',
      if (f.shipping == 'شحن متاح') 'shipping': 'only',
      'limit': '20',
    };
  }

  Future<void> refreshResults() async {
    final seq = ++_searchSeq;
    loading = true;
    notifyListeners();
    try {
      final res = await _client.get('/listings', _searchQuery(filters, query));
      if (seq != _searchSeq) return;
      _remote
        ..clear()
        ..addAll(_mapList(res['data']));
      _cursor = res['next_cursor'] as String?;
      lastError = null;
    } catch (e) {
      if (seq == _searchSeq) _fail(e);
    } finally {
      if (seq == _searchSeq) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_cursor == null || loadingMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      final res = await _client.get('/listings', {
        ..._searchQuery(filters, query),
        'cursor': _cursor!,
      });
      _remote.addAll(_mapList(res['data']));
      _cursor = res['next_cursor'] as String?;
    } catch (e) {
      _fail(e);
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  @override
  void changeFilters(SearchFilters value) {
    super.changeFilters(value);
    unawaited(refreshResults());
  }

  @override
  void search(String value) {
    super.search(value);
    unawaited(refreshResults());
  }

  @override
  void viewListing(String id) {
    super.viewListing(id);
    if (id.length != 26) return;
    unawaited(() async {
      try {
        final full = _map(await api.repos.listing(id));
        _cache[id] = full;
        final i = _remote.indexWhere((l) => l.id == id);
        if (i >= 0) _remote[i] = full;
        notifyListeners();
      } catch (_) {}
    }());
  }

  // ── Auth ─────────────────────────────────────────────────
  void _applyUser(Map<String, dynamic> user) {
    name = user['display_name'] as String? ?? name;
    commercial = user['account_type'] == 'commercial';
  }

  /// Real sign-in / registration. Returns an Arabic error message or null.
  Future<String?> authenticate({
    required bool register,
    required String email,
    required String password,
    String? displayName,
    bool business = false,
    bool news = false,
  }) async {
    try {
      if (register) {
        final res = await _client.post('/auth/register', body: {
          'email': email.trim(),
          'password': password,
          'password_confirmation': password,
          'display_name': (displayName ?? '').trim(),
          'account_type': business ? 'commercial' : 'private',
          'accept_terms_version': '2026-10',
        });
        await api.session.adopt(res);
      } else {
        await api.login(email.trim(), password);
      }
      final user = api.user;
      if (user != null) _applyUser(user);
      newsletter = news;
      super.signIn();
      await _loadAccount();
      return null;
    } on ApiException catch (e) {
      final first = e.errors?.values.expand((v) => v).firstOrNull;
      return first ?? e.detail;
    } catch (_) {
      return 'تعذّر الاتصال بالخادم. تحقّق من الإنترنت وحاول مجددًا.';
    }
  }

  @override
  void signOut() {
    _poll?.cancel();
    unawaited(api.logout());
    ownListings.clear();
    favorites.clear();
    conversations.clear();
    notifications.clear();
    savedSearches.clear();
    followedSellers.clear();
    blockedParticipants.clear();
    _serverConversation.clear();
    _savedSearchIds.clear();
    super.signOut();
  }

  @override
  bool updateProfile(String value, {bool? business}) {
    final ok = super.updateProfile(value, business: business);
    if (ok && signedIn) {
      unawaited(
        _client
            .patch('/me', body: {'display_name': value.trim()})
            .catchError((Object e) { _fail(e); return <String, dynamic>{}; }),
      );
    }
    return ok;
  }

  Future<void> _loadAccount() async {
    await Future.wait([
      _loadOwnListings(),
      _loadFavorites(),
      _loadSavedSearches(),
      _loadFollows(),
      _loadBlocks(),
      refreshConversations(),
      refreshNotifications(),
    ]);
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!signedIn) return;
      unawaited(refreshConversations());
      unawaited(refreshNotifications());
    });
  }

  Future<void> _loadOwnListings() async {
    try {
      final res = await _client.get('/me/listings', {'limit': '50'});
      ownListings
        ..clear()
        ..addAll(_mapList(res['data'], own: true));
      notifyListeners();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final res = await api.repos.favorites();
      final items = _mapList(res['data']);
      for (final l in items) {
        _cache[l.id] = l;
      }
      favorites
        ..clear()
        ..addAll(items.map((l) => l.id));
      notifyListeners();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _loadFollows() async {
    try {
      final res = await _client.get('/follows');
      followedSellers
        ..clear()
        ..addAll(
          (res['data'] as List? ?? []).map(
            (f) => ((f as Map)['user'] as Map?)?['id'] as String? ??
                f['id'] as String,
          ),
        );
    } catch (_) {}
  }

  Future<void> _loadBlocks() async {
    try {
      final res = await _client.get('/blocks');
      blockedParticipants
        ..clear()
        ..addAll(
          (res['data'] as List? ?? []).map(
            (b) => ((b as Map)['user'] as Map?)?['id'] as String? ??
                b['id'] as String,
          ),
        );
    } catch (_) {}
  }

  Future<void> _loadSavedSearches() async {
    try {
      final res = await _client.get('/saved-searches');
      savedSearches.clear();
      _savedSearchIds.clear();
      for (final s in (res['data'] as List? ?? []).cast<Map>()) {
        final raw = Map<String, dynamic>.from(s['filters'] as Map? ?? {});
        final saved = SavedSearch(
          s['query'] as String? ?? '',
          SearchFilters.fromJson(
            Map<String, dynamic>.from(raw['app'] as Map? ?? {}),
          ),
        )..alerts = s['alerts_enabled'] as bool? ?? true;
        savedSearches.add(saved);
        _savedSearchIds[saved.encode()] = s['id'] as String;
      }
      notifyListeners();
    } catch (_) {}
  }

  // ── Listings (own) ───────────────────────────────────────
  @override
  void publish(Listing l, {String? draftId}) {
    if (!signedIn) return;
    super.publish(l, draftId: draftId);
    unawaited(_create(ownListings.first));
  }

  Future<void> _create(Listing local) async {
    try {
      final payload = await _payload(local);
      final created = await api.repos.createListing(payload, local.id);
      final mapped = _map(created, own: true);
      final i = ownListings.indexWhere((x) => x.id == local.id);
      if (i >= 0) ownListings[i] = mapped;
      favorites.remove(local.id);
      _toast('تم نشر الإعلان');
      notifyListeners();
    } catch (e) {
      ownListings.removeWhere((x) => x.id == local.id);
      _fail(e, prefix: 'لم يُنشر الإعلان: ');
      notifyListeners();
    }
  }

  @override
  bool editListing(Listing l, {String? draftId}) {
    final ok = super.editListing(l, draftId: draftId);
    if (ok && l.id.length == 26) unawaited(_update(l));
    return ok;
  }

  Future<void> _update(Listing l) async {
    try {
      final current = await api.repos.listing(l.id);
      final payload = await _payload(l);
      final updated = await api.repos.updateListing(
        l.id,
        payload,
        (current['version'] as num?)?.toInt() ?? 1,
      );
      final i = ownListings.indexWhere((x) => x.id == l.id);
      if (i >= 0) ownListings[i] = _map(updated, own: true);
      notifyListeners();
    } catch (e) {
      _fail(e, prefix: 'لم يُحفظ التعديل: ');
      await _loadOwnListings();
    }
  }

  @override
  void setListingStatus(String id, ListingStatus status) {
    final before = findListing(id)?.status;
    super.setListingStatus(id, status);
    if (before == null || before == status || id.length != 26) return;
    final action = switch ((before, status)) {
      (ListingStatus.active, ListingStatus.reserved) => 'reserve',
      (ListingStatus.reserved, ListingStatus.active) => 'unreserve',
      (ListingStatus.sold, ListingStatus.active) => 'reactivate',
      (_, ListingStatus.sold) => 'sell',
      _ => null,
    };
    if (action == null) return;
    unawaited(() async {
      try {
        await api.repos.transitionListing(id, action);
      } catch (e) {
        _fail(e);
        await _loadOwnListings();
      }
    }());
  }

  @override
  void deleteListing(String id) {
    super.deleteListing(id);
    if (id.length == 26) {
      unawaited(api.repos.deleteListing(id).onError((e, st) => _fail(e as Object)));
    }
  }

  Future<Map<String, dynamic>> _payload(Listing l) async {
    final categoryId = _categoryId(l.category) ?? _categoryIds['hobbies'];
    final city = _cities[l.city] ?? _cities['دمشق'];
    final media = <String>[];
    for (final ref in l.gallery) {
      if (!ref.startsWith('media-')) continue;
      final bytes = await MediaRepository.instance.get(ref);
      if (bytes == null) continue;
      final res = await _client.upload(
        '/media',
        bytes: bytes,
        filename: '$ref.jpg',
        idempotencyKey: ref,
      );
      media.add((res['data'] as Map)['id'] as String);
    }
    return {
      'category_id': _leafFor[categoryId] ?? categoryId,
      'offer_type': l.wanted ? 'wanted' : 'offer',
      'title': l.title,
      'description': l.description.trim().isEmpty ? l.title : l.description,
      'price_cents': l.priceType == PriceType.free
          ? null
          : (l.price * 100).round(),
      'currency': 'SYP',
      'price_type': l.priceType.name,
      'location_id': city?.id,
      'shipping_available': l.shipping,
      if (l.shipping) 'carrier': l.carrier,
      if (media.isNotEmpty) 'media_ids': media,
    };
  }

  // ── Engagement ───────────────────────────────────────────
  @override
  void toggleFavorite(String id) {
    final had = favorites.contains(id);
    super.toggleFavorite(id);
    if (!signedIn || id.length != 26) return;
    final call = had
        ? _client.delete('/favorites/$id')
        : _client.put('/favorites/$id');
    unawaited(
      call.then((_) {}).catchError((Object e) {
        had ? favorites.add(id) : favorites.remove(id);
        _fail(e);
      }),
    );
  }

  @override
  void saveSearch({SavedSearch? snapshot}) {
    final before = savedSearches.length;
    super.saveSearch(snapshot: snapshot);
    if (!signedIn || savedSearches.length == before) return;
    final saved = savedSearches.first;
    unawaited(() async {
      try {
        final res = await _client.post('/saved-searches', body: {
          'query': saved.query,
          'filters': {
            ..._searchQuery(saved.filters, saved.query)..remove('limit'),
            'app': saved.filters.toJson(),
          },
          'alerts_enabled': saved.alerts,
        });
        _savedSearchIds[saved.encode()] =
            (res['data'] as Map)['id'] as String;
      } catch (e) {
        _fail(e);
      }
    }());
  }

  @override
  void deleteSearch(SavedSearch s) {
    final id = _savedSearchIds.remove(s.encode());
    super.deleteSearch(s);
    if (id != null) {
      unawaited(_client.delete('/saved-searches/$id').onError((e, st) => _fail(e as Object)));
    }
  }

  @override
  void toggleSearchAlerts(SavedSearch s) {
    final id = _savedSearchIds.remove(s.encode());
    super.toggleSearchAlerts(s);
    if (id == null) return;
    _savedSearchIds[s.encode()] = id;
    unawaited(
      _client
          .patch('/saved-searches/$id', body: {'alerts_enabled': s.alerts})
          .catchError((Object e) {
            _fail(e);
            return <String, dynamic>{};
          }),
    );
  }

  @override
  void toggleFollow(String identity) {
    final had = followedSellers.contains(identity);
    super.toggleFollow(identity);
    if (!signedIn || identity.length != 26) return;
    unawaited(
      (had
              ? _client.delete('/follows/$identity')
              : _client.put('/follows/$identity'))
          .then((_) {})
          .onError((e, st) { _fail(e as Object); }),
    );
  }

  @override
  void toggleBlock(String participantId) {
    final had = blockedParticipants.contains(participantId);
    super.toggleBlock(participantId);
    if (!signedIn || participantId.length != 26) return;
    unawaited(
      (had
              ? _client.delete('/blocks/$participantId')
              : _client.put('/blocks/$participantId'))
          .then((_) {})
          .onError((e, st) { _fail(e as Object); }),
    );
  }

  static const _reasons = {
    'احتيال': 'fraud',
    'نصب': 'fraud',
    'غير قانوني': 'illegal',
    'ممنوع': 'prohibited_item',
    'إزعاج': 'harassment',
    'تحرش': 'harassment',
    'مسيء': 'harassment',
    'سبام': 'spam',
    'مزعج': 'spam',
    'مكرر': 'spam',
    'حقوق': 'ip_violation',
  };

  @override
  void report({
    required String target,
    required String reason,
    String details = '',
  }) {
    super.report(target: target, reason: reason, details: details);
    if (target.length != 26) return;
    final type = findListing(target) != null ? 'listing' : 'user';
    final code =
        _reasons.entries
            .where((e) => reason.contains(e.key))
            .map((e) => e.value)
            .firstOrNull ??
        'other';
    unawaited(
      _client
          .post('/reports', body: {
            'target_type': type,
            'target_id': target,
            'reason': code,
            'details': [
              reason,
              details.trim(),
            ].where((s) => s.isNotEmpty).join(' — '),
          })
          .then((_) => _toast('تم إرسال البلاغ للإدارة'))
          .onError((e, st) { _fail(e as Object); }),
    );
  }

  // ── Messaging ────────────────────────────────────────────
  Future<void> refreshConversations() async {
    if (!signedIn) return;
    try {
      final lists = await Future.wait([
        api.repos.conversations(),
        api.repos.conversations(archived: true),
      ]);
      final next = <Conversation>[];
      for (final res in lists) {
        for (final c in (res['data'] as List).cast<Map<String, dynamic>>()) {
          final id = c['id'] as String;
          final listing = Map<String, dynamic>.from(c['listing'] as Map);
          final other = Map<String, dynamic>.from(c['participant'] as Map);
          final cached = _cache[listing['id']] ?? _map(listing);
          _cache[cached.id] = cached;
          final old = conversations.where((x) => x.id == id).firstOrNull;
          final updated = DateTime.parse(c['updated_at'] as String);
          final needsFetch = old == null ||
              old.messages.isEmpty ||
              old.activity.isBefore(updated.subtract(const Duration(seconds: 1)));
          final messages = needsFetch ? await _messages(id) : old.messages;
          next.add(
            Conversation(
              id: id,
              listingId: listing['id'] as String,
              participantId: other['id'] as String,
              participant: other['display_name'] as String? ?? '',
              listingTitle: listing['title'] as String? ?? '',
              archived: c['archived'] as bool? ?? false,
              unread: (c['unread_count'] as num?)?.toInt() ?? 0,
              draft: old?.draft ?? '',
              messages: messages,
            ),
          );
        }
      }
      final pending = conversations.where(
        (c) => c.id.length != 26 && !_serverConversation.containsKey(c.id),
      );
      conversations
        ..clear()
        ..addAll(next)
        ..addAll(pending);
      notifyListeners();
    } catch (e) {
      if (e is ApiException && e.status == 401) return signOut();
    }
  }

  Future<List<DemoMessage>> _messages(String conversationId) async {
    final res = await api.repos.messages(conversationId, limit: 100);
    return (res['data'] as List).cast<Map<String, dynamic>>().map((m) {
      return DemoMessage(
        listingId: '',
        text: m['body'] as String? ?? '',
        incoming: !(m['is_mine'] as bool? ?? false),
        at: DateTime.parse(m['created_at'] as String).toLocal(),
      );
    }).toList();
  }

  @override
  bool sendMessage(String id, String text, {bool incoming = false}) {
    final ok = super.sendMessage(id, text, incoming: incoming);
    if (!ok || incoming || !signedIn) return ok;
    final c = findConversation(id);
    if (c == null) return ok;
    final clientId = newId('msg');
    unawaited(() async {
      try {
        final serverId = id.length == 26 ? id : _serverConversation[id];
        if (serverId == null) {
          final created = await api.repos.startConversation(
            c.listingId,
            text.trim(),
            clientId,
          );
          _serverConversation[id] = created['id'] as String;
        } else {
          await api.repos.sendMessage(serverId, text.trim(), clientId);
        }
        await refreshConversations();
      } catch (e) {
        _fail(e, prefix: 'لم تُرسل الرسالة: ');
      }
    }());
    return ok;
  }

  @override
  void markRead(String id) {
    super.markRead(id);
    final c = findConversation(id);
    if (c == null || id.length != 26) return;
    unawaited(() async {
      try {
        final res = await api.repos.messages(id, limit: 1);
        final last = (res['data'] as List).cast<Map>().lastOrNull;
        if (last != null) await api.repos.markRead(id, last['id'] as String);
      } catch (_) {}
    }());
  }

  @override
  void archiveChat(String id, bool value) {
    super.archiveChat(id, value);
    if (id.length != 26) return;
    unawaited(
      _client
          .patch('/conversations/$id', body: {'archived': value})
          .catchError((Object e) {
            _fail(e);
            return <String, dynamic>{};
          }),
    );
  }

  @override
  void deleteChat(String id) {
    super.deleteChat(id);
    if (id.length == 26) {
      unawaited(_client.delete('/conversations/$id').onError((e, st) => _fail(e as Object)));
    }
  }

  // ── Notifications ────────────────────────────────────────
  Future<void> refreshNotifications() async {
    if (!signedIn) return;
    try {
      final res = await api.repos.notifications();
      final items = (res['data'] as List).cast<Map<String, dynamic>>();
      notifications
        ..clear()
        ..addAll(items.map((n) {
          final data = Map<String, dynamic>.from(n['data'] as Map? ?? {});
          final title = switch (n['type']) {
            'new_message' =>
              'رسالة جديدة من ${data['sender'] ?? ''}: ${data['preview'] ?? ''}',
            'saved_search_matches' =>
              'إعلانات جديدة تطابق بحثك ${data['query'] ?? ''}'.trim(),
            _ => data['title'] as String? ?? 'إشعار جديد',
          };
          return LocalNotice(
            id: n['id'] as String,
            title: title,
            threadId: data['conversation_id'] as String?,
            listingId: data['listing_id'] as String?,
            read: n['read_at'] != null,
          );
        }));
      notifyListeners();
    } catch (_) {}
  }

  @override
  void readNotice(LocalNotice n) {
    super.readNotice(n);
    if (n.id.length > 26) {
      unawaited(
        _client
            .post('/notifications/${n.id}/read')
            .then((_) {})
            .catchError((_) {}),
      );
    }
  }

  // ── Mapping ──────────────────────────────────────────────
  List<Listing> _mapList(Object? data, {bool own = false}) => (data as List? ??
          [])
      .cast<Map<String, dynamic>>()
      .map((j) => _map(j, own: own))
      .toList();

  Listing _map(Map<String, dynamic> j, {bool own = false}) {
    final images = (j['images'] as List? ?? [])
        .cast<Map>()
        .map((m) => (m['urls'] as Map?)?['full'] as String?)
        .whereType<String>()
        .toList();
    final cover = j['cover_url'] as String? ??
        (images.isEmpty ? '' : images.first);
    final location = j['location'] as Map?;
    final seller = j['seller'] as Map?;
    final published = DateTime.tryParse(j['published_at'] as String? ?? '');
    final cents = (j['price_cents'] as num?)?.toDouble() ?? 0;
    final status = switch (j['status']) {
      'reserved' => ListingStatus.reserved,
      'sold' => ListingStatus.sold,
      _ => ListingStatus.active,
    };
    return Listing(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      price: cents / 100,
      image: cover,
      images: images,
      category: j['category_name'] as String? ?? '',
      city: (location?['city'] ?? j['city']) as String? ?? '',
      district: (location?['district'] ?? j['district'] ??
              location?['governorate'] ?? j['governorate']) as String? ??
          '',
      distance: 0,
      type: '',
      kind: '',
      carrier: j['carrier'] as String? ?? '',
      condition: j['attributes'] is Map ? j['attributes']['condition'] as String? ?? '' : '',
      shipping: (j['shipping_available'] as bool?) ?? false,
      commercial: (seller?['account_type'] == 'commercial') ||
          (j['seller_commercial'] as bool? ?? false),
      wanted: j['offer_type'] == 'wanted',
      seller: own
          ? name
          : (seller?['display_name'] ?? j['seller_name']) as String? ?? '',
      sellerId: own ? 'self' : (seller?['id'] ?? j['seller_id']) as String? ?? '',
      date: published == null ? '' : _relative(published),
      ageHours: published == null
          ? 0
          : DateTime.now().difference(published).inHours,
      status: status,
      priceType: PriceType.values.firstWhere(
        (p) => p.name == j['price_type'],
        orElse: () => PriceType.fixed,
      ),
      description: j['description'] as String? ?? '',
    );
  }

  static String _relative(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return 'الآن';
    if (d.inHours < 1) return 'منذ ${d.inMinutes} دقيقة';
    if (d.inDays < 1) return 'منذ ${d.inHours} ساعة';
    if (d.inDays < 30) return 'منذ ${d.inDays} يوم';
    final l = at.toLocal();
    return '${l.year}/${l.month}/${l.day}';
  }

  // ── Errors ───────────────────────────────────────────────
  void _fail(Object e, {String prefix = ''}) {
    lastError = prefix +
        (e is ApiException
            ? (e.errors?.values.expand((v) => v).firstOrNull ?? e.detail)
            : 'تعذّر الاتصال بالخادم.');
    if (e is ApiException && e.status == 401 && signedIn) {
      signOut();
    }
    _toast(lastError!);
    notifyListeners();
  }

  void _toast(String text) => messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
