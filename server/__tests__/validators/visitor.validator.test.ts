import { createVisitorSchema, respondVisitorSchema, sendMessageSchema } from '../../src/validators/visitor.validator';

describe('Visitor Validators', () => {
  describe('createVisitorSchema', () => {
    it('should accept valid visitor data', () => {
      const data = {
        familyId: '550e8400-e29b-41d4-a716-446655440000',
        name: 'John Doe',
      };
      const result = createVisitorSchema.parse(data);
      expect(result.familyId).toBe(data.familyId);
      expect(result.name).toBe(data.name);
    });

    it('should reject invalid UUID familyId', () => {
      expect(() => createVisitorSchema.parse({ familyId: 'not-uuid', name: 'John' })).toThrow();
    });

    it('should reject empty name', () => {
      expect(() =>
        createVisitorSchema.parse({
          familyId: '550e8400-e29b-41d4-a716-446655440000',
          name: '',
        })
      ).toThrow();
    });

    it('should reject missing fields', () => {
      expect(() => createVisitorSchema.parse({})).toThrow();
      expect(() => createVisitorSchema.parse({ familyId: '550e8400-e29b-41d4-a716-446655440000' })).toThrow();
    });

    it('should reject name longer than 255 chars', () => {
      expect(() =>
        createVisitorSchema.parse({
          familyId: '550e8400-e29b-41d4-a716-446655440000',
          name: 'x'.repeat(256),
        })
      ).toThrow();
    });
  });

  describe('respondVisitorSchema', () => {
    it('should accept "accept" action', () => {
      const result = respondVisitorSchema.parse({ action: 'accept' });
      expect(result.action).toBe('accept');
    });

    it('should accept "reject" action', () => {
      const result = respondVisitorSchema.parse({ action: 'reject' });
      expect(result.action).toBe('reject');
    });

    it('should reject invalid action', () => {
      expect(() => respondVisitorSchema.parse({ action: 'talk' })).toThrow();
      expect(() => respondVisitorSchema.parse({ action: 'maybe' })).toThrow();
    });

    it('should reject missing action', () => {
      expect(() => respondVisitorSchema.parse({})).toThrow();
    });
  });

  describe('sendMessageSchema', () => {
    it('should accept valid message data', () => {
      const data = { content: 'Hello!', senderType: 'member', senderName: 'Alice' };
      const result = sendMessageSchema.parse(data);
      expect(result.content).toBe('Hello!');
      expect(result.senderType).toBe('member');
      expect(result.senderName).toBe('Alice');
    });

    it('should accept "visitor" senderType', () => {
      const result = sendMessageSchema.parse({
        content: 'Hi',
        senderType: 'visitor',
        senderName: 'Visitor',
      });
      expect(result.senderType).toBe('visitor');
    });

    it('should reject invalid senderType', () => {
      expect(() =>
        sendMessageSchema.parse({ content: 'Hi', senderType: 'bot', senderName: 'Bot' })
      ).toThrow();
    });

    it('should reject empty content', () => {
      expect(() =>
        sendMessageSchema.parse({ content: '', senderType: 'member', senderName: 'Alice' })
      ).toThrow();
    });

    it('should reject content longer than 1000 chars', () => {
      expect(() =>
        sendMessageSchema.parse({
          content: 'x'.repeat(1001),
          senderType: 'member',
          senderName: 'Alice',
        })
      ).toThrow();
    });

    it('should reject missing fields', () => {
      expect(() => sendMessageSchema.parse({})).toThrow();
    });
  });
});
