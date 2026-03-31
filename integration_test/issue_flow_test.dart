import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macoloc/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Issue lifecycle E2E', () {
    testWidgets('app boots and shows home screen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaColocApp()),
      );
      await tester.pumpAndSettle();

      // In dev mode with placeholder Firebase, should land on /home
      // The bottom nav should be visible
      expect(find.byIcon(Icons.home), findsOneWidget);
    });
  });
}
