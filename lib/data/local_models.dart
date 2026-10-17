part of 'demo_store.dart';

enum ListingStatus { active, reserved, sold }

enum PriceType { fixed, negotiable, free }

extension ListingStatusLabel on ListingStatus {
  String get label => switch (this) {
    ListingStatus.active => 'Aktiv',
    ListingStatus.reserved => 'Reserviert',
    ListingStatus.sold => 'Verkauft',
  };
}

extension PriceTypeLabel on PriceType {
  String get label => switch (this) {
    PriceType.fixed => 'Festpreis',
    PriceType.negotiable => 'VB',
    PriceType.free => 'Zu verschenken',
  };
}

String? validateProfileName(String? value) {
  final name = value?.trim() ?? '';
  if (name.length < 2 ||
      name.length > 40 ||
      name.contains('@') ||
      RegExp(r'\d{3,}').hasMatch(name) ||
      !RegExp(r'[a-zA-ZÀ-ž]').hasMatch(name)) {
    return '2–40 Zeichen, keine E-Mail-Adresse oder Telefonnummer';
  }
  return null;
}

class ListingDraft {
  ListingDraft({required this.id, required this.values, this.editingId});
  final String id;
  final String? editingId;
  final Map<String, dynamic> values;
  Map<String, dynamic> toJson() => {
    'id': id,
    'editingId': editingId,
    'values': values,
  };
  factory ListingDraft.fromJson(Map<String, dynamic> j) => ListingDraft(
    id: j['id'] as String,
    editingId: j['editingId'] as String?,
    values: Map<String, dynamic>.from(j['values'] as Map),
  );
}

class DemoMessage {
  DemoMessage({
    required this.listingId,
    required this.text,
    this.incoming = false,
    DateTime? at,
  }) : at = at ?? DateTime.now();
  final String listingId, text;
  final bool incoming;
  final DateTime at;
  Map<String, dynamic> toJson() => {
    'listingId': listingId,
    'text': text,
    'incoming': incoming,
    'at': at.toIso8601String(),
  };
  factory DemoMessage.fromJson(Map<String, dynamic> j) => DemoMessage(
    listingId: j['listingId'] as String,
    text: j['text'] as String,
    incoming: j['incoming'] as bool? ?? false,
    at: DateTime.parse(j['at'] as String),
  );
}

class Conversation {
  Conversation({
    required this.id,
    required this.listingId,
    required this.participantId,
    required this.participant,
    required this.listingTitle,
    this.archived = false,
    this.unread = 0,
    this.draft = '',
    List<DemoMessage>? messages,
  }) : messages = messages ?? [];
  final String id, listingId, participantId, participant, listingTitle;
  bool archived;
  int unread;
  String draft;
  final List<DemoMessage> messages;
  DateTime get activity => messages.isEmpty
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : messages.last.at;
  Map<String, dynamic> toJson() => {
    'id': id,
    'listingId': listingId,
    'participantId': participantId,
    'participant': participant,
    'listingTitle': listingTitle,
    'archived': archived,
    'unread': unread,
    'draft': draft,
    'messages': messages.map((m) => m.toJson()).toList(),
  };
  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: j['id'] as String,
    listingId: j['listingId'] as String,
    participantId: j['participantId'] as String,
    participant: j['participant'] as String,
    listingTitle: j['listingTitle'] as String,
    archived: j['archived'] as bool? ?? false,
    unread: j['unread'] as int? ?? 0,
    draft: j['draft'] as String? ?? '',
    messages: (j['messages'] as List? ?? [])
        .map((m) => DemoMessage.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList(),
  );
}

class LocalNotice {
  LocalNotice({
    required this.id,
    required this.title,
    this.listingId,
    this.threadId,
    this.read = false,
  });
  final String id, title;
  final String? listingId, threadId;
  bool read;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'listingId': listingId,
    'threadId': threadId,
    'read': read,
  };
  factory LocalNotice.fromJson(Map<String, dynamic> j) => LocalNotice(
    id: j['id'] as String,
    title: j['title'] as String,
    listingId: j['listingId'] as String?,
    threadId: j['threadId'] as String?,
    read: j['read'] as bool? ?? false,
  );
}
