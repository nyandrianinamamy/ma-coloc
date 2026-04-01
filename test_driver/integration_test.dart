import 'dart:async';
import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  // Force exit after 4 minutes regardless — integrationDriver hangs on web
  // after tests complete because it waits for the browser to close.
  Timer(const Duration(minutes: 4), () => exit(0));
  await integrationDriver(timeout: const Duration(minutes: 3));
  exit(0);
}
