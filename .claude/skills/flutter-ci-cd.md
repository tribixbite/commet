# Flutter CI/CD — Nightly APK Builds

## Overview
Skill for setting up and maintaining GitHub Actions CI/CD for Flutter Android projects
with rolling nightly releases of split APKs.

## Key Patterns

### Split APK Builds
```bash
flutter build apk --split-per-abi --release \
  --dart-define PLATFORM=android \
  --dart-define BUILD_MODE=release \
  --dart-define GIT_HASH=$GITHUB_SHA \
  --dart-define VERSION_TAG=nightly
```
Produces three APKs in `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` — 64-bit ARM (most modern phones)
- `app-armeabi-v7a-release.apk` — 32-bit ARM (older devices)
- `app-x86_64-release.apk` — x86 emulators, ChromeOS

### Rolling Nightly Release
Use `softprops/action-gh-release@v2` with:
- `tag_name: nightly` — reuses the same tag
- `prerelease: true` — marks as pre-release so it doesn't override latest stable
- `make_latest: false` — prevents nightly from becoming "Latest" release
- `files:` — list of APK paths; existing assets are replaced on each run

### Disk Space on CI Runners
Flutter + Android SDK + Gradle eat ~15GB. Runners only have ~14GB free by default.
Must aggressively clean before build:
```yaml
- name: Aggressive cleanup
  run: |
    sudo rm -rf /usr/share/dotnet /usr/local/.ghcup /usr/local/julia*
    sudo rm -rf /usr/local/share/chromium /opt/microsoft /opt/google
    sudo rm -rf /opt/az /opt/hostedtoolcache
    docker system prune -af || true
```

### Code Generation Requirement
Commet uses procedural codegen that must run before any build:
```bash
cd commet && dart run scripts/codegen.dart
```

### Signing (Release Builds Only)
```bash
dart run scripts/setup_android_release.dart \
  --key_password $ANDROID_KEY_PASSWORD \
  --key_b64 $ANDROID_KEY_STORE_B64
```
Nightly builds skip signing (use debug key) since they're pre-release.

## Verification Checklist
1. `gh run list --workflow=nightly` — confirm workflow triggered
2. `gh run watch` — watch for completion
3. `gh release view nightly` — confirm APKs are attached
4. README badge links to `../../releases/tag/nightly`
