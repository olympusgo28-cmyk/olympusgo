import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/demo/demo_world.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/social_models.dart';

/// One-to-one messages between players, live over Supabase Realtime.
abstract interface class ChatRepository {
  /// The Inbox, newest first. Emits again whenever a message arrives.
  Stream<List<Conversation>> conversations();

  /// The thread, oldest first, updated live.
  Stream<List<ChatMessage>> messages(String conversationId);

  Future<PlayerSummary> otherIn(String conversationId);

  /// Opens (or creates) the conversation with [playerId].
  Future<String> openDirect(String playerId);

  Future<void> send(String conversationId, String body);
  Future<void> markRead(String conversationId);
}

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client);
  final SupabaseClient _client;

  String get _me {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthFailure('Log in again to continue.');
    return id;
  }

  Future<List<Conversation>> _load() async {
    final me = _me;
    final mine = await _client
        .from('conversation_members')
        .select('conversation_id, last_read_at')
        .eq('user_id', me);
    if (mine.isEmpty) return const [];
    final readAt = {
      for (final r in mine)
        r['conversation_id'] as String: DateTime.parse(
          r['last_read_at'] as String,
        ),
    };
    final ids = readAt.keys.toList();

    final others = await _client
        .from('conversation_members')
        .select('conversation_id, user_id')
        .inFilter('conversation_id', ids)
        .neq('user_id', me);
    final otherByConv = {
      for (final r in others)
        r['conversation_id'] as String: r['user_id'] as String,
    };

    final profiles = otherByConv.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
              .from('profiles')
              .select('id, username, full_name, avatar_url')
              .inFilter('id', otherByConv.values.toSet().toList());
    final profileById = {
      for (final p in profiles) p['id'] as String: PlayerSummary.fromRow(p),
    };

    final recent = await _client
        .from('messages')
        .select('conversation_id, sender_id, body, created_at')
        .inFilter('conversation_id', ids)
        .order('created_at', ascending: false)
        .limit(ids.length * 5);
    final last = <String, Map<String, dynamic>>{};
    for (final m in recent) {
      last.putIfAbsent(m['conversation_id'] as String, () => m);
    }

    final list = <Conversation>[];
    for (final id in ids) {
      final other = profileById[otherByConv[id]];
      final m = last[id];
      if (other == null || m == null) continue; // blocked, or nothing sent yet
      final at = DateTime.parse(m['created_at'] as String);
      list.add(
        Conversation(
          id: id,
          other: other,
          lastBody: m['body'] as String,
          lastAt: at,
          unread: m['sender_id'] != me && at.isAfter(readAt[id]!),
        ),
      );
    }
    list.sort((a, b) => b.lastAt!.compareTo(a.lastAt!));
    return list;
  }

  @override
  Stream<List<Conversation>> conversations() {
    late final StreamController<List<Conversation>> controller;
    RealtimeChannel? channel;

    Future<void> refresh() async {
      try {
        controller.add(await _load());
      } catch (e) {
        controller.addError(
          const AuthFailure("Can't load your messages. Pull to try again."),
        );
      }
    }

    controller = StreamController<List<Conversation>>(
      onListen: () {
        refresh();
        channel = _client
            .channel('inbox-$_me')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              callback: (_) => refresh(),
            )
            .subscribe();
      },
      onCancel: () async {
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<ChatMessage>> messages(String conversationId) => _client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at')
      .map(
        (rows) => [
          for (final r in rows)
            ChatMessage(
              id: '${r['id']}',
              senderId: r['sender_id'] as String,
              body: r['body'] as String,
              createdAt: DateTime.parse(r['created_at'] as String),
            ),
        ],
      );

  @override
  Future<PlayerSummary> otherIn(String conversationId) async {
    final row = await _client
        .from('conversation_members')
        .select('user_id')
        .eq('conversation_id', conversationId)
        .neq('user_id', _me)
        .single();
    final p = await _client
        .from('profiles')
        .select('id, username, full_name, avatar_url')
        .eq('id', row['user_id'] as String)
        .single();
    return PlayerSummary.fromRow(p);
  }

  @override
  Future<String> openDirect(String playerId) async {
    try {
      return await _client.rpc(
        'open_direct_conversation',
        params: {'other': playerId},
      ) as String;
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const AuthFailure("You can't message this player.");
      }
      throw const AuthFailure('Something went wrong. Try again.');
    }
  }

  @override
  Future<void> send(String conversationId, String body) async {
    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _me,
        'body': body,
      });
    } on PostgrestException {
      throw const AuthFailure("Your message didn't send. Try again.");
    }
  }

  @override
  Future<void> markRead(String conversationId) async {
    await _client
        .from('conversation_members')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', _me);
  }
}

class DemoChatRepository implements ChatRepository {
  final _w = DemoWorld.instance;
  final _inbox = StreamController<List<Conversation>>.broadcast();
  final _threads = <String, StreamController<List<ChatMessage>>>{};

  List<Conversation> _snapshot() {
    final list = [
      for (final e in _w.conversations.entries)
        if (_w.messages[e.key]?.isNotEmpty ?? false)
          Conversation(
            id: e.key,
            other: _w.players[e.value]!,
            lastBody: _w.messages[e.key]!.last.body,
            lastAt: _w.messages[e.key]!.last.createdAt,
            unread: _w.unread.contains(e.key),
          ),
    ];
    list.sort((a, b) => b.lastAt!.compareTo(a.lastAt!));
    return list;
  }

  @override
  Stream<List<Conversation>> conversations() async* {
    yield _snapshot();
    yield* _inbox.stream;
  }

  StreamController<List<ChatMessage>> _thread(String id) =>
      _threads.putIfAbsent(id, StreamController<List<ChatMessage>>.broadcast);

  @override
  Stream<List<ChatMessage>> messages(String conversationId) async* {
    yield [...?_w.messages[conversationId]];
    yield* _thread(conversationId).stream;
  }

  @override
  Future<PlayerSummary> otherIn(String conversationId) async =>
      _w.players[_w.conversations[conversationId]]!;

  @override
  Future<String> openDirect(String playerId) async {
    final existing = _w.conversations.entries
        .where((e) => e.value == playerId)
        .firstOrNull;
    if (existing != null) return existing.key;
    final id = 'conv-$playerId';
    _w.conversations[id] = playerId;
    _w.messages[id] = [];
    return id;
  }

  @override
  Future<void> send(String conversationId, String body) async {
    final list = _w.messages.putIfAbsent(conversationId, () => []);
    list.add(
      ChatMessage(
        id: '$conversationId-${list.length}',
        senderId: DemoWorld.me,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
    _thread(conversationId).add([...list]);
    _inbox.add(_snapshot());
  }

  @override
  Future<void> markRead(String conversationId) async {
    if (_w.unread.remove(conversationId)) _inbox.add(_snapshot());
  }
}
