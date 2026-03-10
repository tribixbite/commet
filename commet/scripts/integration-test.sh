#!/usr/bin/env bash
# Run integration tests headlessly in the Dart VM (no -d linux).
# This avoids EGL/OpenGL requirements on headless CI runners while
# still supporting real network I/O to the Synapse homeserver.
flutter test integration_test/runner.dart \
  --dart-define=HOMESERVER=$HOMESERVER \
  --dart-define=BUILD_MODE=release \
  --dart-define=USER1_NAME=$USER1_NAME \
  --dart-define=USER1_PW=$USER1_PW \
  --timeout 5x