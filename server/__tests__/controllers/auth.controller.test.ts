import request from 'supertest';
import mockPrisma from '../mocks/prisma';
import { createTestUser, generateTestTokens } from '../helpers';
import { storeOtp } from '../../src/utils/otp';

// Mock modules before importing app
jest.mock('../../src/config/database', () => ({
  __esModule: true,
  default: mockPrisma,
}));

jest.mock('../../src/services/push.service', () => ({
  sendPushNotification: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('../../src/services/cloudinary.service', () => ({
  uploadImage: jest.fn().mockResolvedValue('https://cloudinary.com/test.jpg'),
}));

jest.mock('../../src/services/google-auth.service', () => ({
  verifyGoogleToken: jest.fn(),
}));

import app from '../../src/app';
import { verifyGoogleToken } from '../../src/services/google-auth.service';

describe('Auth Controller', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/auth/send-otp', () => {
    it('should send OTP for valid phone', async () => {
      const res = await request(app)
        .post('/api/auth/send-otp')
        .send({ phone: '+1234567890' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toBe('OTP sent successfully');
    });

    it('should reject invalid phone number', async () => {
      const res = await request(app)
        .post('/api/auth/send-otp')
        .send({ phone: '123' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should reject empty body', async () => {
      const res = await request(app)
        .post('/api/auth/send-otp')
        .send({});

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/auth/verify-otp', () => {
    it('should verify valid OTP and return tokens for new user', async () => {
      const phone = '+1987654321';
      storeOtp(phone, '123456');

      mockPrisma.user.findUnique.mockResolvedValue(null);
      const newUser = createTestUser({ phone, id: 'new-user-id' });
      mockPrisma.user.create.mockResolvedValue(newUser);
      mockPrisma.refreshToken.create.mockResolvedValue({ id: 'rt-1' });

      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ phone, otp: '123456' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
      expect(res.body.data.isNewUser).toBe(true);
    });

    it('should verify valid OTP for existing user', async () => {
      const phone = '+1555666777';
      storeOtp(phone, '654321');

      const existingUser = createTestUser({ phone, id: 'existing-id' });
      mockPrisma.user.findUnique.mockResolvedValue(existingUser);
      mockPrisma.refreshToken.create.mockResolvedValue({ id: 'rt-2' });

      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ phone, otp: '654321' });

      expect(res.status).toBe(200);
      expect(res.body.data.isNewUser).toBe(false);
      expect(res.body.data.user.id).toBe('existing-id');
    });

    it('should reject invalid OTP', async () => {
      const phone = '+1888999000';
      storeOtp(phone, '111111');

      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ phone, otp: '999999' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should reject missing OTP', async () => {
      const res = await request(app)
        .post('/api/auth/verify-otp')
        .send({ phone: '+1234567890' });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/auth/google', () => {
    it('should authenticate with valid Google token for new user', async () => {
      const googleUser = {
        googleId: 'google-123',
        name: 'Google User',
        email: 'google@example.com',
        avatarUrl: 'https://avatar.url',
      };
      (verifyGoogleToken as jest.Mock).mockResolvedValue(googleUser);

      mockPrisma.user.findUnique.mockResolvedValue(null);
      const newUser = createTestUser({
        id: 'google-user-id',
        name: googleUser.name,
        email: googleUser.email,
        googleId: googleUser.googleId,
      });
      mockPrisma.user.create.mockResolvedValue(newUser);
      mockPrisma.refreshToken.create.mockResolvedValue({ id: 'rt-3' });

      const res = await request(app)
        .post('/api/auth/google')
        .send({ idToken: 'valid-google-token' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data.isNewUser).toBe(true);
    });

    it('should reject empty idToken', async () => {
      const res = await request(app)
        .post('/api/auth/google')
        .send({ idToken: '' });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/auth/refresh', () => {
    it('should refresh access token with valid refresh token', async () => {
      const { refreshToken } = generateTestTokens('user-1', 'fam-1', 'admin');

      mockPrisma.refreshToken.findFirst.mockResolvedValue({
        id: 'rt-1',
        token: refreshToken,
        userId: 'user-1',
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // future
      });
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: 'user-1', familyId: 'fam-1', role: 'admin' })
      );

      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken });

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('accessToken');
    });

    it('should reject invalid refresh token', async () => {
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: 'invalid-refresh-token' });

      expect(res.status).toBe(401);
    });

    it('should reject missing refresh token', async () => {
      const res = await request(app)
        .post('/api/auth/refresh')
        .send({});

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/auth/logout', () => {
    it('should logout with valid auth', async () => {
      const { accessToken, refreshToken } = generateTestTokens('user-1');
      mockPrisma.refreshToken.deleteMany.mockResolvedValue({ count: 1 });

      const res = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ refreshToken });

      expect(res.status).toBe(200);
      expect(res.body.message).toBe('Logged out successfully');
    });

    it('should reject logout without auth', async () => {
      const res = await request(app)
        .post('/api/auth/logout')
        .send({ refreshToken: 'some-token' });

      expect(res.status).toBe(401);
    });
  });
});
