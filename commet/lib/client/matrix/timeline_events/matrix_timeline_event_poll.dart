import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_poll.dart';

/// Matrix implementation of a poll event (MSC3381)
/// Handles both m.poll.start and org.matrix.msc3381.poll.start event types
class MatrixTimelineEventPoll extends MatrixTimelineEvent
    implements TimelineEventPoll {
  MatrixTimelineEventPoll(super.event, {required super.client}) {
    _parsePollContent();
  }

  late String _question;
  late Map<String, String> _options;
  late bool _disclosed;
  late int _maxSelections;
  Map<String, List<String>> _votes = {};
  bool _ended = false;

  @override
  String get question => _question;

  @override
  Map<String, String> get options => _options;

  @override
  bool get disclosed => _disclosed;

  @override
  int get maxSelections => _maxSelections;

  @override
  Map<String, List<String>> get votes => _votes;

  @override
  bool get ended => _ended;

  @override
  String get plainTextBody => "Poll: $_question";

  void _parsePollContent() {
    final content = event.content;

    // Extract poll start block, cast to Map for safe access
    final Map<String, dynamic> pollStart =
        _asMap(content['m.poll.start']) ??
            _asMap(content['org.matrix.msc3381.poll.start']) ??
            content;

    // Parse question
    final questionVal = pollStart['question'];
    if (questionVal is Map) {
      _question = (questionVal['m.text'] ??
              questionVal['org.matrix.msc1767.text'] ??
              questionVal['body'] ??
              'Poll')
          .toString();
    } else {
      _question = questionVal?.toString() ?? 'Poll';
    }

    // Parse options/answers
    _options = {};
    final answers = pollStart['answers'] as List? ?? [];
    for (final answer in answers) {
      if (answer is Map) {
        final id = answer['id']?.toString() ?? '';
        final text = (answer['m.text'] ??
                answer['org.matrix.msc1767.text'] ??
                answer['body'] ??
                '')
            .toString();
        if (id.isNotEmpty) {
          _options[id] = text;
        }
      }
    }

    // Parse kind/disclosure
    final kind = pollStart['kind']?.toString() ?? 'm.disclosed';
    _disclosed = kind != 'm.undisclosed' &&
        kind != 'org.matrix.msc3381.v2.undisclosed';

    // Parse max selections
    final maxSel = pollStart['max_selections'];
    _maxSelections = maxSel is int ? maxSel : 1;
  }

  /// Safely cast dynamic to Map<String, dynamic>
  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Update votes from related poll response events
  void addVote(String userId, String optionId) {
    if (!_options.containsKey(optionId)) return;
    // Remove previous vote by this user
    for (final entry in _votes.entries) {
      entry.value.remove(userId);
    }
    _votes.putIfAbsent(optionId, () => []);
    _votes[optionId]!.add(userId);
  }

  /// Mark poll as ended
  void closePoll() {
    _ended = true;
    _disclosed = true; // Always disclose results when ended
  }
}
