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

describe('Family Controller', () => {
  const adminId = 'admin-uuid-1';
  const memberId = 'member-uuid-1';
  const familyId = 'family-uuid-1';
  let adminTokens: ReturnType<typeof generateTestTokens>;
  let memberTokens: ReturnType<typeof generateTestTokens>;

  beforeEach(() => {
    jest.clearAllMocks();
    adminTokens = generateTestTokens(adminId, familyId, 'admin');
    memberTokens = generateTestTokens(memberId, familyId, 'member');
  });

  describe('POST /api/families', () => {
    it('should create a new family', async () => {
      const noFamilyTokens = generateTestTokens(adminId, undefined, 'member');
      mockPrisma.user.findUnique.mockResolvedValue(createTestUser({ id: adminId, familyId: null }));
      const family = createTestFamily({ adminId });
      mockPrisma.family.create.mockResolvedValue(family);
      mockPrisma.family.update.mockResolvedValue({ ...family, qrCodeData: `http://localhost:3001/visit/${family.id}` });
      mockPrisma.user.update.mockResolvedValue(
        createTestUser({ id: adminId, familyId: family.id, role: 'admin' })
      );

      const res = await request(app)
        .post('/api/families')
        .set(authHeader(noFamilyTokens.accessToken))
        .send({ name: 'Test Family', address: '123 Main St' });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.family).toBeDefined();
      expect(res.body.data.accessToken).toBeDefined();
    });

    it('should reject if user already has a family', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: adminId, familyId })
      );

      const res = await request(app)
        .post('/api/families')
        .set(authHeader(adminTokens.accessToken))
        .send({ name: 'Another Family' });

      expect(res.status).toBe(400);
      expect(res.body.message).toBe('You already belong to a family');
    });

    it('should reject empty family name', async () => {
      const res = await request(app)
        .post('/api/families')
        .set(authHeader(adminTokens.accessToken))
        .send({ name: '' });

      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/families/:id', () => {
    it('should return family details for member', async () => {
      const family = createTestFamily({ id: familyId });
      mockPrisma.family.findUnique.mockResolvedValue({
        ...family,
        admin: { id: adminId, name: 'Admin', phone: '+1234567890', avatarUrl: null },
      });
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: memberId, familyId })
      );

      const res = await request(app)
        .get(`/api/families/${familyId}`)
        .set(authHeader(memberTokens.accessToken));

      expect(res.status).toBe(200);
      expect(res.body.data.id).toBe(familyId);
    });

    it('should return 404 for non-existent family', async () => {
      mockPrisma.family.findUnique.mockResolvedValue(null);

      const res = await request(app)
        .get('/api/families/nonexistent-id')
        .set(authHeader(adminTokens.accessToken));

      expect(res.status).toBe(404);
    });

    it('should reject non-member', async () => {
      mockPrisma.family.findUnique.mockResolvedValue(createTestFamily({ id: familyId }));
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: adminId, familyId: 'different-family' })
      );

      const res = await request(app)
        .get(`/api/families/${familyId}`)
        .set(authHeader(adminTokens.accessToken));

      expect(res.status).toBe(403);
    });
  });

  describe('GET /api/families/:id/members', () => {
    it('should return family members', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: memberId, familyId })
      );
      const members = [
        createTestUser({ id: adminId, role: 'admin' }),
        createTestUser({ id: memberId }),
      ];
      mockPrisma.user.findMany.mockResolvedValue(members);

      const res = await request(app)
        .get(`/api/families/${familyId}/members`)
        .set(authHeader(memberTokens.accessToken));

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(2);
    });

    it('should reject non-member', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: memberId, familyId: 'other-family' })
      );

      const res = await request(app)
        .get(`/api/families/${familyId}/members`)
        .set(authHeader(memberTokens.accessToken));

      expect(res.status).toBe(403);
    });
  });

  describe('POST /api/families/:id/members', () => {
    it('should add a member as admin', async () => {
      const admin = createTestUser({ id: adminId, familyId, role: 'admin' });
      const targetUser = createTestUser({ id: 'new-member-id', familyId: null, phone: '+9876543210' });
      const addedUser = { ...targetUser, familyId, role: 'member' };

      mockPrisma.user.findUnique
        .mockResolvedValueOnce(admin) // admin lookup
        .mockResolvedValueOnce(targetUser); // target user lookup
      mockPrisma.user.update.mockResolvedValue(addedUser);

      const res = await request(app)
        .post(`/api/families/${familyId}/members`)
        .set(authHeader(adminTokens.accessToken))
        .send({ phone: '+9876543210' });

      expect(res.status).toBe(201);
      expect(res.body.message).toBe('Member added successfully');
    });

    it('should reject non-admin adding members', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: memberId, familyId, role: 'member' })
      );

      const res = await request(app)
        .post(`/api/families/${familyId}/members`)
        .set(authHeader(memberTokens.accessToken))
        .send({ phone: '+9876543210' });

      expect(res.status).toBe(403);
    });

    it('should reject if target user not found', async () => {
      mockPrisma.user.findUnique
        .mockResolvedValueOnce(createTestUser({ id: adminId, familyId, role: 'admin' }))
        .mockResolvedValueOnce(null);

      const res = await request(app)
        .post(`/api/families/${familyId}/members`)
        .set(authHeader(adminTokens.accessToken))
        .send({ phone: '+9999999999' });

      expect(res.status).toBe(404);
    });

    it('should reject if target user already in this family', async () => {
      mockPrisma.user.findUnique
        .mockResolvedValueOnce(createTestUser({ id: adminId, familyId, role: 'admin' }))
        .mockResolvedValueOnce(createTestUser({ id: 'x', familyId, phone: '+1111111111' }));

      const res = await request(app)
        .post(`/api/families/${familyId}/members`)
        .set(authHeader(adminTokens.accessToken))
        .send({ phone: '+1111111111' });

      expect(res.status).toBe(400);
      expect(res.body.message).toContain('already a member');
    });

    it('should reject if target user in another family', async () => {
      mockPrisma.user.findUnique
        .mockResolvedValueOnce(createTestUser({ id: adminId, familyId, role: 'admin' }))
        .mockResolvedValueOnce(createTestUser({ id: 'y', familyId: 'other-fam', phone: '+2222222222' }));

      const res = await request(app)
        .post(`/api/families/${familyId}/members`)
        .set(authHeader(adminTokens.accessToken))
        .send({ phone: '+2222222222' });

      expect(res.status).toBe(400);
      expect(res.body.message).toContain('another family');
    });
  });

  describe('DELETE /api/families/:id/members/:userId', () => {
    it('should remove a member as admin', async () => {
      mockPrisma.user.findUnique
        .mockResolvedValueOnce(createTestUser({ id: adminId, familyId, role: 'admin' }))
        .mockResolvedValueOnce(createTestUser({ id: memberId, familyId }));
      mockPrisma.user.update.mockResolvedValue(
        createTestUser({ id: memberId, familyId: null })
      );

      const res = await request(app)
        .delete(`/api/families/${familyId}/members/${memberId}`)
        .set(authHeader(adminTokens.accessToken));

      expect(res.status).toBe(200);
      expect(res.body.message).toBe('Member removed successfully');
    });

    it('should prevent admin from removing themselves', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: adminId, familyId, role: 'admin' })
      );

      const res = await request(app)
        .delete(`/api/families/${familyId}/members/${adminId}`)
        .set(authHeader(adminTokens.accessToken));

      expect(res.status).toBe(400);
      expect(res.body.message).toContain('cannot remove themselves');
    });

    it('should reject non-admin removing members', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: memberId, familyId, role: 'member' })
      );

      const res = await request(app)
        .delete(`/api/families/${familyId}/members/some-user`)
        .set(authHeader(memberTokens.accessToken));

      expect(res.status).toBe(403);
    });
  });

  describe('GET /api/families/:id/qr', () => {
    it('should return QR code data', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: memberId, familyId })
      );
      mockPrisma.family.findUnique.mockResolvedValue({
        qrCodeData: 'http://localhost:3001/visit/fam-1',
        name: 'Test Family',
      });

      const res = await request(app)
        .get(`/api/families/${familyId}/qr`)
        .set(authHeader(memberTokens.accessToken));

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveProperty('qrData');
      expect(res.body.data).toHaveProperty('familyName');
    });

    it('should reject non-member', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(
        createTestUser({ id: memberId, familyId: 'other' })
      );

      const res = await request(app)
        .get(`/api/families/${familyId}/qr`)
        .set(authHeader(memberTokens.accessToken));

      expect(res.status).toBe(403);
    });
  });
});
