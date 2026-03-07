import request from 'supertest';
import mockPrisma from '../mocks/prisma';
import { createTestUser, createTestVisitor, createTestFamily, createTestMessage, generateTestTokens, authHeader } from '../helpers';

jest.mock('../../src/config/database', () => ({
  __esModule: true,
  default: mockPrisma,
}));

jest.mock('../../src/services/push.service', () => ({
  sendPushNotification: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('../../src/services/cloudinary.service', () => ({
  uploadImage: jest.fn().mockResolvedValue('https://cloudinary.com/visitor.jpg'),
}));

jest.mock('../../src/services/google-auth.service', () => ({
  verifyGoogleToken: jest.fn(),
}));

// Mock Socket.IO
const mockEmit = jest.fn();
const mockTo = jest.fn(() => ({ emit: mockEmit }));
jest.mock('../../src/socket', () => ({
  getIO: () => ({ to: mockTo }),
  initializeSocket: jest.fn(),
}));

import app from '../../src/app';

describe('Visitor Controller', () => {
  const userId = 'user-uuid-1';
  const familyId = '550e8400-e29b-41d4-a716-446655440000';
  let tokens: ReturnType<typeof generateTestTokens>;

  beforeEach(() => {
    jest.clearAllMocks();
    tokens = generateTestTokens(userId, familyId, 'member');
  });

  describe('POST /api/visitors', () => {
    it('should create a visitor and notify family', async () => {
      const family = createTestFamily({ id: familyId });
      const visitor = createTestVisitor({
        familyId,
        name: 'John Visitor',
        arrivedAt: new Date(),
      });

      mockPrisma.family.findUnique.mockResolvedValue(family);
      mockPrisma.visitor.create.mockResolvedValue(visitor);
      mockPrisma.user.findMany.mockResolvedValue([
        createTestUser({ id: userId, onesignalPlayerId: 'player-1' }),
      ]);

      const res = await request(app)
        .post('/api/visitors')
        .send({ familyId, name: 'John Visitor' });

      expect(res.status).toBe(201);
      expect(res.body.data.visitorId).toBe(visitor.id);
      expect(res.body.data.status).toBe('pending');
    });

    it('should reject visitor for non-existent family', async () => {
      mockPrisma.family.findUnique.mockResolvedValue(null);

      const res = await request(app)
        .post('/api/visitors')
        .send({
          familyId: '550e8400-e29b-41d4-a716-446655440000',
          name: 'Visitor',
        });

      expect(res.status).toBe(404);
    });

    it('should reject invalid familyId format', async () => {
      const res = await request(app)
        .post('/api/visitors')
        .send({ familyId: 'not-a-uuid', name: 'Visitor' });

      expect(res.status).toBe(400);
    });

    it('should reject empty visitor name', async () => {
      const res = await request(app)
        .post('/api/visitors')
        .send({
          familyId: '550e8400-e29b-41d4-a716-446655440000',
          name: '',
        });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/visitors/:id/respond', () => {
    it('should accept a visitor', async () => {
      const visitor = createTestVisitor({ id: 'vis-1', familyId, status: 'pending', family: createTestFamily() });
      const user = createTestUser({ id: userId, familyId, name: 'Family Member' });

      mockPrisma.visitor.findUnique.mockResolvedValue(visitor);
      mockPrisma.user.findUnique.mockResolvedValue(user);
      mockPrisma.visitor.update.mockResolvedValue({
        ...visitor,
        status: 'accepted',
        respondedById: userId,
        respondedAt: new Date(),
      });

      const res = await request(app)
        .post('/api/visitors/vis-1/respond')
        .set(authHeader(tokens.accessToken))
        .send({ action: 'accept' });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('accepted');
      // Verify Socket.IO events were emitted
      expect(mockTo).toHaveBeenCalledWith(`family:${familyId}`);
      expect(mockTo).toHaveBeenCalledWith('visitor:vis-1');
    });

    it('should reject a visitor', async () => {
      const visitor = createTestVisitor({ id: 'vis-2', familyId, status: 'pending', family: createTestFamily() });
      const user = createTestUser({ id: userId, familyId });

      mockPrisma.visitor.findUnique.mockResolvedValue(visitor);
      mockPrisma.user.findUnique.mockResolvedValue(user);
      mockPrisma.visitor.update.mockResolvedValue({ ...visitor, status: 'rejected' });

      const res = await request(app)
        .post('/api/visitors/vis-2/respond')
        .set(authHeader(tokens.accessToken))
        .send({ action: 'reject' });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('rejected');
    });

    it('should reject if visitor not found', async () => {
      mockPrisma.visitor.findUnique.mockResolvedValue(null);

      const res = await request(app)
        .post('/api/visitors/nonexistent/respond')
        .set(authHeader(tokens.accessToken))
        .send({ action: 'accept' });

      expect(res.status).toBe(404);
    });

    it('should reject if visitor already responded to', async () => {
      const visitor = createTestVisitor({
        id: 'vis-3',
        familyId,
        status: 'accepted',
        family: createTestFamily(),
      });

      mockPrisma.visitor.findUnique.mockResolvedValue(visitor);
      mockPrisma.user.findUnique.mockResolvedValue(createTestUser({ id: userId, familyId }));

      const res = await request(app)
        .post('/api/visitors/vis-3/respond')
        .set(authHeader(tokens.accessToken))
        .send({ action: 'reject' });

      expect(res.status).toBe(400);
      expect(res.body.message).toContain('already');
    });

    it('should reject non-family member responding', async () => {
      const visitor = createTestVisitor({ id: 'vis-4', familyId, family: createTestFamily() });

      mockPrisma.visitor.findUnique.mockResolvedValue(visitor);
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: userId, familyId: 'other-family' })
      );

      const res = await request(app)
        .post('/api/visitors/vis-4/respond')
        .set(authHeader(tokens.accessToken))
        .send({ action: 'accept' });

      expect(res.status).toBe(403);
    });

    it('should reject invalid action', async () => {
      const res = await request(app)
        .post('/api/visitors/vis-5/respond')
        .set(authHeader(tokens.accessToken))
        .send({ action: 'maybe' });

      expect(res.status).toBe(400);
    });

    it('should reject unauthenticated request', async () => {
      const res = await request(app)
        .post('/api/visitors/vis-1/respond')
        .send({ action: 'accept' });

      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/families/:id/visitors', () => {
    it('should return visitor history with pagination', async () => {
      const user = createTestUser({ id: userId, familyId });
      const visitors = [
        createTestVisitor({ id: 'v1', name: 'Visitor 1' }),
        createTestVisitor({ id: 'v2', name: 'Visitor 2' }),
      ];

      mockPrisma.user.findUnique.mockResolvedValue(user);
      mockPrisma.visitor.findMany.mockResolvedValue(visitors);
      mockPrisma.visitor.count.mockResolvedValue(2);

      const res = await request(app)
        .get(`/api/families/${familyId}/visitors?page=1&limit=20`)
        .set(authHeader(tokens.accessToken));

      expect(res.status).toBe(200);
      expect(res.body.data.visitors).toHaveLength(2);
      expect(res.body.data.pagination).toEqual({
        page: 1,
        limit: 20,
        total: 2,
        pages: 1,
      });
    });

    it('should reject non-member from viewing history', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: userId, familyId: 'other' })
      );

      const res = await request(app)
        .get(`/api/families/${familyId}/visitors`)
        .set(authHeader(tokens.accessToken));

      expect(res.status).toBe(403);
    });
  });

  describe('GET /api/visitors/:id', () => {
    it('should return visitor details', async () => {
      const visitor = createTestVisitor({
        id: 'vis-detail',
        respondedBy: { name: 'Admin' },
        family: { name: 'Test Family' },
      });
      mockPrisma.visitor.findUnique.mockResolvedValue(visitor);

      const res = await request(app).get('/api/visitors/vis-detail');

      expect(res.status).toBe(200);
      expect(res.body.data.id).toBe('vis-detail');
    });

    it('should return 404 for non-existent visitor', async () => {
      mockPrisma.visitor.findUnique.mockResolvedValue(null);

      const res = await request(app).get('/api/visitors/nonexistent');

      expect(res.status).toBe(404);
    });
  });

  describe('GET /api/visitors/:id/messages', () => {
    it('should return messages for a visitor', async () => {
      const messages = [
        createTestMessage({ id: 'm1', content: 'Hello' }),
        createTestMessage({ id: 'm2', content: 'Hi there', senderType: 'visitor' }),
      ];
      mockPrisma.message.findMany.mockResolvedValue(messages);

      const res = await request(app).get('/api/visitors/vis-1/messages');

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(2);
    });
  });

  describe('POST /api/visitors/:id/messages', () => {
    it('should send a message', async () => {
      const visitor = createTestVisitor({ id: 'vis-msg' });
      const message = createTestMessage({
        visitorId: 'vis-msg',
        content: 'Coming now!',
        sentAt: new Date(),
      });

      mockPrisma.visitor.findUnique.mockResolvedValue(visitor);
      mockPrisma.message.create.mockResolvedValue(message);

      const res = await request(app)
        .post('/api/visitors/vis-msg/messages')
        .send({ content: 'Coming now!', senderType: 'member', senderName: 'Admin' });

      expect(res.status).toBe(201);
      expect(res.body.data.content).toBe('Coming now!');
      // Verify Socket.IO emits
      expect(mockTo).toHaveBeenCalledWith('visitor:vis-msg');
    });

    it('should reject message for non-existent visitor', async () => {
      mockPrisma.visitor.findUnique.mockResolvedValue(null);

      const res = await request(app)
        .post('/api/visitors/nonexistent/messages')
        .send({ content: 'Hello', senderType: 'member', senderName: 'A' });

      expect(res.status).toBe(404);
    });

    it('should reject empty message content', async () => {
      const res = await request(app)
        .post('/api/visitors/vis-1/messages')
        .send({ content: '', senderType: 'member', senderName: 'A' });

      expect(res.status).toBe(400);
    });
  });
});
