#!/usr/bin/env bash
# Run integration tests on the Linux desktop device.
# xvfb-run provides a virtual X display with GLX/EGL support.
# FLUTTER_LINUX_RENDERER=software bypasses EGL for headless CI.
# --ignore-timeouts prevents the hardcoded 12-min loading timeout.
xvfb-run -a -s "-screen 0 1920x1080x24" \
  flutter test integration_test/runner.dart -d linux \
  --verbose \
  --ignore-timeouts \
  --dart-define=HOMESERVER=$HOMESERVER \
  --dart-define=BUILD_MODE=release \
  --dart-define=USER1_NAME=$USER1_NAME \
  --dart-define=USER1_PW=$USER1_PW \
  --timeout 5x