import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/room_header.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/organisms/invitation_view/incoming_invitations_view.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/ui/organisms/home_screen/home_screen_view.dart';
import 'package:commet/utils/update_checker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class HomeScreen extends StatefulWidget {
  final ClientManager clientManager;
  final Client? filterClient;
  final int numRecentRooms;
  final void Function()? onBurgerMenuTap;
  const HomeScreen({
    super.key,
    required this.clientManager,
    this.filterClient,
    this.onBurgerMenuTap,
    this.numRecentRooms = 5,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum RoomFilter { all, unread, favourites }

class _HomeScreenState extends State<HomeScreen> {
  late List<Room> recentActivity;

  Client? filterClient;
  String _searchQuery = '';
  RoomFilter _roomFilter = RoomFilter.all;

  late List<StreamSubscription> subscriptions;

  @override
  void initState() {
    filterClient = widget.filterClient;

    subscriptions = [
      widget.clientManager.onSync.stream.listen(onSync),
      widget.clientManager.onClientRemoved.stream.listen((_) {
        setState(() {
          updateRecent();
        });
      }),
      EventBus.setFilterClient.stream.listen(setFilterClient),
    ];

    if (preferences.checkForUpdates.value == true) {
      UpdateChecker.checkForUpdates();
    }

    updateRecent();
    super.initState();
  }

  @override
  void dispose() {
    for (var element in subscriptions) {
      element.cancel();
    }

    super.dispose();
  }

  void onSync(void event) {
    Future.delayed(Duration(seconds: 1)).then((_) {
      setState(() {
        updateRecent();
      });
    });
  }

  void updateRecent() {
    recentActivity =
        List.from(filterClient?.rooms ?? widget.clientManager.rooms);

    recentActivity.removeWhere((element) => element.lastEvent == null);

    mergeSort(recentActivity, compare: (a, b) {
      return b.lastEventTimestamp.compareTo(a.lastEventTimestamp);
    });

    if (recentActivity.length > widget.numRecentRooms) {
      recentActivity = recentActivity.sublist(0, widget.numRecentRooms);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (Layout.mobile)
          tiamat.Tile.low(
            caulkClipBottomRight: true,
            caulkClipBottomLeft: true,
            caulkBorderBottom: true,
            child: ScaledSafeArea(
              bottom: false,
              left: false,
              right: false,
              child: SizedBox(
                height: 50,
                child: HeaderView(
                  showBurger: Layout.mobile,
                  onBurgerMenuTap: widget.onBurgerMenuTap,
                  text: CommonStrings.promptHome,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search rooms...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _filterChip('All', RoomFilter.all),
              const SizedBox(width: 6),
              _filterChip('Unread', RoomFilter.unread),
              const SizedBox(width: 6),
              _filterChip('Favourites', RoomFilter.favourites),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    IncomingInvitationsWidget(widget.clientManager),
                    HomeScreenView(
                      clientManager: widget.clientManager,
                      rooms: _filterRooms(widget.clientManager
                          .singleRooms(filterClient: filterClient)),
                      recentActivity: _searchQuery.isEmpty
                          ? recentActivity
                          : _filterRooms(recentActivity),
                      favourites: _getFavourites(),
                      onRoomClicked: (room) => EventBus.openRoom
                          .add((room.identifier, room.client.identifier)),
                      onToggleFavourite: (room) async {
                        await room.setFavourite(!room.isFavourite);
                        setState(() {});
                      },
                      joinRoom: joinRoom,
                      createRoom: createRoom,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Future<void> joinRoom(Client client, String address) async {
    await client.joinRoom(address);
  }

  Future<void> createRoom(Client client, CreateRoomArgs args) async {
    await client.createRoom(args);
  }

  void setFilterClient(Client? event) {
    setState(() {
      filterClient = event;
      updateRecent();
    });
  }

  /// Returns rooms marked as favourite, filtered by search query
  List<Room> _getFavourites() {
    var allRooms = filterClient?.rooms ?? widget.clientManager.rooms;
    var favs = allRooms.where((r) => r.isFavourite).toList();
    return _filterBySearch(favs);
  }

  Widget _filterChip(String label, RoomFilter filter) {
    final selected = _roomFilter == filter;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _roomFilter = filter;
        });
      },
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// Filters rooms by search query, matching display name or topic
  List<Room> _filterRooms(List<Room> rooms) {
    var filtered = _filterBySearch(rooms);

    // Apply category filter
    switch (_roomFilter) {
      case RoomFilter.unread:
        filtered =
            filtered.where((r) => r.displayNotificationCount > 0).toList();
        break;
      case RoomFilter.favourites:
        filtered = filtered.where((r) => r.isFavourite).toList();
        break;
      case RoomFilter.all:
        break;
    }

    return filtered;
  }

  /// Filters rooms by text search query only
  List<Room> _filterBySearch(List<Room> rooms) {
    if (_searchQuery.isEmpty) return rooms;
    return rooms
        .where((r) =>
            r.displayName.toLowerCase().contains(_searchQuery) ||
            (r.topic?.toLowerCase().contains(_searchQuery) ?? false))
        .toList();
  }
}
