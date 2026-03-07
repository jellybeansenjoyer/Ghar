import 'package:flutter_test/flutter_test.dart';
import 'package:ghar/models/user.dart';

void main() {
  group('AppUser', () {
    group('fromJson', () {
      test('should create user from complete JSON', () {
        final json = {
          'id': 'user-1',
          'name': 'John Doe',
          'phone': '+1234567890',
          'email': 'john@example.com',
          'avatarUrl': 'https://avatar.com/john.jpg',
          'familyId': 'fam-1',
          'role': 'admin',
          'onesignalPlayerId': 'player-123',
        };

        final user = AppUser.fromJson(json);

        expect(user.id, 'user-1');
        expect(user.name, 'John Doe');
        expect(user.phone, '+1234567890');
        expect(user.email, 'john@example.com');
        expect(user.avatarUrl, 'https://avatar.com/john.jpg');
        expect(user.familyId, 'fam-1');
        expect(user.role, 'admin');
        expect(user.onesignalPlayerId, 'player-123');
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'user-2',
          'name': 'Jane',
        };

        final user = AppUser.fromJson(json);

        expect(user.id, 'user-2');
        expect(user.name, 'Jane');
        expect(user.phone, isNull);
        expect(user.email, isNull);
        expect(user.avatarUrl, isNull);
        expect(user.familyId, isNull);
        expect(user.role, 'member'); // default
      });

      test('should default to empty string for id and name when null', () {
        final json = <String, dynamic>{};

        final user = AppUser.fromJson(json);

        expect(user.id, '');
        expect(user.name, '');
        expect(user.role, 'member');
      });
    });

    group('toJson', () {
      test('should serialize user to JSON', () {
        final user = AppUser(
          id: 'u1',
          name: 'Alice',
          phone: '+111',
          email: 'a@b.com',
          avatarUrl: 'https://img.com/a.png',
          familyId: 'f1',
          role: 'admin',
        );

        final json = user.toJson();

        expect(json['id'], 'u1');
        expect(json['name'], 'Alice');
        expect(json['phone'], '+111');
        expect(json['email'], 'a@b.com');
        expect(json['avatarUrl'], 'https://img.com/a.png');
        expect(json['familyId'], 'f1');
        expect(json['role'], 'admin');
      });
    });

    group('computed properties', () {
      test('isAdmin returns true for admin role', () {
        final admin = AppUser(id: '1', name: 'A', role: 'admin');
        expect(admin.isAdmin, true);
      });

      test('isAdmin returns false for member role', () {
        final member = AppUser(id: '1', name: 'A', role: 'member');
        expect(member.isAdmin, false);
      });

      test('hasFamily returns true when familyId is set', () {
        final user = AppUser(id: '1', name: 'A', familyId: 'f1');
        expect(user.hasFamily, true);
      });

      test('hasFamily returns false when familyId is null', () {
        final user = AppUser(id: '1', name: 'A');
        expect(user.hasFamily, false);
      });

      test('hasCompletedProfile returns true when name is not empty', () {
        final user = AppUser(id: '1', name: 'John');
        expect(user.hasCompletedProfile, true);
      });

      test('hasCompletedProfile returns false when name is empty', () {
        final user = AppUser(id: '1', name: '');
        expect(user.hasCompletedProfile, false);
      });
    });

    group('copyWith', () {
      test('should create a copy with updated name', () {
        final user = AppUser(id: '1', name: 'Old', role: 'member');
        final copy = user.copyWith(name: 'New');

        expect(copy.id, '1');
        expect(copy.name, 'New');
        expect(copy.role, 'member');
      });

      test('should preserve original values when no changes', () {
        final user = AppUser(
          id: '1',
          name: 'Name',
          phone: '+123',
          familyId: 'f1',
          role: 'admin',
        );
        final copy = user.copyWith();

        expect(copy.id, user.id);
        expect(copy.name, user.name);
        expect(copy.phone, user.phone);
        expect(copy.familyId, user.familyId);
        expect(copy.role, user.role);
      });

      test('should update multiple fields', () {
        final user = AppUser(id: '1', name: 'Old');
        final copy = user.copyWith(
          name: 'New',
          familyId: 'f1',
          role: 'admin',
        );

        expect(copy.name, 'New');
        expect(copy.familyId, 'f1');
        expect(copy.role, 'admin');
      });
    });
  });
}
