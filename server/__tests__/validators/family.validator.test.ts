import { createFamilySchema, addMemberSchema, updateProfileSchema } from '../../src/validators/family.validator';

describe('Family Validators', () => {
  describe('createFamilySchema', () => {
    it('should accept valid family name', () => {
      const result = createFamilySchema.parse({ name: 'My Family' });
      expect(result.name).toBe('My Family');
    });

    it('should accept family name with optional address', () => {
      const result = createFamilySchema.parse({ name: 'My Family', address: '123 Main St' });
      expect(result.name).toBe('My Family');
      expect(result.address).toBe('123 Main St');
    });

    it('should reject empty name', () => {
      expect(() => createFamilySchema.parse({ name: '' })).toThrow();
    });

    it('should reject missing name', () => {
      expect(() => createFamilySchema.parse({})).toThrow();
    });

    it('should reject name longer than 255 chars', () => {
      expect(() => createFamilySchema.parse({ name: 'a'.repeat(256) })).toThrow();
    });

    it('should reject address longer than 500 chars', () => {
      expect(() => createFamilySchema.parse({ name: 'Family', address: 'a'.repeat(501) })).toThrow();
    });
  });

  describe('addMemberSchema', () => {
    it('should accept a valid phone number', () => {
      const result = addMemberSchema.parse({ phone: '+1234567890' });
      expect(result.phone).toBe('+1234567890');
    });

    it('should reject invalid phone', () => {
      expect(() => addMemberSchema.parse({ phone: '123' })).toThrow();
    });

    it('should reject missing phone', () => {
      expect(() => addMemberSchema.parse({})).toThrow();
    });

    it('should reject phone with letters', () => {
      expect(() => addMemberSchema.parse({ phone: '+12345abcde' })).toThrow();
    });
  });

  describe('updateProfileSchema', () => {
    it('should accept valid name', () => {
      const result = updateProfileSchema.parse({ name: 'New Name' });
      expect(result.name).toBe('New Name');
    });

    it('should accept valid avatarUrl', () => {
      const result = updateProfileSchema.parse({ avatarUrl: 'https://example.com/avatar.jpg' });
      expect(result.avatarUrl).toBe('https://example.com/avatar.jpg');
    });

    it('should accept both fields', () => {
      const result = updateProfileSchema.parse({ name: 'Name', avatarUrl: 'https://ex.com/a.png' });
      expect(result.name).toBe('Name');
      expect(result.avatarUrl).toBe('https://ex.com/a.png');
    });

    it('should accept empty object (all optional)', () => {
      const result = updateProfileSchema.parse({});
      expect(result).toBeDefined();
    });

    it('should reject invalid URL', () => {
      expect(() => updateProfileSchema.parse({ avatarUrl: 'not-a-url' })).toThrow();
    });
  });
});
