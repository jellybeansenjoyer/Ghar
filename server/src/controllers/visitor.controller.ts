import { Request, Response } from 'express';
import prisma from '../config/database';
import { sendSuccess, sendError } from '../utils/response';
import { createVisitorSchema, respondVisitorSchema, sendMessageSchema } from '../validators/visitor.validator';
import { uploadImage } from '../services/cloudinary.service';
import { sendPushNotification } from '../services/push.service';
import { getIO } from '../socket';

export async function createVisitor(req: Request, res: Response): Promise<void> {
  try {
    const data = createVisitorSchema.parse(req.body);

    // Verify family exists
    const family = await prisma.family.findUnique({
      where: { id: data.familyId },
      select: { id: true, name: true },
    });

    if (!family) {
      sendError(res, 'Family not found', 404);
      return;
    }

    // Upload photo if provided (non-blocking — visitor is still created if upload fails)
    let photoUrl: string | null = null;
    if (req.file) {
      try {
        photoUrl = await uploadImage(req.file.buffer, 'ghar/visitors');
      } catch (uploadErr) {
        console.error('Photo upload failed, continuing without photo:', JSON.stringify(uploadErr));
      }
    }

    // Create visitor record
    const visitor = await prisma.visitor.create({
      data: {
        familyId: data.familyId,
        name: data.name,
        photoUrl,
        status: 'pending',
      },
    });

    // Get all family members' push tokens
    const members = await prisma.user.findMany({
      where: { familyId: data.familyId },
      select: { 
        onesignalPlayerId: true, 
        id: true, 
        name: true,
        phone: true,
        email: true,
      },
    });

    console.log(`[createVisitor] Family ${data.familyId} has ${members.length} members`);

    const playerIds = members
      .map((m) => m.onesignalPlayerId)
      .filter((id): id is string => !!id);

    console.log(`[createVisitor] Found ${playerIds.length} members with OneSignal player IDs out of ${members.length} total members`);
    members.forEach((m, idx) => {
      console.log(`[createVisitor] Member ${idx + 1}: ${m.name} (${m.phone || m.email || 'no contact'}) - Player ID: ${m.onesignalPlayerId || 'NOT SET'}`);
    });

    // Send push notification to ALL members
    if (playerIds.length > 0) {
      console.log(`[createVisitor] Sending push notification to ${playerIds.length} devices`);
      await sendPushNotification({
        playerIds,
        title: '🔔 Visitor at the door!',
        message: `${data.name} is at your door`,
        data: {
          type: 'visitor_arrival',
          visitorId: visitor.id,
          visitorName: data.name,
          photoUrl: photoUrl || '',
          familyId: data.familyId,
        },
      });
    } else {
      console.warn(`[createVisitor] WARNING: No OneSignal player IDs found for family ${data.familyId}. Push notifications will not be sent.`);
    }

    // Emit Socket.IO event to family room (for real-time updates)
    const io = getIO();
    const familyRoom = `family:${data.familyId}`;
    const socketsInRoom = await io.in(familyRoom).fetchSockets();
    console.log(`[createVisitor] Emitting Socket.IO event to family room "${familyRoom}" - ${socketsInRoom.length} connected sockets`);
    
    io.to(familyRoom).emit('visitor:new', {
      visitorId: visitor.id,
      name: data.name,
      photoUrl,
      arrivedAt: visitor.arrivedAt.toISOString(),
    });

    console.log(`[createVisitor] Visitor notification sent via push (${playerIds.length} devices) and Socket.IO (${socketsInRoom.length} sockets)`);

    sendSuccess(res, { visitorId: visitor.id, status: 'pending' }, 'Visitor registered', 201);
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('Create visitor error:', error?.message || JSON.stringify(error));
    sendError(res, 'Failed to register visitor');
  }
}

export async function respondToVisitor(req: Request, res: Response): Promise<void> {
  try {
    const visitorId = req.params.id as string;
    const userId = req.user!.userId;
    const { action } = respondVisitorSchema.parse(req.body);

    const visitor = await prisma.visitor.findUnique({
      where: { id: visitorId },
      include: { family: true },
    });

    if (!visitor) {
      sendError(res, 'Visitor not found', 404);
      return;
    }

    // Verify membership
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (user?.familyId !== visitor.familyId) {
      sendError(res, 'You are not a member of this family', 403);
      return;
    }

    if (visitor.status !== 'pending') {
      sendError(res, `Visitor already ${visitor.status}`, 400);
      return;
    }

    const status = action === 'accept' ? 'accepted' : 'rejected';

    const updatedVisitor = await prisma.visitor.update({
      where: { id: visitorId },
      data: {
        status,
        respondedById: userId,
        respondedAt: new Date(),
      },
    });

    const io = getIO();

    // Notify all family members to stop ringing
    io.to(`family:${visitor.familyId}`).emit('visitor:responded', {
      visitorId,
      status,
      respondedBy: user?.name || 'A family member',
    });

    // Notify visitor web form
    io.to(`visitor:${visitorId}`).emit('visitor:status', {
      status,
      respondedBy: user?.name || 'A family member',
    });

    sendSuccess(res, updatedVisitor, `Visitor ${status}`);
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('Respond to visitor error:', error);
    sendError(res, 'Failed to respond to visitor');
  }
}

export async function getVisitorHistory(req: Request, res: Response): Promise<void> {
  try {
    const familyId = req.params.id as string;
    const userId = req.user!.userId;
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const skip = (page - 1) * limit;

    // Verify membership
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (user?.familyId !== familyId) {
      sendError(res, 'You are not a member of this family', 403);
      return;
    }

    const [visitors, total] = await Promise.all([
      prisma.visitor.findMany({
        where: { familyId },
        orderBy: { arrivedAt: 'desc' },
        skip,
        take: limit,
        include: {
          respondedBy: {
            select: { name: true },
          },
        },
      }),
      prisma.visitor.count({ where: { familyId } }),
    ]);

    sendSuccess(res, {
      visitors,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error('Get visitor history error:', error);
    sendError(res, 'Failed to get visitor history');
  }
}

export async function getVisitor(req: Request, res: Response): Promise<void> {
  try {
    const id = req.params.id as string;

    const visitor = await prisma.visitor.findUnique({
      where: { id },
      include: {
        respondedBy: {
          select: { name: true },
        },
        family: {
          select: { name: true },
        },
      },
    });

    if (!visitor) {
      sendError(res, 'Visitor not found', 404);
      return;
    }

    sendSuccess(res, visitor);
  } catch (error) {
    console.error('Get visitor error:', error);
    sendError(res, 'Failed to get visitor details');
  }
}

export async function getMessages(req: Request, res: Response): Promise<void> {
  try {
    const visitorId = req.params.id as string;

    const messages = await prisma.message.findMany({
      where: { visitorId },
      orderBy: { sentAt: 'asc' },
    });

    sendSuccess(res, messages);
  } catch (error) {
    console.error('Get messages error:', error);
    sendError(res, 'Failed to get messages');
  }
}

export async function sendMessage(req: Request, res: Response): Promise<void> {
  try {
    const visitorId = req.params.id as string;
    const data = sendMessageSchema.parse(req.body);

    const visitor = await prisma.visitor.findUnique({ where: { id: visitorId } });
    if (!visitor) {
      sendError(res, 'Visitor not found', 404);
      return;
    }

    const message = await prisma.message.create({
      data: {
        visitorId,
        senderType: data.senderType,
        senderName: data.senderName,
        senderId: req.user?.userId || null,
        content: data.content,
      },
    });

    // Broadcast message via Socket.IO
    const io = getIO();
    io.to(`visitor:${visitorId}`).emit('chat:message', {
      messageId: message.id,
      content: message.content,
      senderType: message.senderType,
      senderName: message.senderName,
      sentAt: message.sentAt.toISOString(),
    });

    // Also emit to family room so other members can see
    io.to(`family:${visitor.familyId}`).emit('chat:message', {
      messageId: message.id,
      visitorId,
      content: message.content,
      senderType: message.senderType,
      senderName: message.senderName,
      sentAt: message.sentAt.toISOString(),
    });

    sendSuccess(res, message, 'Message sent', 201);
  } catch (error: any) {
    if (error.name === 'ZodError') {
      sendError(res, 'Validation error', 400, error.errors);
      return;
    }
    console.error('Send message error:', error);
    sendError(res, 'Failed to send message');
  }
}
