import 'package:flutter_test/flutter_test.dart';
import 'package:ghar/models/visitor.dart';

void main() {
  group('Visitor', () {
    group('fromJson', () {
      test('should create visitor from complete JSON', () {
        final json = {
          'id': 'vis-1',
          'familyId': 'fam-1',
          'name': 'John Visitor',
          'photoUrl': 'https://img.com/john.jpg',
          'status': 'pending',
          'respondedById': 'user-1',
          'respondedBy': {'name': 'Alice'},
          'arrivedAt': '2025-06-15T10:00:00Z',
          'respondedAt': '2025-06-15T10:05:00Z',
        };

        final visitor = Visitor.fromJson(json);

        expect(visitor.id, 'vis-1');
        expect(visitor.familyId, 'fam-1');
        expect(visitor.name, 'John Visitor');
        expect(visitor.photoUrl, 'https://img.com/john.jpg');
        expect(visitor.status, 'pending');
        expect(visitor.respondedById, 'user-1');
        expect(visitor.respondedByName, 'Alice');
        expect(visitor.arrivedAt, DateTime.parse('2025-06-15T10:00:00Z'));
        expect(visitor.respondedAt, DateTime.parse('2025-06-15T10:05:00Z'));
      });

      test('should handle snake_case keys', () {
        final json = {
          'id': 'vis-2',
          'family_id': 'fam-2',
          'name': 'Visitor',
          'photo_url': 'https://img.com/v.jpg',
          'status': 'accepted',
          'responded_by': 'user-2',
          'arrived_at': '2025-06-15T10:00:00Z',
        };

        final visitor = Visitor.fromJson(json);

        expect(visitor.familyId, 'fam-2');
        expect(visitor.photoUrl, 'https://img.com/v.jpg');
        expect(visitor.respondedById, 'user-2');
        expect(visitor.arrivedAt, DateTime.parse('2025-06-15T10:00:00Z'));
      });

      test('should handle respondedByName as string', () {
        final json = {
          'id': 'vis-3',
          'name': 'V',
          'respondedByName': 'Bob',
          'arrivedAt': '2025-01-01T00:00:00Z',
        };

        final visitor = Visitor.fromJson(json);
        expect(visitor.respondedByName, 'Bob');
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'vis-4',
          'name': 'Minimal Visitor',
          'arrivedAt': '2025-01-01T00:00:00Z',
        };

        final visitor = Visitor.fromJson(json);

        expect(visitor.photoUrl, isNull);
        expect(visitor.status, 'pending'); // default
        expect(visitor.respondedById, isNull);
        expect(visitor.respondedAt, isNull);
      });
    });

    group('status helpers', () {
      test('isPending should return true for pending status', () {
        final visitor = Visitor(
          id: '1',
          familyId: 'f',
          name: 'V',
          status: 'pending',
          arrivedAt: DateTime.now(),
        );
        expect(visitor.isPending, true);
        expect(visitor.isAccepted, false);
        expect(visitor.isRejected, false);
        expect(visitor.isExpired, false);
      });

      test('isAccepted should return true for accepted status', () {
        final visitor = Visitor(
          id: '2',
          familyId: 'f',
          name: 'V',
          status: 'accepted',
          arrivedAt: DateTime.now(),
        );
        expect(visitor.isAccepted, true);
        expect(visitor.isPending, false);
      });

      test('isRejected should return true for rejected status', () {
        final visitor = Visitor(
          id: '3',
          familyId: 'f',
          name: 'V',
          status: 'rejected',
          arrivedAt: DateTime.now(),
        );
        expect(visitor.isRejected, true);
      });

      test('isExpired should return true for expired status', () {
        final visitor = Visitor(
          id: '4',
          familyId: 'f',
          name: 'V',
          status: 'expired',
          arrivedAt: DateTime.now(),
        );
        expect(visitor.isExpired, true);
      });
    });
  });
}
