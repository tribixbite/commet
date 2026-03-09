import 'package:commet/client/client.dart';
import 'package:commet/client/timeline_events/timeline_event_location.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:url_launcher/url_launcher.dart';

/// Renders a location event in the timeline with coordinates and a map link
class TimelineEventViewLocation extends StatefulWidget {
  const TimelineEventViewLocation({
    required this.event,
    required this.room,
    super.key,
  });

  final TimelineEventLocation event;
  final Room room;

  @override
  State<TimelineEventViewLocation> createState() =>
      _TimelineEventViewLocationState();
}

class _TimelineEventViewLocationState extends State<TimelineEventViewLocation>
    implements TimelineEventViewWidget {
  @override
  void update(int newIndex) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.event;
    final sender = widget.room.getMemberOrFallback(loc.senderId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender row
          Row(
            children: [
              tiamat.Avatar(
                radius: 14,
                image: sender.avatar,
                placeholderColor: sender.defaultColor,
                placeholderText: sender.displayName,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sender.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: widget.room.getColorOfUser(loc.senderId),
                  ),
                ),
              ),
              Icon(
                loc.isLive ? Icons.my_location : Icons.location_on,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Location card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.place,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        loc.isLive ? "Live Location" : "Shared Location",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (loc.locationDescription != null &&
                    loc.locationDescription!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      loc.locationDescription!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                // Coordinates display
                tiamat.Text.labelLow(
                  "${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}",
                ),
                const SizedBox(height: 8),
                // Open in maps button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openInMaps(loc.latitude, loc.longitude),
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text("Open in Maps",
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
          ),
        ],
      ),
    );
  }

  void _openInMaps(double lat, double lon) {
    // Use OpenStreetMap as a universal web-based map viewer
    final url = Uri.parse(
        'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=16/$lat/$lon');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
