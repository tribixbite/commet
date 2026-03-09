import 'package:commet/client/timeline_events/timeline_event.dart';

/// Represents a poll start event (MSC3381 m.poll.start)
abstract class TimelineEventPoll extends TimelineEvent {
  /// The poll question text
  String get question;

  /// Map of option ID -> option text
  Map<String, String> get options;

  /// Whether the poll results are currently visible
  bool get disclosed;

  /// Max number of selections allowed (1 for single-choice)
  int get maxSelections;

  /// Map of option ID -> list of user IDs who voted for it
  Map<String, List<String>> get votes;

  /// Whether the poll has been closed/ended
  bool get ended;
}
