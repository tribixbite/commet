import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';

class Layout {
  static WebBrowserInfo? browserInfo;
  static bool? _isWebDesktopCache;

  /// Tablet breakpoint: width >= 600 and < 1024
  /// Returns true when the app should use an intermediate layout
  /// (two-pane without side nav, or compact desktop)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Large screen: width >= 1024 (full desktop layout)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Small screen: width < 600 (phone layout)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool get desktop {
    if (preferences.layoutOverride.value == "desktop") {
      return true;
    }

    if (preferences.layoutOverride.value != null &&
        preferences.layoutOverride.value != "desktop") {
      return false;
    }

    if (BuildConfig.DESKTOP) {
      return true;
    }

    if (BuildConfig.MOBILE) {
      return false;
    }

    _isWebDesktopCache = _isWebDesktop();
    return _isWebDesktopCache!;
  }

  static bool get mobile {
    if (preferences.layoutOverride.value == "mobile") {
      return true;
    }

    if (preferences.layoutOverride.value != null &&
        preferences.layoutOverride.value != "mobile") {
      return false;
    }

    if (BuildConfig.MOBILE) {
      return true;
    }

    if (BuildConfig.DESKTOP) {
      return false;
    }

    _isWebDesktopCache = _isWebDesktop();
    return !_isWebDesktopCache!;
  }

  static bool _isWebDesktop() {
    if (_isWebDesktopCache != null) {
      return _isWebDesktopCache!;
    }

    if (browserInfo == null) {
      return true;
    }

    var userAgent = browserInfo!.userAgent ?? "";
    userAgent = userAgent.toLowerCase();

    if (userAgent.contains("android")) {
      return false;
    }

    if (userAgent.contains("iphone")) {
      return false;
    }

    if (userAgent.contains("mobile")) {
      return false;
    }

    if (userAgent.contains("macintosh")) {
      return true;
    }

    if (userAgent.contains("windows")) {
      return true;
    }

    if (userAgent.contains("linux")) {
      return true;
    }

    // assume desktop otherwise
    return true;
  }
}
