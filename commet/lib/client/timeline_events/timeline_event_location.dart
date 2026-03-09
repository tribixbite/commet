import 'package:commet/client/timeline_events/timeline_event.dart';

/// Abstract location event for MSC3488 location sharing
abstract class TimelineEventLocation extends TimelineEvent {
  /// Latitude coordinate
  double get latitude;

  /// Longitude coordinate
  double get longitude;

  /// Human-readable description of the location
  String? get locationDescription;

  /// geo: URI (e.g. "geo:51.5074,-0.1278")
  String get geoUri;

  /// Whether this is a live-updating location (MSC3489)
  bool get isLive;
}
