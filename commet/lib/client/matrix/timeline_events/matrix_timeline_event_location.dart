import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_location.dart';

/// Matrix implementation of a location sharing event (MSC3488/MSC3489)
/// Handles both m.location and org.matrix.msc3488.location content types
class MatrixTimelineEventLocation extends MatrixTimelineEvent
    implements TimelineEventLocation {
  MatrixTimelineEventLocation(super.event, {required super.client}) {
    _parseLocationContent();
  }

  late double _latitude;
  late double _longitude;
  String? _description;
  late String _geoUri;
  bool _isLive = false;

  @override
  double get latitude => _latitude;

  @override
  double get longitude => _longitude;

  @override
  String? get locationDescription => _description;

  @override
  String get geoUri => _geoUri;

  @override
  bool get isLive => _isLive;

  @override
  String get plainTextBody =>
      _description ?? "Location: $_latitude, $_longitude";

  void _parseLocationContent() {
    final content = event.content;

    // Try stable MSC3488 format first, then unstable prefix
    final locationBlock = _asMap(content['m.location']) ??
        _asMap(content['org.matrix.msc3488.location']) ??
        content;

    // Parse geo: URI
    _geoUri = (locationBlock['uri'] ?? content['geo_uri'] ?? '').toString();

    // Parse coordinates from geo: URI (format: "geo:lat,lon" or "geo:lat,lon;u=uncertainty")
    _latitude = 0;
    _longitude = 0;
    if (_geoUri.startsWith('geo:')) {
      final coords = _geoUri.substring(4).split(';').first.split(',');
      if (coords.length >= 2) {
        _latitude = double.tryParse(coords[0]) ?? 0;
        _longitude = double.tryParse(coords[1]) ?? 0;
      }
    }

    // Parse description
    _description = locationBlock['description']?.toString() ??
        content['body']?.toString();

    // Check for live location (MSC3489)
    _isLive = content.containsKey('org.matrix.msc3672.beacon_info') ||
        content.containsKey('m.beacon_info') ||
        event.type == 'org.matrix.msc3672.beacon' ||
        event.type == 'm.beacon';
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
