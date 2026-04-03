import 'dart:convert';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        final results = data ?? {};
        if (results.isEmpty) {
          print('⚠ No test results received');
          return;
        }

        print('');
        print('═══════════════════════════════════════════════════');
        print('  E2E Test Results (${results.length} tests)');
        print('═══════════════════════════════════════════════════');

        int passed = 0;
        int failed = 0;
        final failures = <String, String>{};

        for (final entry in results.entries) {
          final name = entry.key;
          final result = entry.value;
          if (result == 'success') {
            passed++;
            print('  ✅ $name');
          } else {
            failed++;
            failures[name] = result;
            print('  ❌ $name');
          }
        }

        print('───────────────────────────────────────────────────');
        print('  $passed passed, $failed failed');
        print('═══════════════════════════════════════════════════');

        if (failures.isNotEmpty) {
          print('');
          print('Failure details:');
          for (final entry in failures.entries) {
            print('');
            print('  ❌ ${entry.key}:');
            print('     ${entry.value}');
          }
        }
        print('');
      },
    );
