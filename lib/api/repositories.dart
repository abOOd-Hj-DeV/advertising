import 'api_client.dart';
import 'session.dart';

/// Repositories mapping /api/v1 resources onto plain maps.
/// The UI keeps its own view models; these methods are the single seam
/// between HTTP and app state.
class ApiRepositories {
  ApiRepositories(this.client, this.session);

  final ApiClient client;
  final ApiSession session;

  // ── Catalog ──────────────────────────────────────────────
  Future<List<dynamic>> categories() async =>
      (await client.get('/categories'))['data'] as List;

  Future<Map<String, dynamic>> category(String id) async =>
      (await client.get('/categories/$id'))['data'] as Map<String, dynamic>;

  Future<List<dynamic>> locations({String? query}) async => (await client
          .get('/locations', query == null ? null : {'q': query}))['data']
      as List;

  // ── Listings ─────────────────────────────────────────────
  Future<Map<String, dynamic>> searchListings({
    String? q,
    String? category,
    String? governorate,
    int? priceMin,
    int? priceMax,
    String? currency,
    String? sort,
    String? cursor,
    int limit = 20,
  }) =>
      client.get('/listings', {
        if (q != null && q.isNotEmpty) 'q': q,
        'category': ?category,
        'governorate': ?governorate,
        if (priceMin != null) 'price_min': '$priceMin',
        if (priceMax != null) 'price_max': '$priceMax',
        'currency': ?currency,
        'sort': ?sort,
        'cursor': ?cursor,
        'limit': '$limit',
      });

  Future<Map<String, dynamic>> listing(String id) async =>
      (await client.get('/listings/$id'))['data'] as Map<String, dynamic>;

  Future<Map<String, dynamic>> createListing(
          Map<String, dynamic> payload, String idempotencyKey) async =>
      (await client.post('/listings',
          body: payload, idempotencyKey: idempotencyKey))['data']
      as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateListing(
          String id, Map<String, dynamic> payload, int version) async =>
      (await client.patch('/listings/$id',
          body: payload, ifMatch: '$version'))['data'] as Map<String, dynamic>;

  Future<void> deleteListing(String id) => client.delete('/listings/$id');

  Future<Map<String, dynamic>> transitionListing(String id, String action,
          [Map<String, dynamic>? body]) async =>
      (await client.post('/listings/$id/$action', body: body))['data']
          as Map<String, dynamic>;

  Future<List<dynamic>> similarListings(String id) async =>
      (await client.get('/listings/$id/similar'))['data'] as List;

  // ── Favorites / engagement ───────────────────────────────
  Future<void> favorite(String listingId) =>
      client.post('/favorites/$listingId');

  Future<void> unfavorite(String listingId) =>
      client.delete('/favorites/$listingId');

  Future<Map<String, dynamic>> favorites({String? cursor}) =>
      client.get('/favorites', cursor == null ? null : {'cursor': cursor});

  // ── Messaging ────────────────────────────────────────────
  Future<Map<String, dynamic>> conversations(
          {bool archived = false, String? cursor}) =>
      client.get('/conversations', {
        'archived': archived ? '1' : '0',
        'cursor': ?cursor,
      });

  Future<Map<String, dynamic>> startConversation(
          String listingId, String? firstMessage, String idempotencyKey) async =>
      (await client.post('/conversations', body: {
        'listing_id': listingId,
        'first_message': ?firstMessage,
      }, idempotencyKey: idempotencyKey))['data'] as Map<String, dynamic>;

  Future<Map<String, dynamic>> messages(String conversationId,
          {String? before, String? after, int limit = 30}) =>
      client.get('/conversations/$conversationId/messages', {
        'before': ?before,
        'after': ?after,
        'limit': '$limit',
      });

  Future<Map<String, dynamic>> sendMessage(
          String conversationId, String body, String clientMessageId) async =>
      (await client.post('/conversations/$conversationId/messages', body: {
        'body': body,
        'client_message_id': clientMessageId,
      }, idempotencyKey: clientMessageId))['data'] as Map<String, dynamic>;

  Future<void> markRead(String conversationId, String lastMessageId) =>
      client.post('/conversations/$conversationId/read',
          body: {'last_read_message_id': lastMessageId});

  // ── Notifications ────────────────────────────────────────
  Future<int> unreadCount() async =>
      (await client.get('/notifications/unread-count'))['unread'] as int;

  Future<Map<String, dynamic>> notifications({String? cursor}) =>
      client.get('/notifications', cursor == null ? null : {'cursor': cursor});
}
