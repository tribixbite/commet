import 'package:commet/client/components/push_notification/android/unified_push_notifier.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_toggle.dart';
import 'package:commet/ui/pages/settings/categories/app/notification_settings/notifier_debug_view.dart';
import 'package:commet/ui/pages/setup/menus/unified_push_setup.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  Notifier? notifier;
  GlobalKey pushGatewayKey = GlobalKey();
  bool isPushGatewayLoading = false;

  String get notificationSettingsNotSupported =>
      Intl.message("Push notifications are not supported on this system",
          name: "notificationSettingsNotSupported",
          desc: "Message to display when push notifications are not supported");

  @override
  void initState() {
    super.initState();
    notifier = NotificationManager.notifier;
  }

  bool get canConfigureNotifications =>
      PlatformUtils.isAndroid || PlatformUtils.isLinux;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (canConfigureNotifications)
          Column(
            children: [
              Panel(
                mode: tiamat.TileType.surfaceContainerLow,
                header: "Push Notifications",
                child: buildNotificationSettings(),
              ),
              if (notifier is UnifiedPushNotifier)
                Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Panel(
                        mode: tiamat.TileType.surfaceContainerLow,
                        header: "Unified Push",
                        child: Column(
                          children: [
                            UnifiedPushSetupView(
                              onToggled: (_) => setState(() {}),
                            ),
                            if (preferences.unifiedPushEnabled.value == true)
                              pushGatewaySelector(),
                          ],
                        )),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
            ],
          ),
        const SizedBox(height: 10),
        Panel(
          mode: tiamat.TileType.surfaceContainerLow,
          header: "Notification Sound",
          child: notificationSoundSection(),
        ),
        const SizedBox(height: 10),
        Panel(
          mode: tiamat.TileType.surfaceContainerLow,
          header: "Keyword Alerts",
          child: keywordAlertsSection(),
        ),
        const SizedBox(height: 10),
        Panel(
          mode: tiamat.TileType.surfaceContainerLow,
          header: "Auto-Responder",
          child: autoResponderSection(),
        ),
        if (preferences.developerMode.value)
          const Panel(
            mode: tiamat.TileType.surfaceContainerLow,
            header: "Registered Pushers",
            child: NotifierDebugView(),
          ),
      ],
    );
  }

  /// Notification sound preference section
  Widget notificationSoundSection() {
    final currentSound =
        preferences.notificationSound.value ?? "default";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Text.labelLow(
            "Choose the notification sound for incoming messages.",
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _soundChip("Default", "default", currentSound),
              _soundChip("Gentle", "gentle", currentSound),
              _soundChip("Chime", "chime", currentSound),
              _soundChip("Pop", "pop", currentSound),
              _soundChip("Silent", "silent", currentSound),
            ],
          ),
        ),
      ],
    );
  }

  Widget _soundChip(String label, String value, String current) {
    final isSelected = current == value;
    return ChoiceChip(
      label: tiamat.Text.label(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          preferences.notificationSound.set(value);
        });
      },
    );
  }

  Widget keywordAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Text.labelLow(
            "Get notified when messages contain specific words. Separate multiple keywords with commas.",
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _keywordController,
            decoration: const InputDecoration(
              hintText: "e.g. urgent, deploy, @team",
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              preferences.notificationKeywords.set(value);
            },
          ),
        ),
      ],
    );
  }

  late final TextEditingController _keywordController = TextEditingController(
    text: preferences.notificationKeywords.value,
  );

  Widget buildNotificationSettings() {
    return Column(
      children: [
        if (PlatformUtils.isAndroid)
          BooleanPreferenceToggle(
            preference: preferences.silenceNotifications,
            title: "Silence Notifications",
            description:
                "When another device or client is active, silence notifications on this device",
          ),
        if (PlatformUtils.isLinux)
          Column(
            children: [
              BooleanPreferenceToggle(
                preference: preferences.formatNotificationBody,
                title: "Message Body Formatting",
                description: "Apply user formatting in message notifications",
              ),
              AnimatedOpacity(
                opacity: preferences.formatNotificationBody.value ? 1 : 0.3,
                duration: Durations.short4,
                child: IgnorePointer(
                  ignoring: preferences.formatNotificationBody.value == false,
                  child: Column(
                    children: [
                      BooleanPreferenceToggle(
                        preference: preferences.showMediaInNotifications,
                        title: "Show Images",
                        description:
                            "Show images in notifications, if allowed by 'General > Media Preview' settings",
                      ),
                      BooleanPreferenceToggle(
                        preference: preferences.previewUrlInNotifications,
                        title: "Preview Urls",
                        description:
                            "Fetch URL previews to show extra information about links in notifications",
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
      ],
    );
  }

  Widget pushGatewaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        tiamat.DropdownTextField(
            key: pushGatewayKey,
            initialValue: preferences.pushGateway,
            textEditorPlaceholder: "push.example.com",
            editableEntryPlaceholder: "Custom push gateway",
            items: [
              "push.commet.chat",
              if (notifier is UnifiedPushNotifier)
                "matrix.gateway.unifiedpush.org"
            ]),
        tiamat.Button(
          text: CommonStrings.promptApply,
          isLoading: isPushGatewayLoading,
          onTap: onPushGatewaySelected,
        )
      ],
    );
  }

  late final TextEditingController _autoResponderController =
      TextEditingController(
    text: preferences.autoResponderMessage.value,
  );

  /// Auto-responder settings: enable/disable and configure away message
  Widget autoResponderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BooleanPreferenceToggle(
          preference: preferences.autoResponderEnabled,
          title: "Enable Auto-Responder",
          description:
              "Automatically reply to direct messages when you are away",
          onChanged: (_) => setState(() {}),
        ),
        AnimatedOpacity(
          opacity: preferences.autoResponderEnabled.value ? 1 : 0.3,
          duration: Durations.short4,
          child: IgnorePointer(
            ignoring: !preferences.autoResponderEnabled.value,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _autoResponderController,
                decoration: const InputDecoration(
                  hintText: "Your away message...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                minLines: 1,
                onChanged: (value) {
                  preferences.autoResponderMessage.set(value);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> onPushGatewaySelected() async {
    var value = (pushGatewayKey.currentState as DropdownTextFieldState).value;
    preferences.setPushGateway(value);

    setState(() {
      isPushGatewayLoading = true;
    });

    await PushNotificationComponent.updateAllPushers();

    setState(() {
      isPushGatewayLoading = false;
    });
  }
}
