import { z } from 'zod';

export const sendOtpSchema = z.object({
  phone: z
    .string()
    .min(10, 'Phone number must be at least 10 digits')
    .max(15, 'Phone number too long')
    .regex(/^\+?[1-9]\d{9,14}$/, 'Invalid phone number format. Use E.164 format (e.g., +1234567890)'),
});

export const verifyOtpSchema = z.object({
  phone: z.string().min(10).max(15),
  otp: z.string().length(6, 'OTP must be 6 digits').regex(/^\d{6}$/, 'OTP must be numeric'),
});

export const googleAuthSchema = z.object({
  idToken: z.string().min(1, 'Google ID token is required'),
});

export const emailAuthSchema = z.object({
  email: z.string().email('Valid email is required'),
  name: z.string().min(1, 'Name is required').max(255).optional(),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});
