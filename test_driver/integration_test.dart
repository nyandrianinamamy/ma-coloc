import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  await integrationDriver(timeout: const Duration(minutes: 5));
  exit(0);
}
