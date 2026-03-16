import { Request, Response } from 'express';
import prisma from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { createFamilySchema, addMemberSchema, createInviteSchema } from '../validators/family.validator';
import { env } from '../config/env';
import { signAccessToken } from '../utils/jwt';
import crypto from 'crypto';

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

    let targetUser;

    // Handle invite token
    if (data.inviteToken) {
      const invite = await prisma.familyInvite.findUnique({
        where: { token: data.inviteToken },
        include: { family: true },
      });

      if (!invite) {
        sendError(res, 'Invalid invite token', 404);
        return;
      }

      if (invite.familyId !== familyId) {
        sendError(res, 'This invite is for a different family', 400);
        return;
      }

      if (invite.usedAt) {
        sendError(res, 'This invite has already been used', 400);
        return;
      }

      if (invite.expiresAt < new Date()) {
        sendError(res, 'This invite has expired', 400);
        return;
      }

      // Get the current user (they're accepting the invite)
      targetUser = await prisma.user.findUnique({ where: { id: userId } });
      if (!targetUser) {
        sendError(res, 'User not found', 404);
        return;
      }

      if (targetUser.familyId) {
        if (targetUser.familyId === familyId) {
          sendError(res, 'You are already a member of this family', 400);
        } else {
          sendError(res, 'You already belong to another family', 400);
        }
        return;
      }

      // Mark invite as used
      await prisma.familyInvite.update({
        where: { id: invite.id },
        data: { usedAt: new Date() },
      });
    } else {
      // Handle phone or email lookup
      if (data.phone) {
        targetUser = await prisma.user.findUnique({ where: { phone: data.phone } });
        if (!targetUser) {
          sendError(res, 'No user found with this phone number. They need to install the app first.', 404);
          return;
        }
      } else if (data.email) {
        targetUser = await prisma.user.findUnique({ where: { email: data.email } });
        if (!targetUser) {
          sendError(res, 'No user found with this email. They need to install the app first.', 404);
          return;
        }
      } else {
        sendError(res, 'Either phone, email, or inviteToken must be provided', 400);
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

    console.log(`[getQrCode] Request from user ${userId} for family ${id}`);

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (user?.familyId !== id) {
      console.log(`[getQrCode] Access denied: user ${userId} is not member of family ${id}`);
      sendError(res, 'You are not a member of this family', 403);
      return;
    }

    const family = await prisma.family.findUnique({
      where: { id },
      select: { id: true, qrCodeData: true, name: true },
    });

    if (!family) {
      console.log(`[getQrCode] Family not found: ${id}`);
      sendError(res, 'Family not found', 404);
      return;
    }

    // Always generate QR data from current APP_URL to avoid stale localhost URLs
    const qrData = `${env.APP_URL}/visit/${family.id}`;
    console.log(`[getQrCode] Generated QR data: ${qrData} (APP_URL: ${env.APP_URL})`);

    // Update stored value if it's out of date
    if (family.qrCodeData !== qrData) {
      console.log(`[getQrCode] Updating stale QR data in database`);
      await prisma.family.update({
        where: { id },
        data: { qrCodeData: qrData },
      });
    }

    console.log(`[getQrCode] Returning QR data for family: ${family.name}`);
    sendSuccess(res, { qrData, familyName: family.name });
  } catch (error) {
    console.error('[getQrCode] Error:', error?.message || JSON.stringify(error));
    sendError(res, 'Failed to get QR code');
  }
}

export async function createInvite(req: Request, res: Response): Promise<void> {
  try {
    const familyId = req.params.id as string;
    const userId = req.user!.userId;
    const data = createInviteSchema.parse(req.body);

    console.log(`[createInvite] Request from user ${userId} for family ${familyId}`);

    // Verify admin
    const admin = await prisma.user.findUnique({ where: { id: userId } });
    if (admin?.familyId !== familyId || admin.role !== 'admin') {
      console.log(`[createInvite] Access denied: user ${userId} is not admin of family ${familyId}`);
      sendError(res, 'Only family admin can create invites', 403);
      return;
    }

    // Generate unique token
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + data.expiresInDays);

    console.log(`[createInvite] Creating invite with token: ${token.substring(0, 8)}...`);

    const invite = await prisma.familyInvite.create({
      data: {
        familyId,
        token,
        expiresAt,
        createdBy: userId,
      },
    });

    const inviteUrl = `${env.APP_URL}/invite/${token}`;
    console.log(`[createInvite] Invite created successfully: ${inviteUrl}`);

    sendSuccess(
      res,
      {
        inviteId: invite.id,
        token: invite.token,
        inviteUrl,
        expiresAt: invite.expiresAt.toISOString(),
      },
      'Invite created successfully',
      201
    );
  } catch (error: any) {
    if (error.name === 'ZodError') {
      console.error('[createInvite] Validation error:', error.errors);
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('[createInvite] Error:', error?.message || JSON.stringify(error));
    sendError(res, 'Failed to create invite');
  }
}

export async function getInviteInfo(req: Request, res: Response): Promise<void> {
  try {
    const token = req.params.token as string;

    const invite = await prisma.familyInvite.findUnique({
      where: { token },
      include: {
        family: {
          select: {
            id: true,
            name: true,
            address: true,
            admin: {
              select: {
                id: true,
                name: true,
                avatarUrl: true,
              },
            },
          },
        },
      },
    });

    if (!invite) {
      sendError(res, 'Invalid invite token', 404);
      return;
    }

    if (invite.usedAt) {
      sendError(res, 'This invite has already been used', 400);
      return;
    }

    if (invite.expiresAt < new Date()) {
      sendError(res, 'This invite has expired', 400);
      return;
    }

    sendSuccess(res, {
      family: invite.family,
      expiresAt: invite.expiresAt.toISOString(),
    });
  } catch (error) {
    console.error('Get invite info error:', error);
    sendError(res, 'Failed to get invite info');
  }
}
