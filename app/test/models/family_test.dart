import 'package:flutter_test/flutter_test.dart';
import 'package:ghar/models/family.dart';

void main() {
  group('Family', () {
    group('fromJson', () {
      test('should create family from complete JSON', () {
        final json = {
          'id': 'fam-1',
          'name': 'Doe Family',
          'address': '123 Main St',
          'adminId': 'admin-1',
          'qrCodeData': 'http://localhost:3000/visit/fam-1',
          'createdAt': '2025-01-15T10:00:00Z',
        };

        final family = Family.fromJson(json);

        expect(family.id, 'fam-1');
        expect(family.name, 'Doe Family');
        expect(family.address, '123 Main St');
        expect(family.adminId, 'admin-1');
        expect(family.qrCodeData, 'http://localhost:3000/visit/fam-1');
        expect(family.createdAt, DateTime.parse('2025-01-15T10:00:00Z'));
      });

      test('should handle snake_case keys', () {
        final json = {
          'id': 'fam-2',
          'name': 'Smith Family',
          'admin_id': 'admin-2',
          'qr_code_data': 'http://localhost:3000/visit/fam-2',
        };

        final family = Family.fromJson(json);

        expect(family.adminId, 'admin-2');
        expect(family.qrCodeData, 'http://localhost:3000/visit/fam-2');
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'fam-3',
          'name': 'Minimal Family',
          'adminId': 'admin-3',
        };

        final family = Family.fromJson(json);

        expect(family.address, isNull);
        expect(family.qrCodeData, isNull);
        expect(family.createdAt, isNotNull); // defaults to DateTime.now()
      });

      test('should default to empty string when id/name/adminId are null', () {
        final json = <String, dynamic>{};

        final family = Family.fromJson(json);

        expect(family.id, '');
        expect(family.name, '');
        expect(family.adminId, '');
      });
    });

    group('toJson', () {
      test('should serialize family to JSON', () {
        final family = Family(
          id: 'f1',
          name: 'Test Family',
          address: 'Test Address',
          adminId: 'a1',
          qrCodeData: 'http://test.com/visit/f1',
          createdAt: DateTime(2025, 1, 1),
        );

        final json = family.toJson();

        expect(json['id'], 'f1');
        expect(json['name'], 'Test Family');
        expect(json['address'], 'Test Address');
        expect(json['adminId'], 'a1');
        expect(json['qrCodeData'], 'http://test.com/visit/f1');
      });
    });
  });
}
