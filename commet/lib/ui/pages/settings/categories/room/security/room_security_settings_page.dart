import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/get_or_create_room/room_creator.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:tiamat/atoms/tile.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class RoomSecuritySettingsPage extends StatefulWidget {
  const RoomSecuritySettingsPage({
    required this.room,
    this.contextSpace,
    this.showEncryptionToggle = true,
    super.key,
  });
  final Room room;
  final Space? contextSpace;
  final bool showEncryptionToggle;

  @override
  State<RoomSecuritySettingsPage> createState() =>
      _RoomSecuritySettingsPageState();
}

class _RoomSecuritySettingsPageState extends State<RoomSecuritySettingsPage> {
  late bool isE2EEEnabled;
  late RoomVisibility visibility;

  String get promptEnableEncryptionRoomSettings =>
      Intl.message("Enable Encryption",
          name: "promptEnableEncryptionRoomSettings",
          desc: "Short prompt to enable encryption for a room");

  String get encryptionCannotBeDisabledExplanationRoomSettings =>
      Intl.message("If enabled, encryption cannot be disabled later",
          name: "encryptionCannotBeDisabledExplanationRoomSettings",
          desc: "Explains that encryption cannot be disabled once enabled");

  @override
  void initState() {
    isE2EEEnabled = widget.room.isE2EE;
    visibility = widget.room.visibility;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        if (widget.room.client.supportsE2EE && widget.showEncryptionToggle)
          buildE2EEToggle(),
        buildRoomVisibility(),
        // Room version upgrade for Matrix rooms with admin permissions
        if (widget.room is MatrixRoom) _roomUpgradeSection(),
        // Server ACL management for Matrix rooms with admin permissions
        if (widget.room is MatrixRoom) _serverAclSection(),
      ],
    );
  }

  Widget buildE2EEToggle() {
    return tiamat.Panel(
      mode: tiamat.TileType.surfaceContainerLow,
      child: Opacity(
        opacity: widget.room.permissions.canEnableE2EE ? 1 : 0.5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tiamat.Text.labelEmphasised(
                      promptEnableEncryptionRoomSettings),
                  tiamat.Text.labelLow(
                      encryptionCannotBeDisabledExplanationRoomSettings)
                ]),
            IgnorePointer(
              ignoring: isE2EEEnabled || !widget.room.permissions.canEnableE2EE,
              child: tiamat.Switch(
                state: isE2EEEnabled,
                onChanged: (value) {
                  if (value != true) return;
                  setState(() {
                    isE2EEEnabled = true;
                    widget.room.enableE2EE();
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Room version upgrade section - allows admins to upgrade room version
  Widget _roomUpgradeSection() {
    final matrixRoom = (widget.room as MatrixRoom).matrixRoom;
    final currentVersion = matrixRoom.getState(matrix.EventTypes.RoomCreate)
            ?.content['room_version']
            ?.toString() ??
        "1";
    final canUpgrade = widget.room.permissions.canChangeVisibility;

    return tiamat.Panel(
      mode: tiamat.TileType.surfaceContainerLow,
      header: "Room Version",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 6),
                Text("Current version: $currentVersion",
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: tiamat.Text.labelLow(
              "Upgrading creates a new room and sends users a redirect. "
              "This action cannot be undone.",
            ),
          ),
          if (canUpgrade)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: OutlinedButton.icon(
                onPressed: () => _showUpgradeDialog(matrixRoom, currentVersion),
                icon: const Icon(Icons.upgrade, size: 16),
                label: const Text("Upgrade Room",
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: tiamat.Text.labelLow("Admin permissions required."),
            ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(
      matrix.Room matrixRoom, String currentVersion) {
    // Available room versions (v1-v11)
    final versions = ["11", "10", "9", "8", "7", "6", "5", "4", "3", "2", "1"]
        .where((v) => int.parse(v) > int.parse(currentVersion))
        .toList();

    if (versions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Room is already at latest version")),
      );
      return;
    }

    String selectedVersion = versions.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Upgrade Room"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  "This will create a new room and redirect all users. "
                  "Are you sure?",
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedVersion,
                isExpanded: true,
                items: versions
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text("Version $v"),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() {
                      selectedVersion = v;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final newRoomId = await matrixRoom.client
                      .upgradeRoom(matrixRoom.id, selectedVersion);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text("Room upgraded to v$selectedVersion")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Upgrade failed: $e")),
                    );
                  }
                }
              },
              child: const Text("Upgrade"),
            ),
          ],
        ),
      ),
    );
  }

  /// Server ACL (Access Control List) management section
  /// Allows admins to allow/deny specific servers from participating
  Widget _serverAclSection() {
    final matrixRoom = (widget.room as MatrixRoom).matrixRoom;
    final aclEvent = matrixRoom.getState('m.room.server_acl');
    final canEdit = widget.room.permissions.canChangeVisibility;

    // Parse current ACL entries
    List<String> allowList = [];
    List<String> denyList = [];
    bool allowIpLiterals = true;

    if (aclEvent != null) {
      final content = aclEvent.content;
      allowList = (content['allow'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          ['*'];
      denyList =
          (content['deny'] as List?)?.map((e) => e.toString()).toList() ??
              [];
      allowIpLiterals = content['allow_ip_literals'] as bool? ?? true;
    } else {
      allowList = ['*'];
    }

    return tiamat.Panel(
      mode: tiamat.TileType.surfaceContainerLow,
      header: "Server ACL",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: tiamat.Text.labelLow(
              "Control which servers can participate in this room. "
              "Requires admin permissions.",
            ),
          ),
          // Allow IP literals toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                    child: Text("Allow IP literals",
                        style: TextStyle(fontSize: 13))),
                tiamat.Switch(
                  state: allowIpLiterals,
                  onChanged: canEdit
                      ? (value) {
                          _updateAcl(matrixRoom,
                              allow: allowList,
                              deny: denyList,
                              allowIpLiterals: value);
                        }
                      : null,
                ),
              ],
            ),
          ),
          // Denied servers list
          if (denyList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: tiamat.Text.labelEmphasised("Denied Servers"),
            ),
            for (final server in denyList)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
                child: Row(
                  children: [
                    const Icon(Icons.block, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(server,
                            style: const TextStyle(fontSize: 12))),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          final newDeny = List<String>.from(denyList)
                            ..remove(server);
                          _updateAcl(matrixRoom,
                              allow: allowList,
                              deny: newDeny,
                              allowIpLiterals: allowIpLiterals);
                        },
                      ),
                  ],
                ),
              ),
          ],
          // Add server to deny list
          if (canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: OutlinedButton.icon(
                onPressed: () => _addServerToDenyList(
                    matrixRoom, allowList, denyList, allowIpLiterals),
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Block Server",
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Shows dialog to add a server to the deny list
  void _addServerToDenyList(matrix.Room matrixRoom, List<String> allowList,
      List<String> denyList, bool allowIpLiterals) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Block Server"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "example.com",
            labelText: "Server domain",
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              final server = controller.text.trim();
              if (server.isNotEmpty) {
                final newDeny = List<String>.from(denyList)..add(server);
                _updateAcl(matrixRoom,
                    allow: allowList,
                    deny: newDeny,
                    allowIpLiterals: allowIpLiterals);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Block"),
          ),
        ],
      ),
    );
  }

  /// Sends the m.room.server_acl state event with updated values
  Future<void> _updateAcl(matrix.Room matrixRoom,
      {required List<String> allow,
      required List<String> deny,
      required bool allowIpLiterals}) async {
    try {
      await matrixRoom.client.setRoomStateWithKey(
        matrixRoom.id,
        'm.room.server_acl',
        '',
        {
          'allow': allow,
          'deny': deny,
          'allow_ip_literals': allowIpLiterals,
        },
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server ACL updated")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update ACL: $e")),
        );
      }
    }
  }

  Widget buildRoomVisibility() {
    return IgnorePointer(
      ignoring: !widget.room.permissions.canChangeVisibility,
      child: tiamat.Panel(
        header: "Room Visibility",
        mode: TileType.surfaceContainerLow,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              List<String> spaces = List.empty(growable: true);
              if (widget.room.visibility
                  case RoomVisibilityRestricted restricted) {
                spaces.addAll(restricted.spaces);
              }

              if (widget.contextSpace != null &&
                  !spaces.contains(widget.contextSpace?.identifier)) {
                spaces.add(widget.contextSpace!.identifier);
              }

              if (spaces.isEmpty) {
                var parents = widget.room.client.spaces.where((i) => i.subspaces
                    .any((i) => i.identifier == widget.room.identifier));

                for (var p in parents) {
                  spaces.add(p.identifier);
                }
              }

              var items = [
                if (spaces.isNotEmpty) RoomVisibilityRestricted(spaces),
                RoomVisibilityPrivate(),
                RoomVisibilityPublic(),
              ];

              var newVisibility = await AdaptiveDialog.pickOne(
                title: "Set Visibility",
                context,
                items: items,
                itemBuilder: (context, item, callback) {
                  return Material(
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: callback,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RoomFieldVisibility.buildRoomVisibility(
                            widget.room.client, item),
                      ),
                    ),
                  );
                },
              );

              if (newVisibility != null) {
                ErrorUtils.tryRun(context, () async {
                  await widget.room.setVisibility(newVisibility);

                  setState(() {
                    visibility = newVisibility;
                  });
                });
              }
            },
            child: RoomFieldVisibility.buildRoomVisibility(
                widget.room.client, visibility),
          ),
        ),
      ),
    );
  }
}
