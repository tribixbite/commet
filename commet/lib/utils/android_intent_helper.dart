import 'package:commet/utils/custom_uri.dart';
import 'package:receive_intent/receive_intent.dart';

class AndroidIntentHelper {
  static CustomURI? getUriFromIntent(Intent? intent) {
    var key = "flutter_shortcuts_new";

    if (intent?.action == "SELECT_NOTIFICATION") {
      key = "payload";
    }

    if (intent?.extra?.containsKey(key) == true) {
      var uri = CustomURI.parse(intent!.extra![key]);
      return uri;
    }

    return null;
  }

  /// Extracts shared text from an ACTION_SEND intent
  static String? getSharedText(Intent? intent) {
    if (intent?.action != "android.intent.action.SEND") return null;
    // EXTRA_TEXT is the standard key for shared text
    return intent?.extra?["android.intent.extra.TEXT"] as String?;
  }

  /// Extracts shared file URI from an ACTION_SEND intent
  static String? getSharedFileUri(Intent? intent) {
    if (intent?.action != "android.intent.action.SEND") return null;
    return intent?.extra?["android.intent.extra.STREAM"] as String?;
  }

  /// Returns true if the intent is a share action
  static bool isShareIntent(Intent? intent) {
    return intent?.action == "android.intent.action.SEND" ||
        intent?.action == "android.intent.action.SEND_MULTIPLE";
  }
}
