import { generateOtp, storeOtp, verifyOtp } from '../../src/utils/otp';

describe('OTP Utils', () => {
  describe('generateOtp', () => {
    it('should generate a 6-digit string', () => {
      const otp = generateOtp();
      expect(otp).toHaveLength(6);
      expect(/^\d{6}$/.test(otp)).toBe(true);
    });

    it('should generate different OTPs on each call', () => {
      const otps = new Set(Array.from({ length: 20 }, () => generateOtp()));
      // With 20 generations, we should get mostly unique ones
      expect(otps.size).toBeGreaterThan(1);
    });

    it('should generate OTPs in range 100000 to 999999', () => {
      for (let i = 0; i < 50; i++) {
        const otp = parseInt(generateOtp());
        expect(otp).toBeGreaterThanOrEqual(100000);
        expect(otp).toBeLessThanOrEqual(999999);
      }
    });
  });

  describe('storeOtp & verifyOtp', () => {
    const testPhone = '+1999888777';

    it('should verify a valid OTP', () => {
      const otp = '123456';
      storeOtp(testPhone, otp);
      const result = verifyOtp(testPhone, otp);
      expect(result).toEqual({ valid: true });
    });

    it('should reject when no OTP is stored', () => {
      const result = verifyOtp('+1000000000', '123456');
      expect(result.valid).toBe(false);
      expect(result.reason).toContain('No OTP found');
    });

    it('should reject an incorrect OTP and increment attempts', () => {
      const otp = '123456';
      storeOtp('+1111111111', otp);

      const result = verifyOtp('+1111111111', '654321');
      expect(result.valid).toBe(false);
      expect(result.reason).toContain('Invalid OTP');
    });

    it('should reject after 3 failed attempts', () => {
      const phone = '+1222222222';
      storeOtp(phone, '123456');

      verifyOtp(phone, '000001');
      verifyOtp(phone, '000002');
      verifyOtp(phone, '000003');

      const result = verifyOtp(phone, '123456'); // correct OTP but too late
      expect(result.valid).toBe(false);
      expect(result.reason).toContain('Too many attempts');
    });

    it('should delete OTP after successful verification', () => {
      const phone = '+1333333333';
      storeOtp(phone, '111111');
      verifyOtp(phone, '111111'); // should succeed and delete

      const result = verifyOtp(phone, '111111');
      expect(result.valid).toBe(false);
      expect(result.reason).toContain('No OTP found');
    });

    it('should reject an expired OTP', () => {
      const phone = '+1444444444';
      storeOtp(phone, '222222');

      // Manually expire the OTP by mocking Date.now
      const originalNow = Date.now;
      Date.now = () => originalNow() + 6 * 60 * 1000; // 6 minutes in the future

      const result = verifyOtp(phone, '222222');
      expect(result.valid).toBe(false);
      expect(result.reason).toContain('expired');

      Date.now = originalNow; // restore
    });
  });
});
