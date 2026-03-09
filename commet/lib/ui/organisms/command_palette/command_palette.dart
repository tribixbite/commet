import 'package:commet/main.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/organisms/global_search/global_search_widget.dart';
import 'package:commet/ui/pages/settings/app_settings_page.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Command palette entry definition
class CommandPaletteAction {
  final String name;
  final String? description;
  final IconData icon;
  final VoidCallback action;

  CommandPaletteAction({
    required this.name,
    this.description,
    required this.icon,
    required this.action,
  });
}

/// Quick action launcher (Ctrl+K / Cmd+K)
/// Shows a searchable list of commands, rooms, and actions
class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key});

  /// Shows the command palette as an overlay dialog
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        child: CommandPalette(),
      ),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _controller = TextEditingController();
  late List<CommandPaletteAction> _allActions;
  List<CommandPaletteAction> _filtered = [];
  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _allActions = _buildActions();
    _filtered = _allActions;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<CommandPaletteAction> _buildActions() {
    final actions = <CommandPaletteAction>[
      CommandPaletteAction(
        name: "Search All Rooms",
        description: "Search messages across all rooms",
        icon: Icons.search,
        action: () {
          Navigator.of(context).pop();
          NavigationUtils.navigateTo(context, const GlobalSearchWidget());
        },
      ),
      CommandPaletteAction(
        name: "Settings",
        description: "Open app settings",
        icon: Icons.settings,
        action: () {
          Navigator.of(context).pop();
          NavigationUtils.navigateTo(context, const AppSettingsPage());
        },
      ),
      CommandPaletteAction(
        name: "Toggle Side Panel",
        description: "Show or hide the side panel",
        icon: Icons.view_sidebar,
        action: () {
          Navigator.of(context).pop();
          EventBus.toggleRoomSidePanel.add(null);
        },
      ),
      CommandPaletteAction(
        name: "Search in Room",
        description: "Search messages in current room",
        icon: Icons.find_in_page,
        action: () {
          Navigator.of(context).pop();
          EventBus.startSearch.add(null);
        },
      ),
      CommandPaletteAction(
        name: "Pinned Messages",
        description: "View pinned messages in current room",
        icon: Icons.push_pin,
        action: () {
          Navigator.of(context).pop();
          EventBus.openPinnedMessages.add(null);
        },
      ),
      CommandPaletteAction(
        name: "Room Info",
        description: "View room details and statistics",
        icon: Icons.info_outline,
        action: () {
          Navigator.of(context).pop();
          EventBus.openRoomInfo.add(null);
        },
      ),
    ];

    // Add rooms as quick-nav actions
    if (clientManager != null) {
      for (final room in clientManager!.rooms) {
        actions.add(CommandPaletteAction(
          name: "Go to: ${room.displayName}",
          description: room.identifier,
          icon: Icons.tag,
          action: () {
            Navigator.of(context).pop();
            EventBus.openRoom
                .add((room.identifier, room.client.identifier));
          },
        ));
      }
    }

    return actions;
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _allActions;
      } else {
        final lowerQuery = query.toLowerCase();
        _filtered = _allActions
            .where((a) =>
                a.name.toLowerCase().contains(lowerQuery) ||
                (a.description?.toLowerCase().contains(lowerQuery) ??
                    false))
            .toList();
      }
      _selectedIndex = 0;
    });
  }

  void _executeSelected() {
    if (_filtered.isNotEmpty && _selectedIndex < _filtered.length) {
      _filtered[_selectedIndex].action();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              _selectedIndex =
                  (_selectedIndex + 1).clamp(0, _filtered.length - 1);
            });
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              _selectedIndex =
                  (_selectedIndex - 1).clamp(0, _filtered.length - 1);
            });
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            _executeSelected();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(60),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search input
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _executeSelected(),
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: "Type a command or room name...",
                  prefixIcon: Icon(Icons.bolt,
                      color: Theme.of(context).colorScheme.primary),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            // Results list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(4),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final action = _filtered[index];
                  final isSelected = index == _selectedIndex;
                  return Material(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => action.action(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(action.icon,
                                size: 18,
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                          : null,
                                    ),
                                  ),
                                  if (action.description != null)
                                    Text(
                                      action.description!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withAlpha(128),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "No matching commands",
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
