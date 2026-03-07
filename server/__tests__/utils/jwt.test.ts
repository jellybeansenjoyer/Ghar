import { signAccessToken, signRefreshToken, verifyAccessToken, verifyRefreshToken } from '../../src/utils/jwt';

describe('JWT Utils', () => {
  describe('signAccessToken & verifyAccessToken', () => {
    it('should sign and verify an access token with all fields', () => {
      const payload = { userId: 'user-1', familyId: 'fam-1', role: 'admin' };
      const token = signAccessToken(payload);

      expect(typeof token).toBe('string');
      expect(token.split('.')).toHaveLength(3); // JWT has 3 parts

      const decoded = verifyAccessToken(token);
      expect(decoded.userId).toBe('user-1');
      expect(decoded.familyId).toBe('fam-1');
      expect(decoded.role).toBe('admin');
    });

    it('should sign and verify an access token without optional fields', () => {
      const payload = { userId: 'user-2' };
      const token = signAccessToken(payload);
      const decoded = verifyAccessToken(token);

      expect(decoded.userId).toBe('user-2');
      expect(decoded.familyId).toBeUndefined();
    });

    it('should throw on invalid token', () => {
      expect(() => verifyAccessToken('invalid.token.here')).toThrow();
    });

    it('should throw on token signed with wrong secret', () => {
      const jwt = require('jsonwebtoken');
      const token = jwt.sign({ userId: 'x' }, 'wrong-secret', { expiresIn: '15m' });
      expect(() => verifyAccessToken(token)).toThrow();
    });
  });

  describe('signRefreshToken & verifyRefreshToken', () => {
    it('should sign and verify a refresh token', () => {
      const token = signRefreshToken('user-3');

      expect(typeof token).toBe('string');

      const decoded = verifyRefreshToken(token);
      expect(decoded.userId).toBe('user-3');
    });

    it('should throw on invalid refresh token', () => {
      expect(() => verifyRefreshToken('invalid-token')).toThrow();
    });

    it('should not verify a refresh token with access token secret', () => {
      const accessToken = signAccessToken({ userId: 'x' });
      expect(() => verifyRefreshToken(accessToken)).toThrow();
    });

    it('should not verify an access token with refresh token verifier', () => {
      const refreshToken = signRefreshToken('y');
      expect(() => verifyAccessToken(refreshToken)).toThrow();
    });
  });
});
