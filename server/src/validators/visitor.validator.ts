import { z } from 'zod';

export const createVisitorSchema = z.object({
  familyId: z.string().uuid('Invalid family ID'),
  name: z.string().min(1, 'Visitor name is required').max(255),
});

export const respondVisitorSchema = z.object({
  action: z.enum(['accept', 'reject'], {
    errorMap: () => ({ message: 'Action must be "accept" or "reject"' }),
  }),
});

export const sendMessageSchema = z.object({
  content: z.string().min(1, 'Message content is required').max(1000),
  senderType: z.enum(['visitor', 'member']),
  senderName: z.string().min(1).max(255),
});
