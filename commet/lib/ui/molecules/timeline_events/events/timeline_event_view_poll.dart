import 'package:commet/client/client.dart';
import 'package:commet/client/timeline_events/timeline_event_poll.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

/// Renders a poll event in the timeline with question, options, and vote counts
class TimelineEventViewPoll extends StatefulWidget {
  const TimelineEventViewPoll({
    required this.event,
    required this.room,
    this.onVote,
    super.key,
  });

  final TimelineEventPoll event;
  final Room room;
  final void Function(String optionId)? onVote;

  @override
  State<TimelineEventViewPoll> createState() => _TimelineEventViewPollState();
}

class _TimelineEventViewPollState extends State<TimelineEventViewPoll>
    implements TimelineEventViewWidget {
  @override
  void update(int newIndex) {
    setState(() {});
  }

  int get totalVotes {
    int total = 0;
    for (final voters in widget.event.votes.values) {
      total += voters.length;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.event;
    final sender = widget.room.getMemberOrFallback(poll.senderId);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sender.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: widget.room.getColorOfUser(poll.senderId),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.poll, size: 18,
                  color: Theme.of(context).colorScheme.primary),
            ],
          ),
          const SizedBox(height: 8),
          // Poll question
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poll.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                if (poll.ended)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          "Poll ended",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Poll options
                ...poll.options.entries.map((entry) {
                  final optionId = entry.key;
                  final optionText = entry.value;
                  final voteCount =
                      poll.votes[optionId]?.length ?? 0;
                  final fraction =
                      totalVotes > 0 ? voteCount / totalVotes : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: InkWell(
                      onTap: poll.ended
                          ? null
                          : () => widget.onVote?.call(optionId),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withAlpha(60),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              // Vote bar background
                              if (poll.disclosed || poll.ended)
                                FractionallySizedBox(
                                  widthFactor: fraction,
                                  child: Container(
                                    height: 40,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(40),
                                  ),
                                ),
                              // Option text and count
                              Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: const TextStyle(
                                            fontSize: 13),
                                      ),
                                    ),
                                    if (poll.disclosed || poll.ended)
                                      Text(
                                        "$voteCount",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                // Total votes count
                tiamat.Text.labelLow(
                  "$totalVotes vote${totalVotes == 1 ? '' : 's'}${poll.maxSelections > 1 ? ' (multi-select)' : ''}",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
