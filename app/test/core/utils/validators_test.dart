import 'package:flutter_test/flutter_test.dart';
import 'package:ghar/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('phone', () {
      test('should accept valid phone with country code', () {
        expect(Validators.phone('+1234567890'), isNull);
        expect(Validators.phone('+919876543210'), isNull);
      });

      test('should accept valid phone without country code', () {
        expect(Validators.phone('1234567890'), isNull);
      });

      test('should accept phone with spaces/dashes (cleaned)', () {
        expect(Validators.phone('+1 234-567-890'), isNull);
        expect(Validators.phone('(123) 456-7890'), isNull);
      });

      test('should reject null or empty phone', () {
        expect(Validators.phone(null), isNotNull);
        expect(Validators.phone(''), isNotNull);
        expect(Validators.phone('   '), isNotNull);
      });

      test('should reject short phone number', () {
        expect(Validators.phone('12345'), isNotNull);
      });

      test('should reject phone with letters', () {
        expect(Validators.phone('+12345abcde'), isNotNull);
      });
    });

    group('name', () {
      test('should accept valid names', () {
        expect(Validators.name('John'), isNull);
        expect(Validators.name('John Doe'), isNull);
        expect(Validators.name('AB'), isNull);
      });

      test('should reject null or empty name', () {
        expect(Validators.name(null), isNotNull);
        expect(Validators.name(''), isNotNull);
        expect(Validators.name('   '), isNotNull);
      });

      test('should reject single character name', () {
        expect(Validators.name('A'), isNotNull);
      });

      test('should reject name longer than 100 chars', () {
        expect(Validators.name('A' * 101), isNotNull);
      });
    });

    group('otp', () {
      test('should accept valid 6-digit OTP', () {
        expect(Validators.otp('123456'), isNull);
        expect(Validators.otp('000000'), isNull);
        expect(Validators.otp('999999'), isNull);
      });

      test('should reject null or empty OTP', () {
        expect(Validators.otp(null), isNotNull);
        expect(Validators.otp(''), isNotNull);
      });

      test('should reject OTP with wrong length', () {
        expect(Validators.otp('12345'), isNotNull);
        expect(Validators.otp('1234567'), isNotNull);
      });

      test('should reject non-numeric OTP', () {
        expect(Validators.otp('abcdef'), isNotNull);
        expect(Validators.otp('12345a'), isNotNull);
      });
    });

    group('familyName', () {
      test('should accept valid family names', () {
        expect(Validators.familyName('Doe Family'), isNull);
        expect(Validators.familyName('AB'), isNull);
      });

      test('should reject null or empty family name', () {
        expect(Validators.familyName(null), isNotNull);
        expect(Validators.familyName(''), isNotNull);
      });

      test('should reject single character family name', () {
        expect(Validators.familyName('A'), isNotNull);
      });

      test('should reject family name longer than 50 chars', () {
        expect(Validators.familyName('A' * 51), isNotNull);
      });
    });

    group('address', () {
      test('should accept valid addresses', () {
        expect(Validators.address('123 Main Street'), isNull);
        expect(Validators.address(null), isNull); // optional
      });

      test('should reject address longer than 200 chars', () {
        expect(Validators.address('A' * 201), isNotNull);
      });
    });

    group('message', () {
      test('should accept valid messages', () {
        expect(Validators.message('Hello!'), isNull);
        expect(Validators.message('A'), isNull);
      });

      test('should reject null or empty message', () {
        expect(Validators.message(null), isNotNull);
        expect(Validators.message(''), isNotNull);
      });

      test('should reject whitespace-only message', () {
        expect(Validators.message('   '), isNotNull);
      });

      test('should reject message longer than 500 chars', () {
        expect(Validators.message('A' * 501), isNotNull);
      });
    });
  });
}
