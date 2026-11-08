import 'dart:convert';

import 'package:advertising/api/api_client.dart';
import 'package:advertising/api/api_store.dart';
import 'package:advertising/api/backend_store.dart';
import 'package:advertising/api/session.dart';
import 'package:advertising/data/demo_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Scripted fake backend: records requests, answers by "METHOD /path".
class FakeApi {
  final requests = <http.Request>[];
  final Map<String, http.Response Function(http.Request)> routes = {};

  http.Client get client => MockClient((request) async {
    requests.add(request);
    final key = '${request.method} ${request.url.path}';
    final handler = routes[key];
    if (handler == null) {
      return http.Response(
        jsonEncode({
          'code': 'resource.not_found',
          'detail': 'غير موجود',
          'status': 404,
        }),
        404,
        headers: {'content-type': 'application/problem+json'},
      );
    }
    return handler(request);
  });

  void json(String key, Object body, {int status = 200}) {
    routes[key] = (_) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Iterable<http.Request> sent(String key) =>
      requests.where((r) => '${r.method} ${r.url.path}' == key);
}

const ulid = '01JD0000000000000000000000';
const ulid2 = '01JD0000000000000000000001';

Map<String, dynamic> user({bool verified = true}) => {
  'id': ulid,
  'email': 'a@b.sy',
  'display_name': 'أحمد',
  'account_type': 'private',
  'email_verified': verified,
};

Future<(FakeApi, BackendStore)> liveStore({
  bool verified = true,
  String? storedToken,
}) async {
  SharedPreferences.setMockInitialValues({'api.token': ?storedToken});
  final prefs = await SharedPreferences.getInstance();
  final fake = FakeApi()
    ..json('GET /api/v1/categories', {
      'data': [
        {
          'id': 'cat-vehicles',
          'slug': 'vehicles',
          'name': 'سيارات ومركبات',
          'children': [
            {'id': 'cat-cars', 'slug': 'cars', 'name': 'سيارات'},
            {'id': 'cat-moto', 'slug': 'motorcycles', 'name': 'دراجات نارية'},
          ],
        },
        {
          'id': 'cat-misc',
          'slug': 'miscellaneous',
          'name': 'متفرقات',
          'children': [],
        },
      ],
    })
    ..json('GET /api/v1/locations', {
      'data': [
        {
          'governorate': 'دمشق',
          'cities': [
            {'id': 'loc-dam', 'city': 'دمشق'},
          ],
        },
      ],
    })
    ..json('GET /api/v1/listings', {
      'data': [
        {
          'id': ulid2,
          'title': 'سيارة كيا',
          'price_cents': 150000000,
          'status': 'active',
          'category_name': 'سيارات',
          'location': {'city': 'دمشق', 'governorate': 'دمشق'},
          'seller': {'id': ulid, 'display_name': 'سامر'},
          'published_at': DateTime.now().toIso8601String(),
          'images': [
            {
              'urls': {'full': 'http://x/full.jpg'},
            },
          ],
        },
      ],
      'next_cursor': 'c2',
    })
    ..json('GET /api/v1/me', {'data': user(verified: verified)})
    ..json('GET /api/v1/me/listings', {'data': []})
    ..json('GET /api/v1/favorites', {'data': []})
    ..json('GET /api/v1/saved-searches', {'data': []})
    ..json('GET /api/v1/follows', {'data': []})
    ..json('GET /api/v1/blocks', {'data': []})
    ..json('GET /api/v1/conversations', {'data': []})
    ..json('GET /api/v1/notifications', {'data': []})
    ..json('GET /api/v1/me/business/status', {'status': 'none'});
  final client = ApiClient(baseUrl: 'http://api.test', httpClient: fake.client);
  final session = ApiSession(client, prefs);
  final api = ApiStore.forTest(client, session);
  final store = BackendStore(api, preferences: prefs);
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return (fake, store);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient', () {
    test('sends bearer, Arabic locale and idempotency headers', () async {
      final fake = FakeApi()..json('POST /api/v1/listings', {'data': {}});
      final client = ApiClient(
        baseUrl: 'http://api.test/',
        httpClient: fake.client,
      )..token = 'tok';
      await client.post('/listings', body: {'a': 1}, idempotencyKey: 'k1');
      final r = fake.requests.single;
      expect(r.url.toString(), 'http://api.test/api/v1/listings');
      expect(r.headers['Authorization'], 'Bearer tok');
      expect(r.headers['Accept-Language'], 'ar');
      expect(r.headers['Idempotency-Key'], 'k1');
      expect(jsonDecode(r.body), {'a': 1});
    });

    test('maps RFC 9457 problems to ApiException with field errors', () async {
      final fake = FakeApi()
        ..json('POST /api/v1/auth/login', {
          'code': 'request.validation_failed',
          'detail': 'راجع الحقول',
          'errors': {
            'email': ['بيانات الدخول غير صحيحة.'],
          },
        }, status: 422);
      final client = ApiClient(
        baseUrl: 'http://api.test',
        httpClient: fake.client,
      );
      await expectLater(
        client.post('/auth/login', body: {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 422)
              .having((e) => e.code, 'code', 'request.validation_failed')
              .having(
                (e) => e.errors?['email']?.single,
                'first error',
                'بيانات الدخول غير صحيحة.',
              ),
        ),
      );
    });

    test('204 and empty bodies decode to an empty map', () async {
      final fake = FakeApi()
        ..routes['DELETE /api/v1/favorites/$ulid'] = (_) =>
            http.Response('', 204);
      final client = ApiClient(
        baseUrl: 'http://api.test',
        httpClient: fake.client,
      );
      await client.delete('/favorites/$ulid');
      expect(fake.requests, hasLength(1));
    });
  });

  group('ApiSession', () {
    test('login persists token, logout clears it', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fake = FakeApi()
        ..json('POST /api/v1/auth/login', {'token': 't-1', 'user': user()})
        ..routes['POST /api/v1/auth/logout'] = (_) => http.Response('', 204);
      final client = ApiClient(
        baseUrl: 'http://api.test',
        httpClient: fake.client,
      );
      final session = ApiSession(client, prefs);
      await session.login(email: 'a@b.sy', password: 'x');
      expect(prefs.getString('api.token'), 't-1');
      final body = jsonDecode(fake.sent('POST /api/v1/auth/login').single.body);
      expect(body['device_name'], isNotEmpty);
      await session.logout();
      expect(prefs.getString('api.token'), isNull);
      expect(session.isAuthenticated, isFalse);
    });
  });

  group('BackendStore', () {
    test('bootstraps catalog, locations and first results page', () async {
      final (fake, store) = await liveStore();
      expect(store.isLive, isTrue);
      expect(store.categoryTree['سيارات ومركبات'], ['سيارات', 'دراجات نارية']);
      expect(store.backendParentFor('سيارات ودراجات وقوارب'), 'سيارات ومركبات');
      expect(store.appCategoryLabel('سيارات ومركبات'), 'سيارات ودراجات وقوارب');
      final results = store.results();
      expect(results.single.title, 'سيارة كيا');
      expect(results.single.price, 1500000);
      expect(results.single.image, 'http://x/full.jpg');
      expect(store.hasMore, isTrue);
      expect(fake.sent('GET /api/v1/listings'), hasLength(1));
    });

    test('loadMore requests the cursor and appends', () async {
      final (fake, store) = await liveStore();
      fake.json('GET /api/v1/listings', {
        'data': [
          {
            'id': '01JD0000000000000000000002',
            'title': 'دراجة',
            'price_cents': 5000000,
            'status': 'active',
          },
        ],
        'next_cursor': null,
      });
      await store.loadMore();
      expect(
        fake.sent('GET /api/v1/listings').last.url.queryParameters['cursor'],
        'c2',
      );
      expect(store.results(), hasLength(2));
      expect(store.hasMore, isFalse);
      await store.loadMore(); // no cursor → no request
      expect(fake.sent('GET /api/v1/listings'), hasLength(2));
    });

    test('category filter maps app labels to backend parent ids', () async {
      final (fake, store) = await liveStore();
      store.changeFilters(SearchFilters(category: 'سيارات ودراجات وقوارب'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final q = fake.sent('GET /api/v1/listings').last.url.queryParameters;
      expect(q['category'], 'cat-vehicles');
    });

    test('login applies user and exposes verification state', () async {
      final (fake, store) = await liveStore(verified: false);
      fake.json('POST /api/v1/auth/login', {
        'token': 't-2',
        'user': user(verified: false),
      });
      final error = await store.authenticate(
        register: false,
        email: 'a@b.sy',
        password: 'secret',
      );
      expect(error, isNull);
      expect(store.signedIn, isTrue);
      expect(store.name, 'أحمد');
      expect(store.emailVerified, isFalse);
      expect(store.canPublish, isFalse);
    });

    test('publish is blocked until the e-mail is verified', () async {
      final (fake, store) = await liveStore(verified: false);
      fake.json('POST /api/v1/auth/login', {
        'token': 't-2',
        'user': user(verified: false),
      });
      await store.authenticate(register: false, email: 'a@b.sy', password: 'p');
      store.publish(
        Listing(
          id: 'local-1',
          title: 'سجاد',
          price: 10,
          image: '',
          category: 'المنزل والحديقة',
        ),
      );
      expect(store.ownListings, isEmpty);
      expect(fake.sent('POST /api/v1/listings'), isEmpty);

      fake.json('POST /api/v1/auth/email/verify', {'message': 'ok'});
      fake.json('GET /api/v1/me', {'data': user(verified: true)});
      expect(await store.verifyEmail('$ulid.abc'), isNull);
      expect(store.emailVerified, isTrue);
      expect(
        jsonDecode(fake.sent('POST /api/v1/auth/email/verify').single.body),
        {'token': '$ulid.abc'},
      );
    });

    test('publish sends the chosen leaf category and SYP cents', () async {
      final (fake, store) = await liveStore();
      fake.json('POST /api/v1/auth/login', {'token': 't', 'user': user()});
      await store.authenticate(register: false, email: 'a@b.sy', password: 'p');
      fake.json('POST /api/v1/listings', {
        'data': {
          'id': ulid2,
          'title': 'دراجة نارية',
          'price_cents': 250000000,
          'status': 'active',
          'version': 1,
        },
      }, status: 201);
      store.publish(
        Listing(
          id: 'local-2',
          title: 'دراجة نارية',
          price: 2500000,
          image: '',
          category: 'سيارات ودراجات وقوارب',
          leafCategory: 'دراجات نارية',
          city: 'دمشق',
          shipping: false,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final body = jsonDecode(fake.sent('POST /api/v1/listings').single.body);
      expect(body['category_id'], 'cat-moto');
      expect(body['price_cents'], 250000000);
      expect(body['currency'], 'SYP');
      expect(body['location_id'], 'loc-dam');
      expect(store.ownListings.single.id, ulid2);
    });

    test('forgot/reset password call the auth endpoints', () async {
      final (fake, store) = await liveStore();
      fake.json('POST /api/v1/auth/password/forgot', {
        'message': 'sent',
      }, status: 202);
      fake.json('POST /api/v1/auth/password/reset', {'message': 'ok'});
      expect(await store.forgotPassword('a@b.sy'), isNull);
      expect(
        await store.resetPassword(
          email: 'a@b.sy',
          token: 'tok',
          password: 'longpassword1',
        ),
        isNull,
      );
      final reset = jsonDecode(
        fake.sent('POST /api/v1/auth/password/reset').single.body,
      );
      expect(reset, {
        'email': 'a@b.sy',
        'token': 'tok',
        'password': 'longpassword1',
      });
    });

    test('401 on a live call signs the user out', () async {
      final (fake, store) = await liveStore();
      fake.json('POST /api/v1/auth/login', {'token': 't', 'user': user()});
      await store.authenticate(register: false, email: 'a@b.sy', password: 'p');
      fake.json('GET /api/v1/me/listings', {
        'code': 'auth.unauthenticated',
        'detail': 'x',
      }, status: 401);
      fake.routes['POST /api/v1/auth/logout'] = (_) => http.Response('', 204);
      await store.loadOwnListingsForTest();
      expect(store.signedIn, isFalse);
    });
  });
}
