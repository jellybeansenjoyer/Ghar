import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghar/screens/home/home_screen.dart';
import 'package:ghar/providers/auth_provider.dart';
import 'package:ghar/providers/family_provider.dart' as fp;
import 'package:ghar/providers/visitor_provider.dart' as vp;
import 'package:ghar/models/user.dart';

void main() {
  group('HomeScreen', () {
    Widget createHomeScreen() {
      // User without familyId prevents _loadData and _setupRealtime
      // from making network/socket calls in initState.
      final testUser = AppUser(
        id: 'u1',
        name: 'Test User',
        role: 'admin',
      );

      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) {
            final n = AuthNotifier();
            n.updateUser(testUser);
            return n;
          }),
          fp.familyProvider.overrideWith((ref) => fp.FamilyNotifier()),
          vp.visitorProvider.overrideWith((ref) => vp.VisitorNotifier()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('should display app bar with Ghar', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.text('Ghar'), findsOneWidget);
    });

    testWidgets('should display welcome message', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.textContaining('Hello'), findsOneWidget);
    });

    testWidgets('should display action cards', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.text('QR Code'), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);
      expect(find.text('Visitors'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('should display Recent Visitors section', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.text('Recent Visitors'), findsOneWidget);
    });

    testWidgets('should display no visitors message when empty', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.text('No visitors yet'), findsOneWidget);
    });

    testWidgets('should display profile icon in app bar', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });
  });
}
