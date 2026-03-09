import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/room.dart';

class ReadIndicator extends StatelessWidget {
  const ReadIndicator(
      {required this.room, required this.users, this.onTap, super.key});
  final Room room;
  final Function()? onTap;
  final List<String> users;

  static const int maxItems = 4;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox();

    var diff = users.length - maxItems;
    return Material(
      color: Colors.transparent,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap ?? () => _showReadReceiptDetails(context),
              child: Stack(
                children: [
                  for (int i = 0; i < users.length && i < maxItems; i++)
                    buildEntry(i, context, fade: diff > 0),
                ],
              ),
            )
          ]),
    );
  }

  Widget buildEntry(int index, BuildContext context, {bool fade = false}) {
    var member = room.getMemberOrFallback(users[index]);
    return Opacity(
      opacity: fade ? index / (maxItems - 1) : 1.0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(index.toDouble() * 6, 0, 0, 0),
        child: tiamat.Avatar(
          border: BoxBorder.all(
              color: ColorScheme.of(context).surfaceContainerLow,
              width: 2,
              strokeAlign: 0.5),
          radius: 8,
          image: member.avatar,
          placeholderColor: member.defaultColor,
          placeholderText: member.displayName,
        ),
      ),
    );
  }

  /// Shows a popup with detailed read receipt info (who read, display names)
  void _showReadReceiptDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Read by ${users.length} user${users.length == 1 ? '' : 's'}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final member = room.getMemberOrFallback(users[index]);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: tiamat.Avatar(
                      radius: 18,
                      image: member.avatar,
                      placeholderColor: member.defaultColor,
                      placeholderText: member.displayName,
                    ),
                    title: Text(
                      member.displayName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      users[index],
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(128),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
