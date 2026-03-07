import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghar/app.dart';
import 'package:ghar/providers/auth_provider.dart';

/// Auth notifier whose checkAuth never completes,
/// so the splash screen stays visible and no platform channels are hit.
class _TestAuthNotifier extends AuthNotifier {
  @override
  Future<void> checkAuth() => Completer<void>().future;
}

void main() {
  testWidgets('App launches and shows Ghar text', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier()),
        ],
        child: const GharApp(),
      ),
    );
    // The splash screen should show 'Ghar'
    expect(find.text('Ghar'), findsOneWidget);

    // Advance past the 1500ms Future.delayed timer to drain it
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('App renders splash screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier()),
        ],
        child: const GharApp(),
      ),
    );
    // Should show the tagline from splash screen
    expect(find.text('Smart Visitor Notifications'), findsOneWidget);

    // Drain timers
    await tester.pump(const Duration(seconds: 2));
  });
}
