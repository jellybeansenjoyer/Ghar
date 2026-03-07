import { signAccessToken, signRefreshToken } from '../src/utils/jwt';

/**
 * Generate test user data
 */
export function createTestUser(overrides: Record<string, any> = {}) {
  return {
    id: 'user-uuid-1',
    name: 'Test User',
    phone: '+1234567890',
    email: 'test@example.com',
    googleId: null,
    avatarUrl: null,
    familyId: null,
    role: 'member',
    onesignalPlayerId: null,
    createdAt: new Date('2025-01-01'),
    updatedAt: new Date('2025-01-01'),
    ...overrides,
  };
}

/**
 * Generate test family data
 */
export function createTestFamily(overrides: Record<string, any> = {}) {
  return {
    id: 'family-uuid-1',
    name: 'Test Family',
    address: '123 Test Street',
    adminId: 'user-uuid-1',
    qrCodeData: 'http://localhost:3001/visit/family-uuid-1',
    createdAt: new Date('2025-01-01'),
    ...overrides,
  };
}

/**
 * Generate test visitor data
 */
export function createTestVisitor(overrides: Record<string, any> = {}) {
  return {
    id: 'visitor-uuid-1',
    familyId: 'family-uuid-1',
    name: 'Test Visitor',
    photoUrl: null,
    status: 'pending',
    respondedById: null,
    arrivedAt: new Date('2025-01-01T10:00:00Z'),
    respondedAt: null,
    ...overrides,
  };
}

/**
 * Generate test message data
 */
export function createTestMessage(overrides: Record<string, any> = {}) {
  return {
    id: 'message-uuid-1',
    visitorId: 'visitor-uuid-1',
    senderType: 'member',
    senderName: 'Test User',
    senderId: 'user-uuid-1',
    content: 'Hello visitor!',
    sentAt: new Date('2025-01-01T10:05:00Z'),
    ...overrides,
  };
}

/**
 * Generate auth tokens for a test user
 */
export function generateTestTokens(userId = 'user-uuid-1', familyId?: string, role = 'member') {
  const accessToken = signAccessToken({ userId, familyId, role });
  const refreshToken = signRefreshToken(userId);
  return { accessToken, refreshToken };
}

/**
 * Generate authorization header
 */
export function authHeader(token: string) {
  return { Authorization: `Bearer ${token}` };
}
