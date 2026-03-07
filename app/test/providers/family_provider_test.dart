import 'package:flutter_test/flutter_test.dart';
import 'package:ghar/providers/family_provider.dart';
import 'package:ghar/models/family.dart' as models;
import 'package:ghar/models/user.dart';

void main() {
  group('FamilyState', () {
    test('should have default values', () {
      final state = FamilyState();

      expect(state.family, isNull);
      expect(state.members, isEmpty);
      expect(state.qrCodeData, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('should create state with custom values', () {
      final family = models.Family(
        id: 'f1',
        name: 'Test',
        adminId: 'a1',
        createdAt: DateTime(2025, 1, 1),
      );
      final members = [AppUser(id: 'u1', name: 'User 1')];

      final state = FamilyState(
        family: family,
        members: members,
        qrCodeData: 'http://test.com/qr',
        isLoading: false,
        error: null,
      );

      expect(state.family?.id, 'f1');
      expect(state.members.length, 1);
      expect(state.qrCodeData, 'http://test.com/qr');
    });

    test('copyWith should update specified fields', () {
      final family = models.Family(
        id: 'f1',
        name: 'Test',
        adminId: 'a1',
        createdAt: DateTime(2025, 1, 1),
      );
      final state = FamilyState(family: family);

      final updated = state.copyWith(isLoading: true);

      expect(updated.family?.id, 'f1');
      expect(updated.isLoading, true);
    });

    test('copyWith should update members list', () {
      final state = FamilyState();
      final members = [
        AppUser(id: 'u1', name: 'Alice'),
        AppUser(id: 'u2', name: 'Bob'),
      ];

      final updated = state.copyWith(members: members);

      expect(updated.members.length, 2);
      expect(updated.members[0].name, 'Alice');
    });

    test('copyWith should clear error when not provided', () {
      final state = FamilyState(error: 'Some error');
      final updated = state.copyWith(isLoading: false);

      expect(updated.error, isNull);
    });
  });

  group('FamilyNotifier', () {
    late FamilyNotifier notifier;

    setUp(() {
      notifier = FamilyNotifier();
    });

    test('initial state should have no family', () {
      expect(notifier.state.family, isNull);
      expect(notifier.state.members, isEmpty);
    });

    test('clear should reset state', () {
      // We can't easily set state directly, but we can test clear
      notifier.clear();

      expect(notifier.state.family, isNull);
      expect(notifier.state.members, isEmpty);
      expect(notifier.state.qrCodeData, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });
  });
}
