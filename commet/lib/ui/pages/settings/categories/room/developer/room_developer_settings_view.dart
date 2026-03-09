import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/room.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:commet/main.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomDeveloperSettingsView extends StatelessWidget {
  final Room room;
  const RoomDeveloperSettingsView(this.room, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
      roomIdentifiers(context),
      exportChat(context),
      jsonDump(context),
      notificationTests(context),
    ].map<Widget>((e) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: e),
      );
    }).toList());
  }

  Widget roomIdentifiers(BuildContext context) {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Room Identifiers"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      initiallyExpanded: true,
      children: [
        ListTile(
          title: const Text("Room ID"),
          subtitle: SelectableText(room.identifier),
          trailing: IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: room.identifier));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Room ID copied")),
              );
            },
          ),
        ),
        ListTile(
          title: const Text("Matrix Permalink"),
          subtitle: SelectableText('https://matrix.to/#/${room.identifier}'),
          trailing: IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text: 'https://matrix.to/#/${room.identifier}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Permalink copied")),
              );
            },
          ),
        ),
        if (room.topic != null)
          ListTile(
            title: const Text("Topic"),
            subtitle: SelectableText(room.topic!),
          ),
      ],
    );
  }

  Widget exportChat(BuildContext context) {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Export Chat"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
            text: "Export as Text",
            onTap: () => _exportAsText(context),
          ),
          tiamat.Button(
            text: "Export as JSON",
            onTap: () => _exportAsJson(context),
          ),
          tiamat.Button(
            text: "Copy to Clipboard",
            onTap: () => _copyToClipboard(context),
          ),
        ]),
      ],
    );
  }

  /// Exports timeline events as plain text
  void _exportAsText(BuildContext context) async {
    final timeline = room.timeline;
    if (timeline == null) return;

    final buffer = StringBuffer();
    buffer.writeln('=== ${room.displayName} ===');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Room ID: ${room.identifier}');
    buffer.writeln('');

    final events = timeline.events.reversed.toList();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (final event in events) {
      final sender = room.getMemberOrFallback(event.senderId).displayName;
      final time = dateFormat.format(event.originServerTs);
      final body = event.plainTextBody;
      buffer.writeln('[$time] $sender: $body');
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    await FilePicker.platform.saveFile(
      fileName: '${room.displayName}_export.txt',
      bytes: bytes,
    );
  }

  /// Exports timeline events as JSON
  void _exportAsJson(BuildContext context) async {
    final timeline = room.timeline;
    if (timeline == null) return;

    final events = timeline.events.reversed.map((event) {
      return {
        'event_id': event.eventId,
        'sender': event.senderId,
        'timestamp': event.originServerTs.toIso8601String(),
        'body': event.plainTextBody,
        'source': event.source,
      };
    }).toList();

    final json = const JsonEncoder.withIndent('  ').convert({
      'room_id': room.identifier,
      'room_name': room.displayName,
      'exported_at': DateTime.now().toIso8601String(),
      'event_count': events.length,
      'events': events,
    });

    final bytes = Uint8List.fromList(utf8.encode(json));
    await FilePicker.platform.saveFile(
      fileName: '${room.displayName}_export.json',
      bytes: bytes,
    );
  }

  /// Copies chat text to clipboard
  void _copyToClipboard(BuildContext context) {
    final timeline = room.timeline;
    if (timeline == null) return;

    final buffer = StringBuffer();
    final events = timeline.events.reversed.toList();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (final event in events) {
      final sender = room.getMemberOrFallback(event.senderId).displayName;
      final time = dateFormat.format(event.originServerTs);
      final body = event.plainTextBody;
      buffer.writeln('[$time] $sender: $body');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chat exported to clipboard")),
    );
  }

  Widget jsonDump(BuildContext context) {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Room State"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        SelectionArea(
          child: Codeblock(
            language: "json",
            text: room.developerInfo,
          ),
        )
      ],
    );
  }

  Widget notificationTests(BuildContext context) {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Shortcuts"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
            text: "Register Shortcut",
            onTap: () => shortcutsManager.createShortcutForRoom(room),
          ),
          tiamat.Button(
            text: "Clear All Shortcuts",
            onTap: () => shortcutsManager.clearAllShortcuts(),
          ),
        ])
      ],
    );
  }
}
