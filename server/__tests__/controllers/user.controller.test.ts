import request from 'supertest';
import mockPrisma from '../mocks/prisma';
import { createTestUser, createTestFamily, generateTestTokens, authHeader } from '../helpers';

jest.mock('../../src/config/database', () => ({
  __esModule: true,
  default: mockPrisma,
}));

jest.mock('../../src/services/push.service', () => ({
  sendPushNotification: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('../../src/services/cloudinary.service', () => ({
  uploadImage: jest.fn().mockResolvedValue(null),
}));

jest.mock('../../src/services/google-auth.service', () => ({
  verifyGoogleToken: jest.fn(),
}));

import app from '../../src/app';

describe('User Controller', () => {
  const userId = 'user-uuid-1';
  const familyId = 'family-uuid-1';
  let tokens: ReturnType<typeof generateTestTokens>;

  beforeEach(() => {
    jest.clearAllMocks();
    tokens = generateTestTokens(userId, familyId, 'admin');
  });

  describe('GET /api/users/me', () => {
    it('should return user profile', async () => {
      const user = createTestUser({ id: userId, familyId, family: createTestFamily() });
      mockPrisma.user.findUnique.mockResolvedValue(user);

      const res = await request(app)
        .get('/api/users/me')
        .set(authHeader(tokens.accessToken));

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBe(userId);
    });

    it('should return 404 if user not found', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      const res = await request(app)
        .get('/api/users/me')
        .set(authHeader(tokens.accessToken));

      expect(res.status).toBe(404);
      expect(res.body.message).toBe('User not found');
    });

    it('should reject unauthenticated request', async () => {
      const res = await request(app).get('/api/users/me');

      expect(res.status).toBe(401);
    });
  });

  describe('PUT /api/users/me', () => {
    it('should update user name', async () => {
      const updatedUser = createTestUser({ id: userId, name: 'Updated Name', family: null });
      mockPrisma.user.update.mockResolvedValue(updatedUser);

      const res = await request(app)
        .put('/api/users/me')
        .set(authHeader(tokens.accessToken))
        .send({ name: 'Updated Name' });

      expect(res.status).toBe(200);
      expect(res.body.data.name).toBe('Updated Name');
    });

    it('should update user avatar', async () => {
      const updatedUser = createTestUser({
        id: userId,
        avatarUrl: 'https://new-avatar.com/img.jpg',
        family: null,
      });
      mockPrisma.user.update.mockResolvedValue(updatedUser);

      const res = await request(app)
        .put('/api/users/me')
        .set(authHeader(tokens.accessToken))
        .send({ avatarUrl: 'https://new-avatar.com/img.jpg' });

      expect(res.status).toBe(200);
      expect(res.body.data.avatarUrl).toBe('https://new-avatar.com/img.jpg');
    });

    it('should reject invalid avatar URL', async () => {
      const res = await request(app)
        .put('/api/users/me')
        .set(authHeader(tokens.accessToken))
        .send({ avatarUrl: 'not-a-url' });

      expect(res.status).toBe(400);
    });
  });

  describe('PUT /api/users/me/push-token', () => {
    it('should update push token', async () => {
      mockPrisma.user.update.mockResolvedValue(
        createTestUser({ id: userId, onesignalPlayerId: 'player-123' })
      );

      const res = await request(app)
        .put('/api/users/me/push-token')
        .set(authHeader(tokens.accessToken))
        .send({ playerId: 'player-123' });

      expect(res.status).toBe(200);
      expect(res.body.message).toBe('Push token updated');
    });

    it('should reject missing playerId', async () => {
      const res = await request(app)
        .put('/api/users/me/push-token')
        .set(authHeader(tokens.accessToken))
        .send({});

      expect(res.status).toBe(400);
    });
  });
});
