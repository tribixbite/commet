import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/matrix_background/matrix_background_client.dart';
import 'package:commet/client/matrix_background/matrix_background_events.dart';
import 'package:commet/client/matrix_background/matrix_background_member.dart';
import 'package:commet/client/member.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/matrix/matrix_role.dart';
import 'package:commet/client/role.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/debug/log.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/material.dart' show IconData, Icons, ValueKey, UniqueKey;
import 'package:matrix_dart_sdk_drift_db/database.dart';
import 'package:matrix/matrix.dart' as matrix;

/// Background-context room implementation. Many operations are not available
/// in the background service context and will return safe defaults or throw
/// UnsupportedError for operations that require the full foreground client.
class MatrixBackgroundRoom implements Room {
  MatrixBackgroundClient backgroundClient;
  RoomDataData data;
  String roomId;
  List<PreloadRoomStateData> preloadState;
  List<NonPreloadRoomStateData> nonPreloadState;
  late List<matrix.BasicEvent> _stateEvents;

  MatrixBackgroundRoom(
    this.backgroundClient, {
    required this.roomId,
    required this.data,
    required this.preloadState,
    required this.nonPreloadState,
  }) {
    Log.d("Created background room with data: ${data.content}");

    _stateEvents = List.empty(growable: true);
    for (var preload in preloadState) {
      _stateEvents.add(matrix.BasicEvent.fromJson(jsonDecode(preload.content)));
    }

    for (var postLoad in nonPreloadState) {
      _stateEvents
          .add(matrix.BasicEvent.fromJson(jsonDecode(postLoad.content)));
    }
  }

  Future<void> init() async {
    var event = _stateEvents
        .firstWhereOrNull((e) => e.type == matrix.EventTypes.RoomName);

    if (event != null) {
      displayName = event.content["name"] as String;
    }

    var dms = client.getComponent<DirectMessagesComponent>();
    if (dms?.isRoomDirectMessage(this) == true) {
      var partnerId = dms?.getDirectMessagePartnerId(this);
      if (partnerId != null) {
        var partner = await fetchMember(partnerId);
        displayName = partner.displayName;
      }
    }

    if (displayName == "") {
      displayName = identifier;
    }

    if (avatarId != null) {
      avatar = await MatrixBackgroundMember.uriToCachedMxcImageProvider(
          Uri.parse(avatarId!));
    }
  }

  String? get avatarId => _stateEvents
      .firstWhereOrNull((e) => e.type == matrix.EventTypes.RoomAvatar)
      ?.content["url"] as String?;

  @override
  Future<TimelineEvent<Client>?> addReaction(
      TimelineEvent<Client> reactingTo, Emoticon reaction) {
    throw UnsupportedError('Background client does not support reactions');
  }

  @override
  ImageProvider<Object>? avatar;

  @override
  Future<void> cancelSend(TimelineEvent<Client> event) {
    throw UnsupportedError('Background client does not support sending');
  }

  @override
  Client get client => backgroundClient;

  @override
  Future<void> close() async {
    // No resources to release in background context
  }

  @override
  Color get defaultColor => getColorOfUser(identifier);

  @override
  String get developerInfo => 'Background room: $roomId';

  @override
  int get displayHighlightedNotificationCount => highlightedNotificationCount;

  @override
  String displayName = "";

  @override
  int get displayNotificationCount => notificationCount;

  @override
  Future<void> enableE2EE() {
    throw UnsupportedError('Background client does not support enabling E2EE');
  }

  @override
  Future<Member> fetchMember(String id) async {
    var db = backgroundClient.database.db;
    var data = await (db.select(db.roomMembers)
          ..where(
              (tbl) => tbl.roomId.equals(identifier) & tbl.userId.equals(id)))
        .getSingleOrNull();

    MatrixBackgroundMember result = MatrixBackgroundMember(id);
    if (data != null) {
      result = MatrixBackgroundMember(id, data: data);
    }

    await result.init();
    return result;
  }

  @override
  Future<List<Member>> fetchMembersList({bool cache = false}) async {
    // Background client has limited member list access
    return [];
  }

  @override
  List<T> getAllComponents<T extends RoomComponent<Client, Room>>() {
    return [];
  }

  @override
  Color getColorOfUser(String userId) {
    return MatrixPeer.hashColor(userId);
  }

  @override
  T? getComponent<T extends RoomComponent<Client, Room>>() {
    return null;
  }

  @override
  Future<TimelineEvent<Client>?> getEvent(String eventId) async {
    var result =
        await backgroundClient.api.getOneRoomEvent(identifier, eventId);
    Log.i("Received event: ${result}");

    if ([
      matrix.EventTypes.Encrypted,
      matrix.EventTypes.Message,
    ].contains(result.type)) {
      return MatrixBackgroundTimelineEventMessage(result);
    }

    return null;
  }

  @override
  Member getMemberOrFallback(String id) {
    return MatrixBackgroundMember(id);
  }

  @override
  Role getMemberRole(String identifier) {
    return MatrixRole(0);
  }

  @override
  Future<ImageProvider<Object>?> getShortcutImage() async {
    return null;
  }

  @override
  Future<Timeline> getTimeline({String? contextEventId}) {
    throw UnsupportedError('Background client does not support timeline loading');
  }

  @override
  int get highlightedNotificationCount {
    try {
      var content = jsonDecode(data.content);
      return (content['highlight_count'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  IconData get icon => Icons.tag;

  @override
  String get identifier => roomId;

  @override
  List<(Member, Role)> importantMembers() {
    return [];
  }

  @override
  bool get isE2EE =>
      _stateEvents.any((e) => e.type == matrix.EventTypes.Encryption);

  @override
  bool get isMembersListComplete => false;

  @override
  Key get key => ValueKey(localId);

  @override
  TimelineEvent<Client>? get lastEvent => null;

  @override
  DateTime get lastEventTimestamp {
    try {
      var content = jsonDecode(data.content);
      var ts = content['last_event_ts'];
      if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    } catch (_) {}
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  String get localId => '${client.identifier}:$identifier';

  @override
  Iterable<String> get memberIds {
    // Return member IDs from preloaded state if available
    var memberEvents = _stateEvents
        .where((e) => e.type == matrix.EventTypes.RoomMember)
        .map((e) => e.content['state_key'] as String?)
        .whereType<String>();
    return memberEvents;
  }

  @override
  List<Member> membersList() {
    return [];
  }

  @override
  int get notificationCount {
    try {
      var content = jsonDecode(data.content);
      return (content['notification_count'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  final StreamController<void> _onUpdate = StreamController.broadcast();

  @override
  Stream<void> get onUpdate => _onUpdate.stream;

  @override
  Permissions get permissions => _BackgroundPermissions();

  @override
  Future<List<ProcessedAttachment>> processAttachments(
      List<PendingFileAttachment> attachments) {
    throw UnsupportedError('Background client does not support attachments');
  }

  @override
  PushRule get pushRule => PushRule.notify;

  @override
  Future<void> removeReaction(
      TimelineEvent<Client> reactingTo, Emoticon reaction) {
    throw UnsupportedError('Background client does not support reactions');
  }

  @override
  Future<void> retrySend(TimelineEvent<Client> event) {
    throw UnsupportedError('Background client does not support sending');
  }

  @override
  Future<TimelineEvent<Client>?> sendMessage(
      {String? message,
      TimelineEvent<Client>? inReplyTo,
      TimelineEvent<Client>? replaceEvent,
      List<ProcessedAttachment>? processedAttachments}) {
    throw UnsupportedError('Background client does not support sending');
  }

  @override
  Future<void> setDisplayName(String newName) {
    throw UnsupportedError('Background client does not support room modifications');
  }

  @override
  Future<void> setPushRule(PushRule rule) {
    throw UnsupportedError('Background client does not support push rule changes');
  }

  @override
  bool shouldNotify(TimelineEvent<Client> event) {
    // In background context, always notify for safety
    return pushRule != PushRule.dontNotify;
  }

  @override
  bool get shouldPreviewMedia => true;

  @override
  Timeline? get timeline => null;

  @override
  Member? getMember(String id) {
    return null;
  }

  @override
  bool get isSpecialRoomType => false;

  @override
  Future<void> banUser(String id) {
    throw UnsupportedError('Background client does not support moderation');
  }

  @override
  Future<void> kickUser(String id) {
    throw UnsupportedError('Background client does not support moderation');
  }

  @override
  List<Role> get availableRoles => [];

  @override
  Future<void> setMemberRole(String id, Role role) {
    throw UnsupportedError('Background client does not support role changes');
  }

  @override
  String? get topic {
    var event = _stateEvents
        .firstWhereOrNull((e) => e.type == matrix.EventTypes.RoomTopic);
    return event?.content['topic'] as String?;
  }

  @override
  Future<void> setTopic(String topic) {
    throw UnsupportedError('Background client does not support topic changes');
  }

  @override
  Future<void> setRoomAvatar(Uint8List bytes, String? mimeType) {
    throw UnsupportedError('Background client does not support avatar changes');
  }

  @override
  Future<void> markAsRead() async {
    // Background client cannot mark as read - requires foreground client
  }

  @override
  RoomVisibility get visibility {
    var joinRules = _stateEvents
        .firstWhereOrNull((e) => e.type == matrix.EventTypes.RoomJoinRules);
    var rule = joinRules?.content['join_rule'] as String?;
    return switch (rule) {
      'public' => RoomVisibilityPublic(),
      'restricted' => RoomVisibilityRestricted([]),
      _ => RoomVisibilityPrivate(),
    };
  }

  @override
  Future<void> setVisibility(RoomVisibility visibility) {
    throw UnsupportedError('Background client does not support visibility changes');
  }

  @override
  bool get isFavourite => false;

  @override
  Future<void> setFavourite(bool favourite) {
    throw UnsupportedError('Background client does not support favourite changes');
  }
}

/// Read-only permissions for background context
class _BackgroundPermissions extends Permissions {
  @override
  bool get canSendMessage => false;

  @override
  bool get canEditName => false;

  @override
  bool get canEditAvatar => false;

  @override
  bool get canEditTopic => false;

  @override
  bool get canEnableE2EE => false;

  @override
  bool get canBan => false;

  @override
  bool get canKick => false;

  @override
  bool get canChangeRoles => false;

  @override
  bool get canUserEditMessages => false;

  @override
  bool get canDeleteOtherUserMessages => false;

  @override
  bool get canEditRoomEmoticons => false;

  @override
  bool get canEditChildren => false;

  @override
  bool get canInviteUser => false;

  @override
  bool get canChangeVisibility => false;

  @override
  bool get canChangeNotificationSettings => false;
}
