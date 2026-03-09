import 'package:commet/client/room.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:commet/main.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomDeveloperSettingsView extends StatelessWidget {
  final Room room;
  const RoomDeveloperSettingsView(this.room, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
      roomIdentifiers(context),
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
