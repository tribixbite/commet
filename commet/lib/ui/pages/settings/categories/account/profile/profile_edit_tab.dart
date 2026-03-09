import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/ui/organisms/user_profile/user_profile.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as material;
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class ProfileEditTab extends StatefulWidget {
  const ProfileEditTab(
      {required this.clientManager, this.selectedClientIndex = 0, super.key});
  final ClientManager clientManager;
  final int selectedClientIndex;
  @override
  State<ProfileEditTab> createState() => _ProfileEditTabState();
}

class _ProfileEditTabState extends State<ProfileEditTab> {
  Client? selectedClient;

  @override
  void initState() {
    selectedClient = widget.clientManager.clients[widget.selectedClientIndex];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var client = widget.clientManager.clients[index];
        return Column(
          children: [
            UserProfile(
              userId: client.self!.identifier,
              client: client,
              maxBioHeight: double.infinity,
            ),
            const SizedBox(height: 8),
            _statusEditor(client),
            const Seperator()
          ],
        );
      },
      itemCount: widget.clientManager.clients.length,
    );
  }

  /// Custom presence status editor per account
  Widget _statusEditor(Client client) {
    final presence = client.getComponent<UserPresenceComponent>();
    if (presence == null) return const SizedBox();

    return tiamat.Panel(
      mode: TileType.surfaceContainerLow,
      header: "Custom Status",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: tiamat.Text.labelLow(
              "Set a custom status message visible to other users.",
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (value) async {
                      if (value.trim().isEmpty) {
                        await presence.setStatus(UserPresenceStatus.online,
                            clearMessage: true);
                      } else {
                        await presence.setStatus(UserPresenceStatus.online,
                            message: value.trim());
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: material.Text("Status updated")),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Presence status selector
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Wrap(
              spacing: 6,
              children: [
                _presenceChip(
                    "Online", UserPresenceStatus.online, Colors.green, presence),
                _presenceChip("Away", UserPresenceStatus.unavailable,
                    Colors.orange, presence),
                _presenceChip("Offline", UserPresenceStatus.offline,
                    Colors.grey, presence),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presenceChip(String label, UserPresenceStatus status, Color color,
      UserPresenceComponent presence) {
    return ActionChip(
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      label: material.Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () async {
        await presence.setStatus(status);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: material.Text("Status set to $label")),
          );
        }
      },
    );
  }

  void pickAvatar(Client client, Uint8List bytes, String? type) async {
    await client.setAvatar(bytes, type ?? "");
    setState(() {});
  }

  void setDisplayName(Client client, String name) async {
    await client.setDisplayName(name);
  }
}
