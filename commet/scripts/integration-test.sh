#!/usr/bin/env bash
# Run integration tests on the Linux desktop device.
# Uses `flutter drive` instead of `flutter test` to avoid the hardcoded
# 12-minute loading timeout in the test framework.
# xvfb-run provides a virtual X display with GLX/EGL support.
# FLUTTER_LINUX_RENDERER=software bypasses EGL for headless CI.
xvfb-run -a -s "-screen 0 1920x1080x24" \
  flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/runner.dart \
  -d linux \
  --no-dds \
  --dart-define=HOMESERVER=$HOMESERVER \
  --dart-define=BUILD_MODE=release \
  --dart-define=USER1_NAME=$USER1_NAME \
  --dart-define=USER1_PW=$USER1_PW
