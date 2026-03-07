import { Request, Response, NextFunction } from 'express';
import { authMiddleware, adminMiddleware } from '../../src/middleware/auth';
import { signAccessToken } from '../../src/utils/jwt';

function createMockReq(overrides: Partial<Request> = {}): Request {
  return {
    headers: {},
    ...overrides,
  } as Request;
}

function createMockRes(): Response {
  const res: Partial<Response> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  return res as Response;
}

describe('Auth Middleware', () => {
  let next: NextFunction;

  beforeEach(() => {
    next = jest.fn();
  });

  describe('authMiddleware', () => {
    it('should reject request without authorization header', () => {
      const req = createMockReq();
      const res = createMockRes();

      authMiddleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ success: false, message: 'Access token required' })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject request without Bearer prefix', () => {
      const req = createMockReq({ headers: { authorization: 'Token abc' } });
      const res = createMockRes();

      authMiddleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject request with invalid token', () => {
      const req = createMockReq({ headers: { authorization: 'Bearer invalid-token' } });
      const res = createMockRes();

      authMiddleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Invalid or expired access token' })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should accept valid token and attach user to request', () => {
      const token = signAccessToken({ userId: 'user-1', familyId: 'fam-1', role: 'admin' });
      const req = createMockReq({ headers: { authorization: `Bearer ${token}` } });
      const res = createMockRes();

      authMiddleware(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeDefined();
      expect(req.user!.userId).toBe('user-1');
      expect(req.user!.familyId).toBe('fam-1');
      expect(req.user!.role).toBe('admin');
    });

    it('should work with token that has no familyId', () => {
      const token = signAccessToken({ userId: 'user-2' });
      const req = createMockReq({ headers: { authorization: `Bearer ${token}` } });
      const res = createMockRes();

      authMiddleware(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user!.userId).toBe('user-2');
    });
  });

  describe('adminMiddleware', () => {
    it('should reject if no user is attached', () => {
      const req = createMockReq();
      const res = createMockRes();

      adminMiddleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject non-admin users', () => {
      const req = createMockReq();
      req.user = { userId: 'user-1', role: 'member' };
      const res = createMockRes();

      adminMiddleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'Admin access required' })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should allow admin users', () => {
      const req = createMockReq();
      req.user = { userId: 'user-1', role: 'admin', familyId: 'fam-1' };
      const res = createMockRes();

      adminMiddleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });
});
