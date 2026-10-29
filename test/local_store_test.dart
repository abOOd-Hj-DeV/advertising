import 'dart:async';
import 'dart:convert';
import 'package:advertising/data/demo_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Listing own(
  String id, {
  String title = 'أريكة محلية',
  PriceType priceType = PriceType.fixed,
}) => Listing(
  id: id,
  title: title,
  price: 55.5,
  image: 'sofa',
  images: const ['sofa', 'plant'],
  category: 'المنزل والحديقة',
  city: 'دمشق',
  description: 'وصف محلي كامل.',
  priceType: priceType,
  shipping: true,
  carrier: 'DPD',
  wanted: true,
);
Future<SharedPreferences> prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'complete listing lifecycle uses one canonical ID and persists across restart',
    () async {
      final p = await prefs();
      final store = DemoStore(preferences: p)..signIn();
      store.saveDraft(
        ListingDraft(
          id: 'draft',
          values: {
            'title': 'مسودتي',
            'images': ['sofa'],
          },
        ),
      );
      store.publish(own('local-1'), draftId: 'draft');
      expect(store.drafts, isEmpty);
      expect(store.findListing('local-1')!.sellerId, 'self');
      store.toggleFavorite('local-1');
      store.viewListing('local-1');
      store.editListing(
        store
            .findListing('local-1')!
            .copyWith(title: 'عنوان آخر', priceType: PriceType.negotiable),
      );
      expect(
        store.findListing('local-1')!.formattedPrice,
        '55.50 ل.س قابل للتفاوض',
      );
      store.setListingStatus('local-1', ListingStatus.reserved);
      expect(store.results().any((l) => l.id == 'local-1'), isFalse);
      store.setListingStatus('local-1', ListingStatus.active);
      expect(store.results().any((l) => l.id == 'local-1'), isTrue);
      store.setListingStatus('local-1', ListingStatus.sold);
      expect(await store.flush(), isTrue);
      final restored = DemoStore(preferences: p)..signIn();
      final l = restored.findListing('local-1')!;
      expect(l.title, 'عنوان آخر');
      expect(l.status, ListingStatus.sold);
      expect(l.gallery, ['sofa', 'plant']);
      expect(l.shipping, isTrue);
      expect(l.carrier, 'DPD');
      expect(l.wanted, isTrue);
      restored.setListingStatus('local-1', ListingStatus.active);
      restored.deleteListing('local-1');
      expect(await restored.flush(), isTrue);
      final deleted = DemoStore(preferences: p)..signIn();
      expect(deleted.findListing('local-1'), isNull);
      expect(deleted.isOwn('local-1'), isFalse);
      expect(deleted.favorites, isNot(contains('local-1')));
      expect(deleted.recentlyViewed, isNot(contains('local-1')));
      expect(deleted.editListing(l), isFalse);
      expect(deleted.ownListings, isEmpty);
      store.dispose();
      restored.dispose();
      deleted.dispose();
    },
  );
  test(
    'draft values and stable editing ID survive restarts and delete independently',
    () async {
      final p = await prefs();
      final store = DemoStore(preferences: p)..signIn();
      store.publish(own('mine'));
      store.saveDraft(
        ListingDraft(
          id: 'edit',
          editingId: 'mine',
          values: {
            'title': 'غير مكتمل',
            'priceText': 'غير صالح',
            'images': ['media-123', 'sofa'],
            'wanted': true,
          },
        ),
      );
      store.saveDraft(
        ListingDraft(
          id: 'other',
          values: {
            'title': 'الثاني',
            'images': ['plant'],
          },
        ),
      );
      await store.flush();
      final restored = DemoStore(preferences: p)..signIn();
      expect(restored.drafts.last.editingId, 'mine');
      expect(restored.drafts.last.values['images'], ['media-123', 'sofa']);
      expect(restored.findListing('mine')!.title, 'أريكة محلية');
      restored.deleteDraft('other');
      expect(restored.drafts.single.id, 'edit');
      restored.deleteListing('mine');
      expect(restored.drafts, isEmpty);
      await restored.flush();
      store.dispose();
      restored.dispose();
    },
  );
  test(
    'registration profile provider and notification preferences persist without credentials',
    () async {
      final p = await prefs();
      final store = DemoStore(preferences: p);
      store.registerLocal('ميرا المحلية', business: true, news: true);
      store.publish(own('self-ad'));
      expect(store.updateProfile('demo@example.test'), isFalse);
      expect(store.updateProfile('123456789'), isFalse);
      expect(store.updateProfile('L'), isFalse);
      expect(store.updateProfile('فريق الحديقة', business: false), isTrue);
      store.setNotifications(alerts: false, email: true);
      await store.flush();
      final restored = DemoStore(preferences: p);
      expect(restored.signedIn, isFalse);
      expect(restored.name, 'فريق الحديقة');
      expect(restored.commercial, isFalse);
      expect(restored.newsletter, isTrue);
      expect(restored.emailPreference, isTrue);
      expect(restored.localAlerts, isFalse);
      expect(restored.sellerListings('self').single.seller, 'فريق الحديقة');
      expect(restored.ownListings.single.commercial, isFalse);
      final encoded = p.getString(DemoStore.storageKey)!;
      expect(encoded, isNot(contains('password')));
      expect(encoded, isNot(contains('@')));
      store.dispose();
      restored.dispose();
    },
  );
  test(
    'thread identity is listing plus participant, including multiple buyers on own listing',
    () async {
      final p = await prefs();
      final s = DemoStore(preferences: p)..signIn();
      s.publish(own('mine'));
      final a = s.ensureConversation(
        s.findListing('mine')!,
        participantId: 'buyer-a',
        participant: 'لمى',
      );
      final b = s.ensureConversation(
        s.findListing('mine')!,
        participantId: 'buyer-b',
        participant: 'باسل',
      );
      expect(a.id, isNot(b.id));
      expect(
        s
            .ensureConversation(
              s.findListing('mine')!,
              participantId: 'buyer-a',
            )
            .id,
        a.id,
      );
      s.sendMessage(a.id, 'للمى فقط');
      s.sendMessage(b.id, 'لباسل فقط', incoming: true);
      s.setChatDraft(a.id, 'نص غير مرسل');
      expect(a.messages.single.text, 'للمى فقط');
      expect(a.unread, 0);
      expect(b.unread, 1);
      s.archiveChat(a.id, true);
      s.markRead(b.id);
      await s.flush();
      final r = DemoStore(preferences: p)..signIn();
      expect(r.findConversation(a.id)!.draft, 'نص غير مرسل');
      expect(r.findConversation(a.id)!.archived, isTrue);
      expect(r.findConversation(b.id)!.unread, 0);
      expect(r.findConversation(b.id)!.messages.single.incoming, isTrue);
      r.deleteChat(a.id);
      expect(r.findConversation(a.id), isNull);
      expect(r.findConversation(b.id), isNotNull);
      r.signOut();
      expect(r.messages, isEmpty);
      r.signIn();
      expect(r.findConversation(b.id)!.messages.single.text, 'لباسل فقط');
      await r.flush();
      s.dispose();
      r.dispose();
    },
  );
  test(
    'block, report and unavailable listing enforce local composition boundaries',
    () async {
      final p = await prefs();
      final s = DemoStore(preferences: p)..signIn();
      s.publish(own('mine'));
      final c = s.ensureConversation(
        s.findListing('mine')!,
        participantId: 'buyer',
        participant: 'Demo',
      );
      expect(s.sendMessage(c.id, '  '), isFalse);
      expect(s.sendMessage(c.id, 'x' * 2001), isFalse);
      s.toggleBlock('buyer');
      expect(s.sendMessage(c.id, 'مرحباً'), isFalse);
      expect(s.sendMessage(c.id, 'افتراضي', incoming: true), isFalse);
      s.report(target: 'buyer', reason: 'اشتباه احتيال', details: 'محلي فقط');
      await s.flush();
      final r = DemoStore(preferences: p)..signIn();
      expect(r.blockedParticipants, {'buyer'});
      expect(r.reports.single['details'], 'محلي فقط');
      r.toggleBlock('buyer');
      expect(r.sendMessage(c.id, 'بعد إلغاء الحظر'), isTrue);
      r.setListingStatus('mine', ListingStatus.sold);
      expect(r.sendMessage(c.id, 'لا ترسل'), isFalse);
      r.deleteListing('mine');
      expect(r.findConversation(c.id)!.messages.single.text, 'بعد إلغاء الحظر');
      expect(r.sendMessage(c.id, 'محذوف'), isFalse);
      await r.flush();
      s.dispose();
      r.dispose();
    },
  );
  test(
    'collections follow, history, saved filters, alerts and notices persist independently',
    () async {
      final p = await prefs();
      final s = DemoStore(preferences: p)..signIn();
      s.toggleFollow(listings.first.identity);
      s.toggleFavorite('b2');
      s.viewListing('b1');
      s.viewListing('b2');
      s.viewListing('b1');
      s.search('دراجة');
      s.changeFilters(
        SearchFilters(
          city: 'دمشق',
          maximum: 200,
          type: 'دراجات مدينة',
          category: 'دراجات وملحقات',
        ),
      );
      s.saveSearch();
      s.toggleSearchAlerts(s.savedSearches.single);
      s.seedNotice();
      s.readNotice(s.notifications.single);
      await s.flush();
      final r = DemoStore(preferences: p)..signIn();
      expect(r.followedSellers, {listings.first.identity});
      expect(r.recentlyViewed, ['b1', 'b2']);
      expect(r.searchHistory, ['دراجة']);
      final saved = r.savedSearches.single;
      expect(saved.alerts, isFalse);
      r.restoreSearch(saved);
      expect(r.filters.maximum, 200);
      expect(r.filters.type, 'دراجات مدينة');
      expect(r.notifications.single.read, isTrue);
      r.dismissNotice(r.notifications.single);
      r.clearRecent();
      r.deleteSearch(saved);
      expect(r.favorites, {'b2'});
      expect(r.searchHistory, ['دراجة']);
      expect(r.followedSellers, isNotEmpty);
      r.setNotifications(alerts: false);
      r.seedNotice();
      expect(r.notifications, isEmpty);
      await r.flush();
      s.dispose();
      r.dispose();
    },
  );
  test(
    'legacy preferences migrate while malformed records do not discard healthy siblings',
    () async {
      final legacy = SavedSearch('أريكة', SearchFilters(maximum: 100));
      final p = await prefs({
        'theme': 'dark',
        'favorites': ['b1'],
        'saved_searches': ['bad', legacy.encode()],
      });
      final s = DemoStore(preferences: p);
      expect(s.themeMode, ThemeMode.dark);
      expect(s.savedSearches.single.query, 'أريكة');
      expect(s.storageError, isNotNull);
      await s.retrySave();
      final data =
          jsonDecode(p.getString(DemoStore.storageKey)!)
              as Map<String, dynamic>;
      data['listings'] = [
        own('good').toJson(),
        {'id': 'broken', 'price': 'bad'},
        own('other').toJson(),
      ];
      data['drafts'] = [
        false,
        {
          'id': 'd',
          'values': {'title': 'سليم'},
        },
      ];
      data['favorites'] = ['b1', null, 'missing'];
      await p.setString(DemoStore.storageKey, jsonEncode(data));
      final r = DemoStore(preferences: p);
      expect(r.ownListings.map((l) => l.id), ['good', 'other']);
      expect(r.drafts.single.id, 'd');
      expect(r.favorites, {'b1'});
      expect(r.storageError, isNotNull);
      await r.retrySave();
      expect(DemoStore(preferences: p).ownListings.length, 2);
      s.dispose();
      r.dispose();
    },
  );
  test(
    'bad root types and future versions do not crash or overwrite future data',
    () async {
      for (final raw in <Object>['not json', '[]', 12]) {
        final p = await prefs({
          DemoStore.storageKey: raw,
          'theme': true,
          'favorites': 7,
        });
        final s = DemoStore(preferences: p);
        expect(s.storageError, isNotNull);
        expect(s.results(), isNotEmpty);
        s.dispose();
      }
      const future = '{"version":99,"future":"keep me"}';
      final p = await prefs({DemoStore.storageKey: future});
      final s = DemoStore(preferences: p)..setTheme(ThemeMode.dark);
      expect(await s.flush(), isFalse);
      expect(await s.resetLocalData(), isFalse);
      expect(p.getString(DemoStore.storageKey), future);
      s.dispose();
    },
  );
  test(
    'writes serialize snapshots and recover after rejected and throwing writes',
    () async {
      final gate = Completer<void>();
      final writes = <Map<String, dynamic>>[];
      var active = 0, maxActive = 0, count = 0;
      final s = DemoStore(
        writeSnapshot: (encoded) async {
          active++;
          if (active > maxActive) maxActive = active;
          if (count++ == 0) await gate.future;
          writes.add(jsonDecode(encoded) as Map<String, dynamic>);
          active--;
          return true;
        },
      );
      s.updateProfile('الاسم الأول');
      s.updateProfile('الاسم الأخير');
      await Future<void>.delayed(Duration.zero);
      expect(writes, isEmpty);
      gate.complete();
      expect(await s.flush(), isTrue);
      expect(maxActive, 1);
      expect(writes.map((j) => j['name']), ['الاسم الأول', 'الاسم الأخير']);
      s.dispose();
      var attempt = 0;
      final failing = DemoStore(
        writeSnapshot: (_) async {
          attempt++;
          if (attempt == 1) return false;
          if (attempt == 2) throw StateError('quota');
          return true;
        },
      );
      failing.publish(own('retained'));
      expect(await failing.flush(), isFalse);
      expect(failing.storageError, isNotNull);
      expect(failing.ownListings.single.id, 'retained');
      expect(await failing.retrySave(), isFalse);
      expect(await failing.retrySave(), isTrue);
      expect(failing.storageError, isNull);
      failing.dispose();
    },
  );
  test(
    'reset waits behind delayed writes and does not delete unrelated preferences',
    () async {
      final p = await prefs({
        'other.app': 'untouched',
        'theme': 'dark',
        'favorites': ['b1'],
      });
      final gate = Completer<void>();
      var first = true;
      final s = DemoStore(
        preferences: p,
        writeSnapshot: (encoded) async {
          if (first) {
            first = false;
            await gate.future;
          }
          return p.setString(DemoStore.storageKey, encoded);
        },
      )..signIn();
      s.publish(own('before-reset'));
      s.saveDraft(ListingDraft(id: 'draft', values: {'title': 'قبل'}));
      s.seedConversations();
      s.toggleFollow(listings.first.identity);
      final reset = s.resetLocalData();
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      expect(await reset, isTrue);
      final r = DemoStore(preferences: p);
      expect(r.ownListings, isEmpty);
      expect(r.drafts, isEmpty);
      expect(r.conversations, isEmpty);
      expect(r.followedSellers, isEmpty);
      expect(r.notifications, isEmpty);
      expect(r.signedIn, isFalse);
      expect(r.consentAccepted, isFalse);
      expect(r.themeMode, ThemeMode.system);
      expect(p.getString('other.app'), 'untouched');
      expect(p.containsKey('theme'), isFalse);
      s.dispose();
      r.dispose();
    },
  );
  test('explicit price types do not infer VB from a numeric threshold', () {
    expect(own('fixed').formattedPrice, '55.50 ل.س');
    expect(own('free', priceType: PriceType.free).formattedPrice, 'مجاني');
    expect(
      own('vb', priceType: PriceType.negotiable).formattedPrice,
      '55.50 ل.س قابل للتفاوض',
    );
  });
  test(
    'saved-search notices require a matching new listing and local alert preference',
    () async {
      final s = DemoStore()..signIn();
      s.search('أريكة');
      s.changeFilters(SearchFilters(city: 'دمشق', maximum: 100));
      s.saveSearch();
      s.publish(own('match'));
      List<LocalNotice> matches() => s.notifications
          .where((n) => n.title.startsWith('نتيجة جديدة لبحثك:'))
          .toList();
      expect(matches().single.listingId, 'match');
      s.publish(own('wrong-title', title: 'دراجة'));
      expect(matches().length, 1);
      s.publish(own('wrong-city').copyWith(city: 'حلب'));
      expect(matches().length, 1);
      s.toggleSearchAlerts(s.savedSearches.single);
      s.publish(own('disabled-search'));
      expect(matches().length, 1);
      s.toggleSearchAlerts(s.savedSearches.single);
      s.setNotifications(alerts: false);
      s.publish(own('disabled-global'));
      expect(matches().length, 1);
      await s.flush();
      s.dispose();
    },
  );
  test(
    'unavailable preferences never report successful durable writes or reset',
    () async {
      final s = DemoStore(startupError: 'التخزين غير متاح')..signIn();
      s.publish(own('temporary'));
      expect(await s.flush(), isFalse);
      expect(s.persistenceAvailable, isFalse);
      expect(s.findListing('temporary'), isNotNull);
      expect(await s.resetLocalData(), isFalse);
      expect(s.storageError, isNotNull);
      s.dispose();
    },
  );
}
