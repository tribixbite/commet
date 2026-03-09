import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/ui/pages/matrix/room_address_settings/matrix_room_address_settings.dart';
import 'package:commet/ui/pages/settings/categories/room/general/room_general_settings_view.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomGeneralSettingsPage extends StatefulWidget {
  const RoomGeneralSettingsPage({super.key, required this.room});
  final Room room;
  @override
  State<RoomGeneralSettingsPage> createState() =>
      _RoomGeneralSettingsPageState();
}

class _RoomGeneralSettingsPageState extends State<RoomGeneralSettingsPage> {
  late PushRule pushRule;
  late bool isFavourite;

  /// Current message retention duration label (for display only)
  String _retentionLabel = "Off";

  @override
  void initState() {
    pushRule = widget.room.pushRule;
    isFavourite = widget.room.isFavourite;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RoomGeneralSettingsView(
          pushRule: pushRule,
          onPushRuleChanged: setPushRule,
          isFavourite: isFavourite,
          onToggleFavourite: (value) {
            setState(() {
              isFavourite = value;
            });
            widget.room.setFavourite(value);
          },
        ),
        const SizedBox(height: 10),
        // Disappearing messages / message retention UI
        _messageRetentionSection(),
        const SizedBox(height: 10),
        if (widget.room is MatrixRoom)
          MatrixRoomAddressSettings((widget.room as MatrixRoom).matrixRoom)
      ],
    );
  }

  /// Message retention / disappearing messages section
  Widget _messageRetentionSection() {
    return tiamat.Panel(
      mode: tiamat.TileType.surfaceContainerLow,
      header: "Disappearing Messages",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: tiamat.Text.labelLow(
              "When enabled, messages will be automatically deleted after the specified time. "
              "This requires room admin permissions to set.",
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 18),
                const SizedBox(width: 8),
                Text("Current: $_retentionLabel",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _retentionChip("Off", null),
                _retentionChip("1 hour", const Duration(hours: 1)),
                _retentionChip("1 day", const Duration(days: 1)),
                _retentionChip("7 days", const Duration(days: 7)),
                _retentionChip("30 days", const Duration(days: 30)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _retentionChip(String label, Duration? duration) {
    final isSelected = _retentionLabel == label;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _retentionLabel = label;
        });
        // TODO: Send m.room.retention state event when protocol support is stable
        // This would require: room.client.sendStateEvent(
        //   room.identifier, 'm.room.retention',
        //   {'max_lifetime': duration?.inMilliseconds}, '')
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(duration == null
                ? "Disappearing messages disabled"
                : "Messages will disappear after $label"),
          ),
        );
      },
    );
  }

  void setPushRule(PushRule? rule) {
    if (rule == null) return;

    setState(() {
      pushRule = rule;
    });

    widget.room.setPushRule(rule);
  }
}
