import { Request, Response } from 'express';
import prisma from '../config/database';
import { sendOtp as sendOtpSms, verifyOtp } from '../services/otp.service';
import { verifyGoogleToken } from '../services/google-auth.service';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../utils/jwt';
import { sendSuccess, sendError } from '../utils/response';
import {
  sendOtpSchema,
  verifyOtpSchema,
  googleAuthSchema,
  emailAuthSchema,
  refreshTokenSchema,
} from '../validators/auth.validator';

export async function sendOtpHandler(req: Request, res: Response): Promise<void> {
  try {
    const { phone } = sendOtpSchema.parse(req.body);
    await sendOtpSms(phone);
    sendSuccess(res, null, 'OTP sent successfully');
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('Send OTP error:', error);
    sendError(res, 'Failed to send OTP', 500);
  }
}

export async function verifyOtpHandler(req: Request, res: Response): Promise<void> {
  try {
    const { phone, otp } = verifyOtpSchema.parse(req.body);
    const result = verifyOtp(phone, otp);

    if (!result.valid) {
      sendError(res, result.reason || 'Invalid OTP', 400);
      return;
    }

    // Find or create user
    let user = await prisma.user.findUnique({ where: { phone } });
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      user = await prisma.user.create({
        data: {
          name: '',
          phone,
          role: 'member',
        },
      });
    }

    // Generate tokens
    const accessToken = signAccessToken({
      userId: user.id,
      familyId: user.familyId,
      role: user.role,
    });
    const refreshToken = signRefreshToken(user.id);

    // Store refresh token
    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: refreshToken,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      },
    });

    sendSuccess(res, { accessToken, refreshToken, user, isNewUser }, 'Login successful');
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('Verify OTP error:', error);
    sendError(res, 'Verification failed', 500);
  }
}

export async function googleAuthHandler(req: Request, res: Response): Promise<void> {
  try {
    const { idToken } = googleAuthSchema.parse(req.body);
    const googleUser = await verifyGoogleToken(idToken);

    // Find or create user
    let user = await prisma.user.findUnique({ where: { googleId: googleUser.googleId } });
    let isNewUser = false;

    if (!user) {
      // Check if user with same email exists
      if (googleUser.email) {
        user = await prisma.user.findUnique({ where: { email: googleUser.email } });
        if (user) {
          // Link Google account to existing user
          user = await prisma.user.update({
            where: { id: user.id },
            data: {
              googleId: googleUser.googleId,
              avatarUrl: user.avatarUrl || googleUser.avatarUrl,
            },
          });
        }
      }

      if (!user) {
        isNewUser = true;
        user = await prisma.user.create({
          data: {
            name: googleUser.name,
            email: googleUser.email,
            googleId: googleUser.googleId,
            avatarUrl: googleUser.avatarUrl,
            role: 'member',
          },
        });
      }
    }

    const accessToken = signAccessToken({
      userId: user.id,
      familyId: user.familyId,
      role: user.role,
    });
    const refreshToken = signRefreshToken(user.id);

    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: refreshToken,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });

    sendSuccess(res, { accessToken, refreshToken, user, isNewUser }, 'Login successful');
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('Google auth error:', error);
    sendError(res, 'Google authentication failed', 500);
  }
}

export async function emailAuthHandler(req: Request, res: Response): Promise<void> {
  try {
    const { email, name } = emailAuthSchema.parse(req.body);

    let user = await prisma.user.findUnique({ where: { email } });
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      user = await prisma.user.create({
        data: {
          name: name?.trim() || email.split('@')[0] || 'User',
          email,
          role: 'member',
        },
      });
    } else if (name && name.trim().length > 0 && user.name !== name.trim()) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { name: name.trim() },
      });
    }

    const accessToken = signAccessToken({
      userId: user.id,
      familyId: user.familyId,
      role: user.role,
    });
    const refreshToken = signRefreshToken(user.id);

    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: refreshToken,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });

    sendSuccess(res, { accessToken, refreshToken, user, isNewUser }, 'Login successful');
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('Email auth error:', error);
    sendError(res, 'Email authentication failed', 500);
  }
}

export async function refreshTokenHandler(req: Request, res: Response): Promise<void> {
  try {
    const { refreshToken } = refreshTokenSchema.parse(req.body);

    // Verify the refresh token
    const { userId } = verifyRefreshToken(refreshToken);

    // Check if token exists in DB
    const storedToken = await prisma.refreshToken.findFirst({
      where: { token: refreshToken, userId },
    });

    if (!storedToken || storedToken.expiresAt < new Date()) {
      if (storedToken) {
        await prisma.refreshToken.delete({ where: { id: storedToken.id } });
      }
      sendError(res, 'Invalid or expired refresh token', 401);
      return;
    }

    // Get fresh user data
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      sendError(res, 'User not found', 404);
      return;
    }

    const accessToken = signAccessToken({
      userId: user.id,
      familyId: user.familyId,
      role: user.role,
    });

    sendSuccess(res, { accessToken }, 'Token refreshed');
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    sendError(res, 'Token refresh failed', 401);
  }
}

export async function logoutHandler(req: Request, res: Response): Promise<void> {
  try {
    const { refreshToken } = refreshTokenSchema.parse(req.body);

    await prisma.refreshToken.deleteMany({
      where: { token: refreshToken },
    });

    sendSuccess(res, null, 'Logged out successfully');
  } catch (error) {
    sendError(res, 'Logout failed', 500);
  }
}
