import { Request, Response } from 'express';
import prisma from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { updateProfileSchema } from '../validators/family.validator';

export async function getProfile(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user!.userId;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        family: true,
      },
    });

    if (!user) {
      sendError(res, 'User not found', 404);
      return;
    }

    sendSuccess(res, user);
  } catch (error) {
    console.error('Get profile error:', error);
    sendError(res, 'Failed to get profile');
  }
}

export async function updateProfile(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user!.userId;
    const data = updateProfileSchema.parse(req.body);

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(data.name && { name: data.name }),
        ...(data.avatarUrl && { avatarUrl: data.avatarUrl }),
      },
      include: {
        family: true,
      },
    });

    sendSuccess(res, user, 'Profile updated');
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('Update profile error:', error);
    sendError(res, 'Failed to update profile');
  }
}

export async function updatePushToken(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user!.userId;
    const { playerId } = req.body;

    if (!playerId) {
      sendError(res, 'Player ID is required', 400);
      return;
    }

    console.log(`[updatePushToken] Updating push token for user ${userId}: ${playerId}`);

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { onesignalPlayerId: playerId },
      select: { id: true, name: true, onesignalPlayerId: true },
    });

    console.log(`[updatePushToken] ✅ Push token updated successfully for user ${updatedUser.name}`);

    sendSuccess(res, null, 'Push token updated');
  } catch (error: any) {
    console.error('[updatePushToken] Error:', error?.message || error);
    sendError(res, 'Failed to update push token');
  }
}
