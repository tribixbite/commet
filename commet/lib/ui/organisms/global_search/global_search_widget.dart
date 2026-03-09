import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_view_single.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

/// Search result with room context for cross-room display
class GlobalSearchResult {
  final Room room;
  final TimelineEvent event;

  GlobalSearchResult({required this.room, required this.event});
}

/// Global search widget that searches across all rooms for all clients
class GlobalSearchWidget extends StatefulWidget {
  const GlobalSearchWidget({super.key});

  @override
  State<GlobalSearchWidget> createState() => _GlobalSearchWidgetState();
}

class _GlobalSearchWidgetState extends State<GlobalSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final Debouncer _debouncer = Debouncer(delay: const Duration(seconds: 1));

  List<GlobalSearchResult> _results = [];
  bool _loading = false;
  int _roomsSearched = 0;
  int _totalRooms = 0;

  // Track active search subscriptions so we can cancel them
  final List<StreamSubscription> _activeSubscriptions = [];

  @override
  void dispose() {
    _cancelSearch();
    _controller.dispose();
    super.dispose();
  }

  void _cancelSearch() {
    for (var sub in _activeSubscriptions) {
      sub.cancel();
    }
    _activeSubscriptions.clear();
  }

  void _onTextChanged(String value) {
    _cancelSearch();
    setState(() {
      _results = [];
      _roomsSearched = 0;
      _totalRooms = 0;
    });

    if (value.trim().isEmpty) {
      _debouncer.cancel();
      setState(() => _loading = false);
    } else {
      _debouncer.run(() => _startSearch(value));
      setState(() => _loading = _debouncer.running);
    }
  }

  /// Search across all rooms for all logged-in clients
  Future<void> _startSearch(String query) async {
    setState(() {
      _loading = true;
      _results = [];
      _roomsSearched = 0;
    });

    final allRooms = clientManager!.rooms;
    setState(() => _totalRooms = allRooms.length);

    for (final room in allRooms) {
      if (!mounted) return;

      final searchComponent =
          room.client.getComponent<EventSearchComponent>();
      if (searchComponent == null) continue;

      try {
        final session = await searchComponent.createSearchSession(room);
        final stream = session.startSearch(query);

        final sub = stream.listen((events) {
          if (!mounted) return;
          setState(() {
            // Merge results, dedup by eventId
            final existingIds =
                _results.map((r) => r.event.eventId).toSet();
            for (final event in events) {
              if (!existingIds.contains(event.eventId)) {
                _results.add(
                    GlobalSearchResult(room: room, event: event));
                existingIds.add(event.eventId);
              }
            }
            // Sort by timestamp descending
            _results.sort((a, b) =>
                b.event.originServerTs.compareTo(a.event.originServerTs));
          });
        });

        _activeSubscriptions.add(sub);
      } catch (_) {
        // Skip rooms that fail to search
      }

      setState(() {
        _roomsSearched++;
        if (_roomsSearched >= _totalRooms) _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onTextChanged,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: "Search all rooms...",
            border: InputBorder.none,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: _totalRooms > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _totalRooms > 0
                      ? _roomsSearched / _totalRooms
                      : 0,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          if (_results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: tiamat.Text.labelLow(
                "${_results.length} result${_results.length == 1 ? '' : 's'} across ${_results.map((r) => r.room.identifier).toSet().length} room${_results.map((r) => r.room.identifier).toSet().length == 1 ? '' : 's'}",
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                return _buildResultTile(context, result);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(BuildContext context, GlobalSearchResult result) {
    final color = Theme.of(context).colorScheme.surfaceContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              // Navigate to the room and jump to the event
              Navigator.of(context).pop();
              EventBus.openRoom
                  .add((result.room.identifier, result.room.client.identifier));
              // Small delay to let room open before jumping
              Future.delayed(const Duration(milliseconds: 300), () {
                EventBus.jumpToEvent.add(result.event.eventId);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room name header
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(8, 4, 8, 2),
                    child: Row(
                      children: [
                        if (result.room.avatar != null)
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: result.room.avatar,
                          )
                        else
                          CircleAvatar(
                            radius: 10,
                            backgroundColor:
                                result.room.defaultColor,
                            child: Icon(result.room.icon,
                                size: 12, color: Colors.white),
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            result.room.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Event content
                  TimelineEventViewSingle(
                    room: result.room,
                    event: result.event,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
