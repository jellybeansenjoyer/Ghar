import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghar/screens/splash/splash_screen.dart';
import 'package:ghar/providers/auth_provider.dart';

/// Auth notifier whose checkAuth never completes,
/// preventing navigation and platform channel access during tests.
class _TestAuthNotifier extends AuthNotifier {
  @override
  Future<void> checkAuth() => Completer<void>().future;
}

void main() {
  group('SplashScreen', () {
    Widget createSplashScreen() {
      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier()),
        ],
        child: const MaterialApp(home: SplashScreen()),
      );
    }

    testWidgets('should display app name', (tester) async {
      await tester.pumpWidget(createSplashScreen());
      expect(find.text('Ghar'), findsOneWidget);
      // Advance past the 1500ms delay timer to drain it
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('should display tagline', (tester) async {
      await tester.pumpWidget(createSplashScreen());
      expect(find.text('Smart Visitor Notifications'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('should display loading indicator', (tester) async {
      await tester.pumpWidget(createSplashScreen());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('should display house emoji', (tester) async {
      await tester.pumpWidget(createSplashScreen());
      expect(find.text('🏠'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
