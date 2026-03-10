// This file is a workaround for the issue: https://github.com/flutter/flutter/issues/101031

import 'dart:io';
import 'package:commet/main.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'generated/l10n.dart';
import 'matrix/login_test.dart' as login_test;
import 'matrix/key_verification_test.dart' as key_verification_test;
import 'matrix/create_space_test.dart' as create_space_test;
import 'matrix/multi_account_test.dart' as multi_account_test;
import 'matrix/change_space_name_test.dart' as change_space_name_test;

/// Debug log to file — stdout may be captured by test framework
void _debugLog(String msg) {
  final timestamp = DateTime.now().toIso8601String();
  final line = '[$timestamp] $msg\n';
  stderr.writeln(line.trim());
  try {
    File('/tmp/integration-test-debug.log')
        .writeAsStringSync(line, mode: FileMode.append, flush: true);
  } catch (_) {}
}

void main() async {
  _debugLog('runner.dart main() entered');
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  _debugLog('IntegrationTestWidgetsFlutterBinding initialized');
  await T.load(const Locale("en"));
  _debugLog('l10n loaded');
  await preferences.init();
  _debugLog('preferences initialized');

  login_test.main();
  key_verification_test.main();
  create_space_test.main();
  multi_account_test.main();
  change_space_name_test.main();
  _debugLog('all test suites registered');
}
