import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineEventLayoutMessage extends StatelessWidget {
  const TimelineEventLayoutMessage(
      {super.key,
      required this.senderName,
      required this.senderColor,
      this.senderAvatar,
      this.formattedContent,
      this.attachments,
      this.inResponseTo,
      this.reactions,
      this.timestamp,
      this.sticker,
      this.thread,
      this.urlPreviews,
      this.readReceipts,
      this.onAvatarTapped,
      this.edited = false,
      this.avatarSize = 32,
      this.avatarBuilder,
      this.showSender = true});
  final String senderName;
  final Color senderColor;
  final ImageProvider? senderAvatar;
  final Widget? formattedContent;
  final Widget? attachments;
  final Widget? inResponseTo;
  final Widget? reactions;
  final Widget? urlPreviews;
  final Widget? thread;
  final Widget? sticker;
  final Widget? readReceipts;
  final bool showSender;
  final bool edited;
  final String? timestamp;
  final Function()? onAvatarTapped;
  final Widget Function(Widget child)? avatarBuilder;

  final double avatarSize;

  String get messageEditedMarker => Intl.message("(Edited)",
      name: "messageEditedMarker",
      desc: "Short text to mark that a message has been edited");

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineMessageBodyBuilt += 1;
    final layoutStyle = preferences.messageLayoutStyle.value;

    // Dispatch to the appropriate layout renderer
    switch (layoutStyle) {
      case "bubble":
        return _buildBubbleLayout(context);
      case "irc":
        return _buildIrcLayout(context);
      default:
        return _buildDefaultLayout(context);
    }
  }

  /// Default layout: avatar on left, name + content in column
  Widget _buildDefaultLayout(BuildContext context) {
    final compact = preferences.compactMode.value;
    final hPad = compact ? 8.0 : 16.0;
    final vPad = compact ? 0.0 : 2.0;
    final avatarGap = compact ? 6.0 : 12.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, compact ? 4.0 : 8.0, vPad),
      child: Column(
        children: [
          if (inResponseTo != null) inResponseTo!,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar(),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(avatarGap, 0, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showSender)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            name(),
                            if (timestamp != null)
                              tiamat.Text.labelLow(timestamp!),
                          ],
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (formattedContent != null)
                                  RepaintBoundary(child: formattedContent!),
                                if (edited)
                                  tiamat.Text.labelLow(messageEditedMarker),
                                if (attachments != null) attachments!,
                                if (sticker != null) sticker!,
                                if (urlPreviews != null) urlPreviews!,
                                if (reactions != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 4, 0, 0),
                                    child: reactions!,
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 35,
                            child: readReceipts,
                          )
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
          if (thread != null) thread!,
        ],
      ),
    );
  }

  /// Bubble layout: messages wrapped in rounded containers with tail
  Widget _buildBubbleLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = preferences.compactMode.value;
    final vPad = compact ? 1.0 : 3.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, vPad, 12, vPad),
      child: Column(
        children: [
          if (inResponseTo != null) inResponseTo!,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showSender) avatar(),
              if (showSender) const SizedBox(width: 8),
              if (!showSender) SizedBox(width: avatarSize + 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: showSender
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showSender)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              name(),
                              const SizedBox(width: 8),
                              if (timestamp != null)
                                tiamat.Text.labelLow(timestamp!),
                            ],
                          ),
                        ),
                      if (formattedContent != null)
                        RepaintBoundary(child: formattedContent!),
                      if (edited)
                        tiamat.Text.labelLow(messageEditedMarker),
                      if (attachments != null) attachments!,
                      if (sticker != null) sticker!,
                      if (urlPreviews != null) urlPreviews!,
                      if (reactions != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: reactions!,
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 30, child: readReceipts),
            ],
          ),
          if (thread != null) thread!,
        ],
      ),
    );
  }

  /// IRC-style layout: compact single-line with inline name prefix
  Widget _buildIrcLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inResponseTo != null) inResponseTo!,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp prefix
              if (timestamp != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: tiamat.Text.labelLow(timestamp!),
                ),
              // Inline sender name
              if (showSender)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: onAvatarTapped,
                    child: Text(
                      "<$senderName>",
                      style: TextStyle(
                        color: senderColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              // Message body
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formattedContent != null)
                      RepaintBoundary(child: formattedContent!),
                    if (edited)
                      tiamat.Text.labelLow(messageEditedMarker),
                    if (attachments != null) attachments!,
                    if (sticker != null) sticker!,
                    if (urlPreviews != null) urlPreviews!,
                    if (reactions != null) reactions!,
                  ],
                ),
              ),
            ],
          ),
          if (thread != null) thread!,
        ],
      ),
    );
  }

  Widget name() {
    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onAvatarTapped,
          child: tiamat.Text.name(
            senderName,
            color: senderColor,
          ),
        ),
      ),
    );
  }

  Widget avatar() {
    Widget result = SizedBox(
      width: avatarSize,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onAvatarTapped,
          child: tiamat.Avatar(
            radius: avatarSize / 2,
            image: senderAvatar,
            placeholderText: senderName,
            placeholderColor: senderColor,
            isPadding: showSender == false,
          ),
        ),
      ),
    );

    if (avatarBuilder != null) {
      result = avatarBuilder!.call(result);
    }

    return result;
  }
}
