import { sendOtpSchema, verifyOtpSchema, googleAuthSchema, refreshTokenSchema } from '../../src/validators/auth.validator';

describe('Auth Validators', () => {
  describe('sendOtpSchema', () => {
    it('should accept a valid E.164 phone number', () => {
      expect(() => sendOtpSchema.parse({ phone: '+1234567890' })).not.toThrow();
    });

    it('should accept a phone without + prefix', () => {
      expect(() => sendOtpSchema.parse({ phone: '1234567890' })).not.toThrow();
    });

    it('should reject a short phone number', () => {
      expect(() => sendOtpSchema.parse({ phone: '12345' })).toThrow();
    });

    it('should reject a phone number that is too long', () => {
      expect(() => sendOtpSchema.parse({ phone: '+12345678901234567' })).toThrow();
    });

    it('should reject missing phone', () => {
      expect(() => sendOtpSchema.parse({})).toThrow();
    });

    it('should reject empty phone', () => {
      expect(() => sendOtpSchema.parse({ phone: '' })).toThrow();
    });

    it('should reject phone with letters', () => {
      expect(() => sendOtpSchema.parse({ phone: '+1234abcdef' })).toThrow();
    });
  });

  describe('verifyOtpSchema', () => {
    it('should accept valid phone and 6-digit OTP', () => {
      expect(() => verifyOtpSchema.parse({ phone: '+1234567890', otp: '123456' })).not.toThrow();
    });

    it('should reject OTP shorter than 6 digits', () => {
      expect(() => verifyOtpSchema.parse({ phone: '+1234567890', otp: '12345' })).toThrow();
    });

    it('should reject OTP longer than 6 digits', () => {
      expect(() => verifyOtpSchema.parse({ phone: '+1234567890', otp: '1234567' })).toThrow();
    });

    it('should reject non-numeric OTP', () => {
      expect(() => verifyOtpSchema.parse({ phone: '+1234567890', otp: 'abcdef' })).toThrow();
    });

    it('should reject missing fields', () => {
      expect(() => verifyOtpSchema.parse({})).toThrow();
      expect(() => verifyOtpSchema.parse({ phone: '+1234567890' })).toThrow();
      expect(() => verifyOtpSchema.parse({ otp: '123456' })).toThrow();
    });
  });

  describe('googleAuthSchema', () => {
    it('should accept a valid idToken', () => {
      expect(() => googleAuthSchema.parse({ idToken: 'valid-google-id-token' })).not.toThrow();
    });

    it('should reject empty idToken', () => {
      expect(() => googleAuthSchema.parse({ idToken: '' })).toThrow();
    });

    it('should reject missing idToken', () => {
      expect(() => googleAuthSchema.parse({})).toThrow();
    });
  });

  describe('refreshTokenSchema', () => {
    it('should accept a valid refreshToken', () => {
      expect(() => refreshTokenSchema.parse({ refreshToken: 'some-refresh-token' })).not.toThrow();
    });

    it('should reject empty refreshToken', () => {
      expect(() => refreshTokenSchema.parse({ refreshToken: '' })).toThrow();
    });

    it('should reject missing refreshToken', () => {
      expect(() => refreshTokenSchema.parse({})).toThrow();
    });
  });
});
