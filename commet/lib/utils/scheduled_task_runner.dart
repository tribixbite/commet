import 'dart:async';

import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/event_bus.dart';

/// Periodically checks for due scheduled messages and reminders,
/// executing them when their scheduled time arrives.
class ScheduledTaskRunner {
  static Timer? _timer;

  /// Start the periodic checker (every 30 seconds)
  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
    Log.i("ScheduledTaskRunner started");
  }

  /// Stop the periodic checker
  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static void _tick() {
    _processDueScheduledMessages();
    _processDueReminders();
  }

  /// Send any scheduled messages that are past their send time
  static Future<void> _processDueScheduledMessages() async {
    final due = preferences.getDueScheduledMessages();
    if (due.isEmpty) return;

    for (final msg in due) {
      final roomId = msg['roomId'] as String?;
      final clientIdent = msg['clientId'] as String?;
      final message = msg['message'] as String?;

      if (roomId == null || message == null) continue;

      try {
        // Find the matching client and room
        final client = clientManager?.clients.firstWhere(
          (c) => c.identifier == clientIdent,
          orElse: () => clientManager!.clients.first,
        );

        final room = client?.rooms.cast().firstWhere(
              (r) => r.identifier == roomId,
              orElse: () => throw StateError('Room not found'),
            );

        if (room != null) {
          await room.sendMessage(message: message);
          Log.i("Sent scheduled message to $roomId");
        }
      } catch (e) {
        Log.w("Failed to send scheduled message: $e");
      }
    }

    // Remove all due messages from storage
    final all = preferences.getScheduledMessages();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = all.length - 1; i >= 0; i--) {
      if ((all[i]['sendAt'] as int) <= now) {
        await preferences.removeScheduledMessage(i);
      }
    }
  }

  /// Show notifications for any due reminders and clean them up
  static Future<void> _processDueReminders() async {
    final due = preferences.getDueReminders();
    if (due.isEmpty) return;

    for (final reminder in due) {
      final roomId = reminder['room_id'] as String?;
      final eventId = reminder['event_id'] as String?;
      final preview = reminder['preview'] as String? ?? "Reminder";

      if (eventId == null) continue;

      // Show a notification for the reminder
      await NotificationManager.notify(
        NotificationContent(
          title: "Reminder",
          content: preview,
        ),
        forceShow: true,
      );

      // Navigate to the room if possible
      if (roomId != null) {
        EventBus.openRoom.add((roomId, null));
      }

      // Remove the processed reminder
      await preferences.removeReminder(eventId);
      Log.i("Processed reminder for event $eventId");
    }
  }
}
