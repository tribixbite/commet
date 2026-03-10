// Driver for running integration tests via `flutter drive`.
// Unlike `flutter test -d linux`, `flutter drive` has no loading timeout,
// making it more reliable for headless CI environments.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
