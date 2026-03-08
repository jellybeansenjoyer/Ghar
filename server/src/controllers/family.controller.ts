import { Request, Response } from 'express';
import prisma from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { createFamilySchema, addMemberSchema } from '../validators/family.validator';
import { env } from '../config/env';
import { signAccessToken } from '../utils/jwt';

export async function createFamily(req: Request, res: Response): Promise<void> {
  try {
    const userId = req.user!.userId;
    const data = createFamilySchema.parse(req.body);

    // Check if user already has a family
    const existingUser = await prisma.user.findUnique({ where: { id: userId } });
    if (existingUser?.familyId) {
      sendError(res, 'You already belong to a family', 400);
      return;
    }

    // Create family and assign user as admin
    const family = await prisma.family.create({
      data: {
        name: data.name,
        address: data.address,
        adminId: userId,
      },
    });

    // Generate QR code data (URL to visitor form)
    const qrCodeData = `${env.APP_URL}/visit/${family.id}`;
    await prisma.family.update({
      where: { id: family.id },
      data: { qrCodeData },
    });

    // Update user to be admin of this family
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        familyId: family.id,
        role: 'admin',
      },
    });

    // Generate new access token with updated family info
    const accessToken = signAccessToken({
      userId: updatedUser.id,
      familyId: updatedUser.familyId,
      role: updatedUser.role,
    });

    sendSuccess(
      res,
      { family: { ...family, qrCodeData }, accessToken },
      'Family created successfully',
      201
    );
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('Create family error:', error);
    sendError(res, 'Failed to create family');
  }
}

export async function getFamily(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const userId = req.user!.userId;

    const family = await prisma.family.findUnique({
      where: { id },
      include: {
        admin: {
          select: { id: true, name: true, phone: true, avatarUrl: true },
        },
      },
    });

    if (!family) {
      sendError(res, 'Family not found', 404);
      return;
    }

    // Check membership
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (user?.familyId !== id) {
      sendError(res, 'You are not a member of this family', 403);
      return;
    }

    sendSuccess(res, family);
  } catch (error) {
    console.error('Get family error:', error);
    sendError(res, 'Failed to get family');
  }
}

export async function getMembers(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const userId = req.user!.userId;

    // Check membership
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (user?.familyId !== id) {
      sendError(res, 'You are not a member of this family', 403);
      return;
    }

    const members = await prisma.user.findMany({
      where: { familyId: id },
      select: {
        id: true,
        name: true,
        phone: true,
        email: true,
        avatarUrl: true,
        role: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'asc' },
    });

    sendSuccess(res, members);
  } catch (error) {
    console.error('Get members error:', error);
    sendError(res, 'Failed to get members');
  }
}

export async function addMember(req: Request, res: Response): Promise<void> {
  try {
    const familyId = req.params.id as string;
    const userId = req.user!.userId;
    const data = addMemberSchema.parse(req.body);

    // Verify admin
    const admin = await prisma.user.findUnique({ where: { id: userId } });
    if (admin?.familyId !== familyId || admin.role !== 'admin') {
      sendError(res, 'Only family admin can add members', 403);
      return;
    }

    // Find user by phone
    const targetUser = await prisma.user.findUnique({ where: { phone: data.phone } });
    if (!targetUser) {
      sendError(res, 'No user found with this phone number. They need to install the app first.', 404);
      return;
    }

    if (targetUser.familyId) {
      if (targetUser.familyId === familyId) {
        sendError(res, 'This user is already a member of your family', 400);
      } else {
        sendError(res, 'This user already belongs to another family', 400);
      }
      return;
    }

    // Add to family
    const updatedUser = await prisma.user.update({
      where: { id: targetUser.id },
      data: {
        familyId,
        role: 'member',
      },
      select: {
        id: true,
        name: true,
        phone: true,
        email: true,
        avatarUrl: true,
        role: true,
      },
    });

    sendSuccess(res, updatedUser, 'Member added successfully', 201);
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('Add member error:', error);
    sendError(res, 'Failed to add member');
  }
}

export async function removeMember(req: Request, res: Response): Promise<void> {
  try {
    const familyId = req.params.id as string;
    const targetUserId = req.params.userId as string;
    const adminId = req.user!.userId;

    // Verify admin
    const admin = await prisma.user.findUnique({ where: { id: adminId } });
    if (admin?.familyId !== familyId || admin.role !== 'admin') {
      sendError(res, 'Only family admin can remove members', 403);
      return;
    }

    if (adminId === targetUserId) {
      sendError(res, 'Admin cannot remove themselves', 400);
      return;
    }

    const targetUser = await prisma.user.findUnique({ where: { id: targetUserId } });
    if (!targetUser || targetUser.familyId !== familyId) {
      sendError(res, 'User is not a member of this family', 404);
      return;
    }

    await prisma.user.update({
      where: { id: targetUserId },
      data: {
        familyId: null,
        role: 'member',
      },
    });

    sendSuccess(res, null, 'Member removed successfully');
  } catch (error) {
    console.error('Remove member error:', error);
    sendError(res, 'Failed to remove member');
  }
}

export async function getQrCode(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;
    const userId = req.user!.userId;

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (user?.familyId !== id) {
      sendError(res, 'You are not a member of this family', 403);
      return;
    }

    const family = await prisma.family.findUnique({
      where: { id },
      select: { id: true, qrCodeData: true, name: true },
    });

    if (!family) {
      sendError(res, 'Family not found', 404);
      return;
    }

    // Always generate QR data from current APP_URL to avoid stale localhost URLs
    const qrData = `${env.APP_URL}/visit/${family.id}`;

    // Update stored value if it's out of date
    if (family.qrCodeData !== qrData) {
      await prisma.family.update({
        where: { id },
        data: { qrCodeData: qrData },
      });
    }

    sendSuccess(res, { qrData, familyName: family.name });
  } catch (error) {
    console.error('Get QR code error:', error);
    sendError(res, 'Failed to get QR code');
  }
}
