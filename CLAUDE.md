# Commet — Claude Code Configuration

## Project Structure
- **Monorepo**: `commet/` (main client), `tiamat/` (UI design system), `widgets/` (platform widgets)
- **Language**: Dart/Flutter (~113k LOC across 554+ files)
- **Flutter**: v3.41.1 stable
- **Application ID**: `chat.commet.commetapp`
- **Platforms**: Android, Linux, Windows (iOS/macOS/Web planned)

## Build Pipeline
1. Code generation is **required** before any build: `cd commet && dart run scripts/codegen.dart`
2. Build APK: `flutter build apk --dart-define PLATFORM=android`
3. Split APKs: `flutter build apk --split-per-abi --dart-define PLATFORM=android`
4. Release builds use `dart run scripts/build_release.dart` with `--platform`, `--version_tag`, `--git_hash`
5. Android signing: `dart run scripts/setup_android_release.dart --key_password ... --key_b64 ...`

## CI/CD Workflows (`.github/workflows/`)
- `build.yml` — PR/merge gate (debug builds for all platforms)
- `release.yml` — Triggered on GitHub release creation (signed release builds)
- `nightly.yml` — Builds split APKs on every push to main, uploads to rolling `nightly` pre-release
- `static-analysis.yml` — Dart analyzer checks
- `benchmark.yml` / `integration-test.yml` — Performance and integration tests

## CI Notes
- CI runners need aggressive disk cleanup (remove .NET, Haskell, Julia, Chromium, Azure CLI, Docker)
- Java 17 required for Android builds
- Git submodules must be checked out (`submodules: 'true'`)
- Linux dependencies: `ninja-build libgtk-3-dev libmpv-dev mpv ffmpeg`
- `softprops/action-gh-release@v2` used for rolling nightly releases
- APK output paths: `commet/build/app/outputs/flutter-apk/`

## Code Conventions
- Dart naming conventions (lowerCamelCase for variables/methods, UpperCamelCase for classes)
- UI components use tiamat design system (`import 'package:tiamat/tiamat.dart' as tiamat`)
- Matrix SDK: `import 'package:matrix/matrix.dart' as matrix`
- Client abstraction layer: abstract `Client`, `Room`, `Space` classes in `commet/lib/client/`
- Components pattern: features as mixins/components attached to clients/rooms
- Preferences via `commet/lib/config/preferences.dart`
- Intl message localization via `Intl.message()` pattern

## Dart/Flutter Specifics
- Use `.nonNulls` instead of deprecated `.whereNotNull()` (collection package)
- Use `color.withValues(alpha: ...)` instead of deprecated `color.withOpacity(...)`
- Avoid ambiguous imports between tiamat and Flutter (prefix with `tiamat.`)
- `await import(...)` is NOT valid Dart — use static imports
- `setRoomStateWithKey` is on the matrix SDK client, not the room object

## Testing
- Analysis: `cd commet && dart analyze`
- Debug APK: `cd commet && flutter build apk --debug --dart-define PLATFORM=android`
- ADB install: `adb install -r commet/build/app/outputs/flutter-apk/app-debug.apk`
- Integration tests: `cd commet && flutter test integration_test/`

## Roadmap
- Feature tracking in `output/ROADMAP.md`
- 67 features completed, 40 remaining
- Key remaining: iOS/macOS clients, full background sync, web client, collaborative tools
