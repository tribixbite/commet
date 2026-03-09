import 'dart:async';

import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/ui/organisms/room_event_search/room_event_search_widget.dart';
import 'package:commet/ui/organisms/room_members_list/room_members_list.dart';
import 'package:commet/ui/organisms/room_pinned_messages/room_pinned_messages_widget.dart';
import 'package:commet/ui/organisms/room_quick_access_menu/room_quick_access_menu_mobile.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet_calendar_widget/main.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

enum SidePanelState {
  defaultView,
  thread,
  search,
  pinnedMessages,
  calendar,
  roomInfo,
  nothing
}

class RoomSidePanel extends StatefulWidget {
  const RoomSidePanel({required this.state, this.builder, super.key});

  final MainPageState state;

  final Widget Function(SidePanelState state, Widget child)? builder;

  @override
  State<RoomSidePanel> createState() => _RoomSidePanelState();
}

class _RoomSidePanelState extends State<RoomSidePanel> {
  String? _currentThreadId;
  String? get currentThreadId => _currentThreadId;

  late SidePanelState state;

  late List<StreamSubscription> subs;

  @override
  void initState() {
    state = preferences.hideRoomSidePanel.value && Layout.desktop
        ? SidePanelState.nothing
        : SidePanelState.defaultView;

    subs = [
      EventBus.openThread.stream.listen(onOpenThreadSignal),
      EventBus.closeThread.stream.listen(onCloseThreadSignal),
      EventBus.startSearch.stream.listen(onStartSearch),
      EventBus.openPinnedMessages.stream.listen(onShowPinnedMessages),
      EventBus.openCalendar.stream.listen(onShowCalendar),
      EventBus.toggleRoomSidePanel.stream.listen(onToggleSidePanel),
      EventBus.openRoomInfo.stream.listen(onShowRoomInfo),
    ];
    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = buildPanelContent(context);

    result = Material(
      color: Colors.transparent,
      child: result,
    );

    if (widget.builder != null) {
      result = widget.builder!.call(state, result);
    }

    // if (state == _SidePanelState.thread) {
    //   result = Flexible(child: result);
    // }

    return result;
  }

  Widget buildPanelContent(BuildContext context) {
    switch (state) {
      case SidePanelState.defaultView:
        return buildDefaultView();
      case SidePanelState.thread:
        return buildThread();
      case SidePanelState.search:
        return buildSearch();
      case SidePanelState.pinnedMessages:
        return buildPinnedMessages();
      case SidePanelState.calendar:
        return buildCalendar();
      case SidePanelState.roomInfo:
        return buildRoomInfo();
      case SidePanelState.nothing:
        return SizedBox(
          width: 0,
        );
    }
  }

  void onOpenThreadSignal((String, String, String) event) {
    var clientId = event.$1;
    var roomId = event.$2;
    var threadId = event.$3;

    EventBus.openRoom.add((roomId, clientId));

    setState(() {
      _currentThreadId = threadId;
      state = SidePanelState.thread;
    });
  }

  void onCloseThreadSignal(void event) {
    setState(() {
      _currentThreadId = null;
      state = SidePanelState.defaultView;
    });
  }

  Widget buildDefaultView() {
    return Column(
      children: [
        if (Layout.mobile)
          RoomQuickAccessMenuViewMobile(
            room: widget.state.currentRoom!,
            key: ValueKey(
                "quick_access_menu_${widget.state.currentRoom!.localId}"),
          ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: RoomMembersListWidget(widget.state.currentRoom!),
          ),
        ),
      ],
    );
  }

  Widget buildThread() {
    return Tile(
      caulkPadLeft: true,
      caulkClipTopLeft: true,
      caulkClipBottomLeft: true,
      caulkPadBottom: true,
      child: Column(
        children: [
          Flexible(
            child: Stack(
              children: [
                Chat(
                  widget.state.currentRoom!,
                  threadId: currentThreadId,
                  key: ValueKey(
                      "room-timeline-key-${widget.state.currentRoom!.localId}_thread_$currentThreadId"),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: tiamat.CircleButton(
                      icon: Icons.close,
                      radius: 24,
                      onPressed: () => EventBus.closeThread.add(null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearch() {
    return SizedBox(
        width: Layout.desktop ? 300 : null,
        child: RoomEventSearchWidget(
          room: widget.state.currentRoom!,
          onEventClicked: (eventId) {
            EventBus.jumpToEvent.add(eventId);
            EventBus.focusTimeline.add(null);
          },
          close: () => setState(() {
            state = SidePanelState.defaultView;
          }),
        ));
  }

  void onStartSearch(void event) {
    setState(() {
      if (state == SidePanelState.search) {
        state = SidePanelState.defaultView;
      } else {
        state = SidePanelState.search;
      }
    });
  }

  void onShowPinnedMessages(void event) {
    setState(() {
      if (state == SidePanelState.pinnedMessages) {
        state = SidePanelState.defaultView;
      } else {
        state = SidePanelState.pinnedMessages;
      }
    });
  }

  void onShowCalendar(void event) {
    setState(() {
      if (state == SidePanelState.calendar) {
        state = SidePanelState.defaultView;
      } else {
        state = SidePanelState.calendar;
      }
    });
  }

  Widget buildPinnedMessages() {
    return SizedBox(
        width: Layout.desktop ? 300 : null,
        child: Column(
          children: [
            if (Layout.mobile)
              RoomQuickAccessMenuViewMobile(
                room: widget.state.currentRoom!,
                key: ValueKey(
                    "quick_access_menu_${widget.state.currentRoom!.localId}"),
              ),
            Expanded(
              child: RoomPinnedMessagesWidget(
                room: widget.state.currentRoom!,
                onEventClicked: (eventId) {
                  EventBus.jumpToEvent.add(eventId);
                  EventBus.focusTimeline.add(null);
                },
              ),
            ),
          ],
        ));
  }

  Widget buildCalendar() {
    var calendar = widget.state.currentRoom?.getComponent<CalendarRoom>();
    if (calendar?.hasCalendar != true) {
      return Placeholder();
    }

    var query = MediaQuery.of(context);

    return tiamat.Tile.low(
      child: Column(
        children: [
          if (Layout.mobile)
            RoomQuickAccessMenuViewMobile(
              room: widget.state.currentRoom!,
              key: ValueKey(
                  "quick_access_menu_${widget.state.currentRoom!.localId}"),
            ),
          if (Layout.mobile)
            Divider(
              height: 2,
            ),
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            var newQuery = query.copyWith(
              size: Size(constraints.maxWidth, constraints.maxHeight),
            );

            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: ScaledSafeArea(
                top: false,
                bottom: true,
                child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: MediaQuery(
                        data: newQuery,
                        child: CalendarWidgetView(
                            calendar: calendar!.calendar!,
                            watermark: false,
                            useMobileLayout: Layout.mobile,
                            autoDisposeCalendar: false))),
              ),
            );
          })),
        ],
      ),
    );
  }

  void onShowRoomInfo(void event) {
    setState(() {
      if (state == SidePanelState.roomInfo) {
        state = SidePanelState.defaultView;
      } else {
        state = SidePanelState.roomInfo;
      }
    });
  }

  /// Builds a room info panel with room statistics and details
  Widget buildRoomInfo() {
    final room = widget.state.currentRoom;
    if (room == null) return const SizedBox();

    return SizedBox(
      width: Layout.desktop ? 300 : null,
      child: Column(
        children: [
          if (Layout.mobile)
            RoomQuickAccessMenuViewMobile(
              room: room,
              key: ValueKey("quick_access_menu_${room.localId}"),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Room avatar and name header
                Center(
                  child: Column(
                    children: [
                      if (room.avatar != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: room.avatar,
                        )
                      else
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: room.defaultColor,
                          child: Icon(room.icon, size: 32, color: Colors.white),
                        ),
                      const SizedBox(height: 8),
                      tiamat.Text.labelEmphasised(room.displayName),
                      if (room.topic != null && room.topic!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: tiamat.Text.labelLow(room.topic!),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                // Room statistics
                tiamat.Text.labelEmphasised("Room Info"),
                const SizedBox(height: 8),
                _infoRow(Icons.people, "Members",
                    "${room.memberIds.length}"),
                _infoRow(Icons.lock,
                    "Encryption", room.isE2EE ? "Enabled" : "Disabled"),
                _infoRow(Icons.access_time, "Last Activity",
                    _formatTimestamp(room.lastEventTimestamp)),
                _infoRow(Icons.notifications, "Unread",
                    "${room.notificationCount}"),
                _infoRow(Icons.star, "Favourite",
                    room.isFavourite ? "Yes" : "No"),
                _infoRow(Icons.tag, "Room ID", room.identifier),
                const Divider(height: 24),
                // Quick actions
                tiamat.Text.labelEmphasised("Actions"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.search, size: 18),
                      label: const Text("Search"),
                      onPressed: () => EventBus.startSearch.add(null),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.push_pin, size: 18),
                      label: const Text("Pins"),
                      onPressed: () =>
                          EventBus.openPinnedMessages.add(null),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.people, size: 18),
                      label: const Text("Members"),
                      onPressed: () => setState(() {
                        state = SidePanelState.defaultView;
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          tiamat.Text.labelLow(label),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inHours < 1) return "${diff.inMinutes}m ago";
    if (diff.inDays < 1) return "${diff.inHours}h ago";
    if (diff.inDays < 30) return "${diff.inDays}d ago";
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  void onToggleSidePanel(void event) {
    preferences.hideRoomSidePanel.set(!preferences.hideRoomSidePanel.value);

    if (preferences.hideRoomSidePanel.value) {
      setState(() {
        state = SidePanelState.nothing;
      });
    } else {
      setState(() {
        state = SidePanelState.defaultView;
      });
    }
  }
}
