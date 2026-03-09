import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:tiamat/tiamat.dart' as tiamat;

/// Public room directory browser for discovering and joining public rooms
class PublicRoomDirectory extends StatefulWidget {
  const PublicRoomDirectory({super.key});

  @override
  State<PublicRoomDirectory> createState() => _PublicRoomDirectoryState();
}

class _PublicRoomDirectoryState extends State<PublicRoomDirectory> {
  final _searchController = TextEditingController();
  final _serverController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 800));

  List<matrix.PublicRoomsChunk> _rooms = [];
  bool _loading = false;
  String? _nextBatch;
  String? _error;

  matrix.Client? get _matrixClient {
    final clients = clientManager?.clients ?? [];
    for (final c in clients) {
      if (c is MatrixClient) return c.getMatrixClient();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _search(); // Load initial public rooms
  }

  @override
  void dispose() {
    _searchController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _search({bool append = false}) async {
    final mc = _matrixClient;
    if (mc == null) return;

    setState(() {
      _loading = true;
      _error = null;
      if (!append) _rooms = [];
    });

    try {
      final query = _searchController.text.trim();
      final server = _serverController.text.trim();

      final response = await mc.queryPublicRooms(
        limit: 20,
        server: server.isNotEmpty ? server : null,
        since: append ? _nextBatch : null,
        filter: query.isNotEmpty
            ? matrix.PublicRoomQueryFilter(genericSearchTerm: query)
            : null,
      );

      setState(() {
        if (append) {
          _rooms.addAll(response.chunk);
        } else {
          _rooms = response.chunk;
        }
        _nextBatch = response.nextBatch;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Public Rooms"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search public rooms...",
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
              onChanged: (_) {
                _debouncer.run(() => _search());
              },
            ),
          ),
          // Optional server field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _serverController,
              decoration: InputDecoration(
                hintText: "Server (e.g. matrix.org)",
                prefixIcon: const Icon(Icons.dns, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
              onSubmitted: (_) => _search(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          // Error display
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12)),
            ),
          // Results
          Expanded(
            child: _rooms.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator())
                : _rooms.isEmpty
                    ? Center(
                        child: tiamat.Text.labelLow("No rooms found"),
                      )
                    : ListView.builder(
                        itemCount: _rooms.length + (_nextBatch != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _rooms.length) {
                            return _loadMoreButton();
                          }
                          return _roomTile(_rooms[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _roomTile(matrix.PublicRoomsChunk room) {
    final mc = _matrixClient;
    final isJoined =
        mc?.getRoomById(room.roomId) != null;

    return ListTile(
      leading: room.avatarUrl != null && mc != null
          ? CircleAvatar(
              backgroundImage: MatrixMxcImage(
                  room.avatarUrl!, mc,
                  autoLoadFullRes: false, thumbnailHeight: 48),
              radius: 22,
            )
          : CircleAvatar(
              radius: 22,
              child: Icon(
                room.roomType == 'm.space' ? Icons.workspaces : Icons.tag,
                size: 20,
              ),
            ),
      title: Text(
        room.name ?? room.canonicalAlias ?? room.roomId,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room.topic != null && room.topic!.isNotEmpty)
            Text(room.topic!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          Text("${room.numJoinedMembers} members",
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
        ],
      ),
      trailing: isJoined
          ? Chip(
              label: const Text("Joined", style: TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
            )
          : TextButton(
              onPressed: () => _joinRoom(room),
              child: const Text("Join", style: TextStyle(fontSize: 12)),
            ),
      isThreeLine: room.topic != null && room.topic!.isNotEmpty,
    );
  }

  Widget _loadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : OutlinedButton(
                onPressed: () => _search(append: true),
                child: const Text("Load more"),
              ),
      ),
    );
  }

  Future<void> _joinRoom(matrix.PublicRoomsChunk room) async {
    final clients = clientManager?.clients ?? [];
    MatrixClient? mc;
    for (final c in clients) {
      if (c is MatrixClient) {
        mc = c;
        break;
      }
    }
    if (mc == null) return;
    final client = mc;

    try {
      await client.joinRoom(room.roomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Joined ${room.name ?? room.roomId}")),
        );
        setState(() {}); // Refresh joined state
        // Navigate to the room
        EventBus.openRoom.add((room.roomId, client.identifier));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to join: $e")),
        );
      }
    }
  }
}
