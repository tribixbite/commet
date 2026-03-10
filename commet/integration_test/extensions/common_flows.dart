import 'dart:io';

import 'package:commet/config/app_config.dart';
import 'package:commet/ui/organisms/side_navigation_bar/side_navigation_bar.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import 'wait_for.dart';

extension CommonFlows on WidgetTester {
  String get homeserver =>
      const String.fromEnvironment('HOMESERVER', defaultValue: "localhost");
  String get username =>
      const String.fromEnvironment('USER1_NAME', defaultValue: "alice");
  String get password => const String.fromEnvironment('USER1_PW',
      defaultValue: "AliceInWonderland");

  String get userTwoName =>
      const String.fromEnvironment('USER2_NAME', defaultValue: "bob");
  String get userTwoPassword =>
      const String.fromEnvironment('USER2_PW', defaultValue: "CanWeFixIt");

  Future<void> clearUserData() async {
    var dir = Directory(await AppConfig.getDatabasePath());
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    dir = await getApplicationSupportDirectory();

    if (!await dir.exists()) return;

    var files = await dir.list(recursive: true).toList();
    for (var file in files) {
      try {
        if (!await file.exists()) continue;

        await file.delete();
      } catch (exception) {
        // ignore: avoid_print
        print("Could not delete file: ${file.uri.toString()}");
      }
    }
  }

  Future<void> clean() async {
    await fileCache?.close();
    await preferences.clear();
    await clearUserData();
  }

  Future<App> setupApp() async {
    print('[setupApp] clearUserData');
    await clearUserData();
    print('[setupApp] initNecessary');
    await initNecessary();
    print('[setupApp] initGuiRequirements');
    await initGuiRequirements();
    print('[setupApp] creating App');
    return App(clientManager: clientManager!);
  }

  /// Enters homeserver and waits for server validation to complete,
  /// then enters credentials and taps Login.
  Future<void> login(App app) async {
    print('[login] waiting for LoginPage');
    await waitFor(() => find.byType(LoginPage).evaluate().isNotEmpty);
    print('[login] LoginPage found');

    // Enter homeserver first and wait for debounce + validation
    var hsInput = find.byType(TextField);
    expect(hsInput, findsWidgets);
    print('[login] entering homeserver: $homeserver');
    await enterText(hsInput.first, homeserver);

    // Wait for debounce (1s) + HTTPS attempt + HTTP fallback + response
    // Username/password fields appear only after server validation succeeds
    print('[login] waiting for 3 TextFields (server validation)');
    await waitFor(
      () => find.byType(TextField).evaluate().length >= 3,
      timeout: const Duration(seconds: 10),
    );
    print('[login] 3 TextFields found, entering credentials');

    var inputs = find.byType(TextField);
    await enterText(inputs.at(1), username);
    await pump(const Duration(milliseconds: 500));
    await enterText(inputs.at(2), password);
    await pump(const Duration(milliseconds: 500));

    print('[login] tapping Login button');
    var button = find.widgetWithText(ElevatedButton, "Login");
    await tap(button);

    await pump(const Duration(seconds: 1));

    print('[login] waiting for isLoggedIn');
    await waitFor(() => app.clientManager.isLoggedIn(),
        timeout: const Duration(seconds: 10), skipPumpAndSettle: true);
    print('[login] login complete');
    expect(app.clientManager.isLoggedIn(), equals(true));
  }

  Future<void> loginUser2(App app) async {
    await waitFor(() => find.byType(LoginPage).evaluate().isNotEmpty);

    var hsInput = find.byType(TextField);
    expect(hsInput, findsWidgets);
    await enterText(hsInput.first, homeserver);

    await waitFor(
      () => find.byType(TextField).evaluate().length >= 3,
      timeout: const Duration(seconds: 10),
    );

    var inputs = find.byType(TextField);
    await enterText(inputs.at(1), userTwoName);
    await pump(const Duration(milliseconds: 500));
    await enterText(inputs.at(2), userTwoPassword);
    await pump(const Duration(milliseconds: 500));

    var button = find.widgetWithText(ElevatedButton, "Login");
    await tap(button);

    await pump(const Duration(seconds: 1));

    await waitFor(() => app.clientManager.isLoggedIn(),
        timeout: const Duration(seconds: 10), skipPumpAndSettle: true);
    expect(app.clientManager.isLoggedIn(), equals(true));
  }

  Future<Client> createTestClient() async {
    throw UnimplementedError();
    // var otherClient = Client(
    //   "Commet Integration Tester",
    //   verificationMethods: {
    //     KeyVerificationMethod.emoji,
    //     KeyVerificationMethod.numbers
    //   },
    //   nativeImplementations: MatrixClient.nativeImplementations,
    //   logLevel: Level.verbose,
    //   databaseBuilder: (client) async {
    //     final db = HiveCollectionsDatabase(
    //         client.clientName, await AppConfig.getDatabasePath());
    //     await db.open();
    //     return db;
    //   },
    // );

    // await otherClient.checkHomeserver(Uri.http(homeserver));

    // await otherClient.login(LoginType.mLoginPassword,
    //     identifier: AuthenticationUserIdentifier(user: username),
    //     password: password);

    // return otherClient;
  }

  Future<void> openSettings(App app) async {
    await dragUntilVisible(find.byKey(SideNavigationBar.settingsKey),
        find.byType(SideNavigationBar), const Offset(0, 20));

    await tap(find.byKey(SideNavigationBar.settingsKey));

    await pump(const Duration(milliseconds: 500));
  }
}
