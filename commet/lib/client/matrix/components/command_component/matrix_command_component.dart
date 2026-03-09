import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/command/command_component.dart';
import 'package:commet/client/components/emoticon_recent/recent_emoticon_component.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/matrix/components/profile/matrix_profile_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/matrix_api_lite/generated/model.dart';
import 'package:uuid/uuid.dart';

class MatrixCommandComponent extends CommandComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixCommandComponent(this.client) {
    client.getMatrixClient().addCommand("sendjson", sendJson);
    client.getMatrixClient().addCommand("status", setStatus);
    client.getMatrixClient().addCommand("clearemojistats", clearEmojiStats);
    client.getMatrixClient().addCommand("setprofile", setProfile);
    client.getMatrixClient().addCommand("addwidget", addWidget);
    client.getMatrixClient().addCommand("shrug", _shrug);
    client.getMatrixClient().addCommand("tableflip", _tableflip);
    client.getMatrixClient().addCommand("unflip", _unflip);
    client.getMatrixClient().addCommand("lenny", _lenny);
    client.getMatrixClient().addCommand("nick", _nick);
    client.getMatrixClient().addCommand("roomnick", _roomNick);
    client.getMatrixClient().addCommand("rainbow", _rainbow);
    client.getMatrixClient().addCommand("plain", _plain);
    client.getMatrixClient().addCommand("spoiler", _spoiler);
    client.getMatrixClient().addCommand("confetti", _confetti);
  }

  @override
  List<String> getCommands() {
    return client.getMatrixClient().commands.keys.toList();
  }

  @override
  Future<void> executeCommand(String string, Room room,
      {TimelineEvent? interactingEvent, EventInteractionType? type}) async {
    var mxRoom = (room as MatrixRoom).matrixRoom;
    matrix.Event? event;
    if (interactingEvent != null) {
      event = (interactingEvent as MatrixTimelineEvent).event;
    }

    await client.getMatrixClient().parseAndRunCommand(
          mxRoom,
          string,
          inReplyTo: type == EventInteractionType.reply ? event : null,
          editEventId:
              type == EventInteractionType.edit ? event?.eventId : null,
        );
  }

  @override
  bool isExecutable(String string) {
    if (string.startsWith("/")) {
      var command = string.substring(1).split(" ").first;
      return client.getMatrixClient().commands.containsKey(command);
    }

    return false;
  }

  FutureOr<String?> sendJson(matrix.CommandArgs args, StringBuffer? out) {
    var json = const JsonDecoder().convert(args.msg) as Map<String, dynamic>;

    var tx = client.getMatrixClient().generateUniqueTransactionId();
    client
        .getMatrixClient()
        .sendMessage(args.room!.id, json["type"], tx, json['content']);

    return null;
  }

  @override
  bool isPossiblyCommand(String string) {
    return string.startsWith("/");
  }

  FutureOr<String?> setStatus(
      matrix.CommandArgs args, StringBuffer? out) async {
    client.getComponent<UserProfileComponent>()?.setStatus(args.msg);

    await client.getMatrixClient().setPresence(
        client.getMatrixClient().userID!, PresenceType.online,
        statusMsg: args.msg);

    return null;
  }

  FutureOr<String?> clearEmojiStats(
      matrix.CommandArgs args, StringBuffer? out) async {
    var c = client.getComponent<RecentEmoticonComponent>();
    c?.clear();
    return null;
  }

  FutureOr<String?> setProfile(
      matrix.CommandArgs args, StringBuffer? stdout) async {
    final parts = args.msg.split(" ");
    final field = parts[0];
    final content = parts.sublist(1).join(" ");
    dynamic result = content;
    try {
      result = jsonDecode(content);
    } catch (e, s) {
      Log.onError(e, s);
    }

    var comp = client.getComponent<MatrixProfileComponent>();
    comp?.setField(field, result);

    return null;
  }

  FutureOr<String?> addWidget(
      matrix.CommandArgs args, StringBuffer? out) async {
    if (args.room == null) return null;

    var url = Uri.parse(args.msg);
    var uuid = const Uuid();
    var id = uuid.v4();

    var content = {
      "type": "m.custom",
      "url": url.toString(),
      "name": "Custom",
      "id": id,
      "creatorUserId": client.self!.identifier,
      "roomId": args.room!.id,
    };

    if (url.host == "calendar-widget.commet.chat") {
      content["type"] = "chat.commet.widgets.calendar";
      content["name"] = "Calendar";
    }

    await client.matrixClient.setRoomStateWithKey(
        args.room!.id, "im.vector.modular.widgets", id, content);

    return null;
  }

  /// Appends ¯\_(ツ)_/¯ to the message
  FutureOr<String?> _shrug(
      matrix.CommandArgs args, StringBuffer? out) async {
    final text = args.msg.isEmpty ? r'¯\_(ツ)_/¯' : '${args.msg} ¯\\_(ツ)_/¯';
    await args.room?.sendTextEvent(text);
    return null;
  }

  /// Sends (╯°□°)╯︵ ┻━┻
  FutureOr<String?> _tableflip(
      matrix.CommandArgs args, StringBuffer? out) async {
    final text = args.msg.isEmpty
        ? '(╯°□°)╯︵ ┻━┻'
        : '${args.msg} (╯°□°)╯︵ ┻━┻';
    await args.room?.sendTextEvent(text);
    return null;
  }

  /// Sends ┬─┬ ノ( ゜-゜ノ)
  FutureOr<String?> _unflip(
      matrix.CommandArgs args, StringBuffer? out) async {
    final text = args.msg.isEmpty
        ? '┬─┬ ノ( ゜-゜ノ)'
        : '${args.msg} ┬─┬ ノ( ゜-゜ノ)';
    await args.room?.sendTextEvent(text);
    return null;
  }

  /// Sends ( ͡° ͜ʖ ͡°)
  FutureOr<String?> _lenny(
      matrix.CommandArgs args, StringBuffer? out) async {
    final text =
        args.msg.isEmpty ? '( ͡° ͜ʖ ͡°)' : '${args.msg} ( ͡° ͜ʖ ͡°)';
    await args.room?.sendTextEvent(text);
    return null;
  }

  /// Changes display name across all rooms
  FutureOr<String?> _nick(
      matrix.CommandArgs args, StringBuffer? out) async {
    if (args.msg.isEmpty) return 'Usage: /nick <display name>';
    await client.setDisplayName(args.msg);
    return null;
  }

  /// Changes display name in the current room only
  FutureOr<String?> _roomNick(
      matrix.CommandArgs args, StringBuffer? out) async {
    if (args.msg.isEmpty || args.room == null) {
      return 'Usage: /roomnick <display name>';
    }
    final userId = client.getMatrixClient().userID!;
    await args.room!.setMemberDisplayName(userId, args.msg);
    return null;
  }

  /// Sends message with rainbow-colored HTML spans
  FutureOr<String?> _rainbow(
      matrix.CommandArgs args, StringBuffer? out) async {
    if (args.msg.isEmpty) return 'Usage: /rainbow <message>';
    final colors = [
      '#ff0000', '#ff7f00', '#ffff00', '#00ff00',
      '#0000ff', '#4b0082', '#9400d3',
    ];
    final buf = StringBuffer();
    int colorIndex = 0;
    for (var i = 0; i < args.msg.length; i++) {
      final ch = args.msg[i];
      if (ch == ' ') {
        buf.write(' ');
      } else {
        buf.write(
            '<font color="${colors[colorIndex % colors.length]}">$ch</font>');
        colorIndex++;
      }
    }
    await args.room?.sendEvent({
      'msgtype': matrix.MessageTypes.Text,
      'body': args.msg,
      'format': 'org.matrix.custom.html',
      'formatted_body': buf.toString(),
    });
    return null;
  }

  /// Sends message as plain text without markdown processing
  FutureOr<String?> _plain(
      matrix.CommandArgs args, StringBuffer? out) async {
    if (args.msg.isEmpty) return 'Usage: /plain <message>';
    await args.room?.sendTextEvent(args.msg);
    return null;
  }

  /// Wraps message in a spoiler tag
  FutureOr<String?> _spoiler(
      matrix.CommandArgs args, StringBuffer? out) async {
    if (args.msg.isEmpty) return 'Usage: /spoiler <message>';
    // Parse optional reason: /spoiler reason|hidden text
    String reason = '';
    String content = args.msg;
    if (args.msg.contains('|')) {
      final parts = args.msg.split('|');
      reason = parts[0].trim();
      content = parts.sublist(1).join('|').trim();
    }
    final reasonAttr = reason.isNotEmpty ? ' data-mx-spoiler="$reason"' : ' data-mx-spoiler';
    await args.room?.sendEvent({
      'msgtype': matrix.MessageTypes.Text,
      'body': '||${args.msg}||',
      'format': 'org.matrix.custom.html',
      'formatted_body': '<span$reasonAttr>$content</span>',
    });
    return null;
  }

  /// Sends message with confetti effect (Commet-specific)
  FutureOr<String?> _confetti(
      matrix.CommandArgs args, StringBuffer? out) async {
    if (args.msg.isEmpty) return 'Usage: /confetti <message>';
    await args.room?.sendEvent({
      'msgtype': matrix.MessageTypes.Text,
      'body': args.msg,
      'chat.commet.effect': 'confetti',
    });
    return null;
  }
}
