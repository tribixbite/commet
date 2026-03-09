import 'dart:convert';
import 'dart:io';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/config/preferences/preference.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/diagnostic/diagnostics.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/pages/developer/benchmarks/timeline_viewer_benchmark.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_toggle.dart';
import 'package:commet/ui/pages/settings/categories/app/double_preference_slider.dart';
import 'package:commet/ui/pages/settings/categories/developer/cumulative_diagnostics_widget.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:commet/utils/background_tasks/mock_tasks.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:http/http.dart' as http;
import 'package:window_manager/window_manager.dart';

class DeveloperSettingsPage extends StatefulWidget {
  const DeveloperSettingsPage({super.key});

  @override
  State<DeveloperSettingsPage> createState() => _DeveloperSettingsPageState();
}

class _DeveloperSettingsPageState extends State<DeveloperSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
      performance(),
      benchmarks(),
      windowSize(),
      notificationTests(),
      rendering(),
      error(),
      if (PlatformUtils.isAndroid) shortcuts(),
      backgroundTasks(),
      dumpDatabases(),
      settingsBackup(),
      apiExplorer(),
      tiamat.Panel(
        header: "Other Settings",
        mode: TileType.surfaceContainerLow,
        child: Column(
          children: [
            if (!BuildConfig.MOBILE)
              BooleanPreferenceToggle(
                preference: preferences.disableTextCursorManagement,
                title: "Disable Text Cursor Management",
                description:
                    "As part of the implementaton for the rich text editor, we sometimes have to make automated changes to the text cursor. This disables that",
              ),
            DoublePreferenceSlider(
              preference: preferences.customOnscreenKeyboardViewOffset,
              title: "Keyboard Offset",
              min: 0.0,
              max: 1000,
              description:
                  "Amount to shift the app view up by when the onscreen keyboard is shown",
            )
          ],
        ),
      )
    ].map<Widget>((e) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: e),
      );
    }).toList());
  }

  Widget performance() {
    // Gather client stats for the dashboard
    final clients = clientManager?.clients ?? [];
    final totalRooms =
        clients.fold<int>(0, (sum, c) => sum + c.rooms.length);
    final totalSpaces =
        clients.fold<int>(0, (sum, c) => sum + c.spaces.length);

    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Performance"),
        initiallyExpanded: false,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
        children: [
          // Client stats overview
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const tiamat.Text.labelEmphasised("Client Stats"),
                const SizedBox(height: 4),
                _statRow("Accounts", "${clients.length}"),
                _statRow("Total Rooms", "$totalRooms"),
                _statRow("Total Spaces", "$totalSpaces"),
                _statRow("Build Mode",
                    BuildConfig.RELEASE ? "Release" : "Debug"),
              ],
            ),
          ),
          ...([
            Diagnostics.general,
            Diagnostics.initialLoadDatabaseDiagnostics,
            Diagnostics.postLoadDatabaseDiagnostics,
          ].map((e) => CumulativeDiagnosticsWidget(diagnostics: e)).toList()),
        ]);
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          tiamat.Text.labelLow(label),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget rendering() {
    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Rendering"),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const tiamat.Text.label("Show repaints"),
                  tiamat.Switch(
                    state: debugRepaintRainbowEnabled,
                    onChanged: (value) {
                      setState(() {
                        debugRepaintRainbowEnabled = value;
                      });
                    },
                  ),
                ],
              )
            ]),
          )
        ]);
  }

  Widget benchmarks() {
    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Benchmarks"),
        initiallyExpanded: false,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tiamat.Button(
                text: "Timeline Viewer",
                onTap: () => NavigationUtils.navigateTo(
                    context, const BenchmarkTimelineViewer()),
              )
            ],
          ),
        ]);
  }

  Widget windowSize() {
    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Window Size"),
        initiallyExpanded: false,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tiamat.Button(
                text: "1280x720",
                onTap: () => windowManager.setSize(const Size(1280, 720)),
              ),
              tiamat.Button(
                text: "1280x800 (Steamdeck)",
                onTap: () => windowManager.setSize(const Size(1280, 800)),
              ),
              tiamat.Button(
                text: "1920x1080",
                onTap: () => windowManager.setSize(const Size(1920, 1080)),
              ),
              tiamat.Button(
                text: "2560x1440",
                onTap: () => windowManager.setSize(const Size(2560, 1440)),
              ),
              tiamat.Button(
                text: "3840x2160",
                onTap: () => windowManager.setSize(const Size(3840, 2160)),
              ),
              tiamat.Button(
                text: "1170x2532 (iPhone 12 Pro)",
                onTap: () => windowManager.setSize(const Size(1170, 2532)),
              ),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tiamat.Button(
                text: "1:1",
                onTap: () => setAspectRatio(1),
              ),
              tiamat.Button(
                text: "16:9",
                onTap: () => setAspectRatio(16 / 9),
              ),
            ],
          )
        ]);
  }

  void setAspectRatio(double ratio) async {
    var size = await windowManager.getSize();
    var newWidth = size.height * ratio;
    await windowManager.setSize(Size(newWidth, size.height));
  }

  Widget notificationTests() {
    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Notifications"),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            tiamat.Button(
              text: "Message Notification",
              onTap: () async {
                var client = clientManager!.clients.first;
                var room = client.rooms.first;
                var user = client.self!;
                NotificationManager.notify(MessageNotificationContent(
                  senderName: user.displayName,
                  senderImage: user.avatar,
                  senderId: user.identifier,
                  roomName: room.displayName,
                  roomId: room.identifier,
                  roomImage: await room.getShortcutImage(),
                  content: "Test Message!",
                  clientId: client.identifier,
                  eventId: "fake_event_id",
                  isDirectMessage: true,
                ));
              },
            ),
            tiamat.Button(
              text: "Call Notification",
              onTap: () async {
                if (!BuildConfig.ANDROID) {
                  clientManager?.callManager.startRingtone();
                }

                var client = clientManager!.clients.first;
                var room = client.rooms.first;
                var user = client.self!;
                NotificationManager.notify(CallNotificationContent(
                  title: "Incoming Call!",
                  senderImage: user.avatar,
                  senderId: user.identifier,
                  roomName: room.displayName,
                  roomId: room.identifier,
                  senderName: user.displayName,
                  senderImageId: "fake_call_avatar_id",
                  roomImage: await room.getShortcutImage(),
                  content: "Test Call Notification",
                  clientId: client.identifier,
                  callId: "fake_call_id",
                  isDirectMessage: true,
                ));
              },
            ),
          ])
        ]);
  }

  Widget shortcuts() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Shortcuts"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
            text: "Clear Shortcuts",
            onTap: () async {
              await shortcutsManager.clearAllShortcuts();
            },
          ),
        ])
      ],
    );
  }

  Widget backgroundTasks() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Background Tasks"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
              text: "With progress",
              onTap: () => backgroundTaskManager
                  .addTask(FakeBackgroundTaskWithProgress())),
          tiamat.Button(
              text: "Indeterminate",
              onTap: () => backgroundTaskManager.addTask(FakeBackgroundTask())),
          tiamat.Button(
              text: "Async task with crash",
              onTap: () => backgroundTaskManager.addTask(AsyncTask(() async {
                    await Future.delayed(const Duration(seconds: 5));
                    throw Exception("This background task failed!");
                  }, "Async task"))),
        ])
      ],
    );
  }

  Widget error() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Error"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
              text: "Throw an error",
              onTap: () {
                // This should also throw an error!
                String? empty;
                empty!.split(" ");
              }),
        ])
      ],
    );
  }

  Widget dumpDatabases() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Dump Databases"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
              text: "Dump Databases",
              onTap: () async {
                var folder = await FilePicker.platform.getDirectoryPath();
                var dbDir = Directory(await AppConfig.getDatabasePath());

                var files = await dbDir
                    .list(recursive: true)
                    .where((event) => event is File)
                    .toList();

                for (var file in files) {
                  var name = p.basename(file.path);
                  var dirname = p.basename(p.dirname(file.path));

                  var newFolder = Directory(p.join(folder!, dirname));
                  if (!await newFolder.exists()) {
                    await newFolder.create(recursive: true);
                  }

                  var newFile = p.join(folder, dirname, name);
                  (file as File).copy(newFile);
                }
              }),
        ])
      ],
    );
  }

  /// Settings backup/restore: export all SharedPreferences as JSON, import from file
  Widget settingsBackup() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Settings Backup"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Text.labelLow(
            "Export or import all app preferences as a JSON file.",
          ),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
            text: "Export Settings",
            onTap: () async {
              // Access the SharedPreferences instance via the Preference static
              final sp = Preference.preferences;
              if (sp == null) return;

              final keys = sp.getKeys();
              final Map<String, dynamic> data = {};
              for (final key in keys) {
                data[key] = sp.get(key);
              }

              final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
              final path = await FilePicker.platform.saveFile(
                dialogTitle: "Export Settings",
                fileName: "commet_settings.json",
              );
              if (path != null) {
                await File(path).writeAsString(jsonStr);
              }
            },
          ),
          tiamat.Button(
            text: "Import Settings",
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
              );
              if (result == null || result.files.isEmpty) return;

              final file = File(result.files.single.path!);
              final jsonStr = await file.readAsString();
              final Map<String, dynamic> data = jsonDecode(jsonStr);

              final sp = Preference.preferences;
              if (sp == null) return;

              for (final entry in data.entries) {
                final key = entry.key;
                final value = entry.value;
                if (value is String) {
                  await sp.setString(key, value);
                } else if (value is int) {
                  await sp.setInt(key, value);
                } else if (value is double) {
                  await sp.setDouble(key, value);
                } else if (value is bool) {
                  await sp.setBool(key, value);
                } else if (value is List) {
                  await sp.setStringList(
                      key, value.cast<String>());
                }
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Settings imported. Restart app to apply.")),
                );
              }
            },
          ),
        ]),
      ],
    );
  }

  /// Basic Matrix CS API explorer for developer use
  Widget apiExplorer() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("API Explorer"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _ApiExplorerContent(),
        ),
      ],
    );
  }
}

/// Stateful widget for the API explorer form
class _ApiExplorerContent extends StatefulWidget {
  @override
  State<_ApiExplorerContent> createState() => _ApiExplorerContentState();
}

class _ApiExplorerContentState extends State<_ApiExplorerContent> {
  final _endpointController = TextEditingController(
      text: "/_matrix/client/v3/account/whoami");
  String _method = "GET";
  String _result = "";
  bool _loading = false;

  /// Common Matrix CS API endpoints for quick selection
  static const _quickEndpoints = [
    ("whoami", "/_matrix/client/v3/account/whoami"),
    ("versions", "/_matrix/client/versions"),
    ("capabilities", "/_matrix/client/v3/capabilities"),
    ("joined rooms", "/_matrix/client/v3/joined_rooms"),
    ("profile", "/_matrix/client/v3/profile/{userId}"),
    ("server info", "/_matrix/federation/v1/version"),
  ];

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick endpoint buttons
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: _quickEndpoints.map((e) {
            return ActionChip(
              label: Text(e.$1, style: const TextStyle(fontSize: 11)),
              onPressed: () {
                var endpoint = e.$2;
                // Replace {userId} with actual user ID
                final client = clientManager?.clients.firstOrNull;
                if (client != null) {
                  endpoint = endpoint.replaceAll(
                      '{userId}', client.self?.identifier ?? '');
                }
                _endpointController.text = endpoint;
                setState(() {});
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Endpoint input
        TextField(
          controller: _endpointController,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: "Endpoint",
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "GET", label: Text("GET")),
                ButtonSegment(value: "POST", label: Text("POST")),
              ],
              selected: {_method},
              onSelectionChanged: (s) =>
                  setState(() => _method = s.first),
            ),
            const SizedBox(width: 8),
            tiamat.Button(
              text: _loading ? "Loading..." : "Send",
              onTap: _loading ? null : _sendRequest,
            ),
          ],
        ),
        if (_result.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _result,
                style: const TextStyle(
                    fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _sendRequest() async {
    final client = clientManager?.clients.firstOrNull;
    if (client == null) {
      setState(() => _result = "Error: No client available");
      return;
    }

    setState(() {
      _loading = true;
      _result = "";
    });

    try {
      final endpoint = _endpointController.text.trim();
      // Access the Matrix SDK client to get homeserver and token
      final dynamic matrixClient = (client as dynamic).matrixClient;
      final homeserver = matrixClient.homeserver as Uri;
      final token = matrixClient.accessToken as String?;

      final uri = homeserver.replace(path: endpoint);
      final headers = <String, String>{
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final http.Response response;
      if (_method == "GET") {
        response = await http.get(uri, headers: headers);
      } else {
        response = await http.post(uri, headers: headers);
      }

      // Pretty-print JSON if possible
      try {
        final decoded = const JsonDecoder().convert(response.body);
        _result =
            const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        _result = response.body;
      }
    } catch (e) {
      _result = "Error: $e";
    }

    setState(() => _loading = false);
  }
}

