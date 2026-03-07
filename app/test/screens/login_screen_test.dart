import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghar/screens/auth/login_screen.dart';
import 'package:ghar/providers/auth_provider.dart';

/// Auth notifier with no-op async methods to avoid
/// network calls and platform channel access in tests.
class _TestAuthNotifier extends AuthNotifier {
  @override
  Future<void> checkAuth() async {}

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<bool> signInWithGoogle() async => false;
}

void main() {
  group('LoginScreen', () {
    Widget createLoginScreen() {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, __) => const LoginScreen(),
          ),
          GoRoute(
            path: '/otp-verify',
            builder: (_, __) => const Scaffold(body: Text('OTP Verify')),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/family-setup',
            builder: (_, __) => const Scaffold(body: Text('Family Setup')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier()),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('should display welcome text', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.text('Welcome to Ghar'), findsOneWidget);
      expect(find.text('Get notified when visitors arrive'), findsOneWidget);
    });

    testWidgets('should display phone number input', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should display Send OTP button', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.text('Send OTP'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should display Google sign-in button', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('should display OR divider', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('should show validation error for empty phone', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      // Tap send OTP without entering phone
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your phone number'), findsOneWidget);
    });

    testWidgets('should show validation error for short phone', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      // Enter short phone number
      await tester.enterText(find.byType(TextFormField), '12345');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid phone number'), findsOneWidget);
    });

    testWidgets('should not show validation error for valid phone', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      // Enter valid phone number
      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      // No validation errors should appear for valid input
      expect(find.text('Please enter your phone number'), findsNothing);
      expect(find.text('Please enter a valid phone number'), findsNothing);
    });

    testWidgets('should display house emoji', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      // Check the emoji exists in the UI
      expect(find.text('🏠'), findsOneWidget);
    });
  });
}
