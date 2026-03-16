import { z } from 'zod';

export const createFamilySchema = z.object({
  name: z.string().min(1, 'Family name is required').max(255),
  address: z.string().max(500).optional(),
});

export const addMemberSchema = z.object({
  phone: z
    .string()
    .min(10, 'Phone number must be at least 10 digits')
    .max(15)
    .regex(/^\+?[1-9]\d{9,14}$/, 'Invalid phone number format')
    .optional(),
  email: z.string().email('Invalid email format').optional(),
  inviteToken: z.string().min(1, 'Invite token is required').optional(),
}).refine(
  (data) => data.phone || data.email || data.inviteToken,
  { message: 'Either phone, email, or inviteToken must be provided' }
);

export const createInviteSchema = z.object({
  expiresInDays: z.number().int().min(1).max(30).default(7),
});

export const updateProfileSchema = z.object({
  name: z.string().min(1).max(255).optional(),
  avatarUrl: z.string().url().optional(),
});
