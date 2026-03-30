import { Server as SocketServer } from 'socket.io';
import { Server as HttpServer } from 'http';
import { verifyAccessToken } from '../utils/jwt';
import prisma from '../config/database';

let io: SocketServer;

export function initializeSocket(httpServer: HttpServer): SocketServer {
  io = new SocketServer(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  io.on('connection', (socket) => {
    console.log(`🔌 Client connected: ${socket.id}`);

    // Family member joins their family room (authenticated)
    socket.on('join:family', async (data: { familyId: string; token: string }) => {
      try {
        const payload = verifyAccessToken(data.token);
        // IMPORTANT: do not rely only on token.familyId, it may be stale
        // right after a member is added/joins a family.
        const user = await prisma.user.findUnique({
          where: { id: payload.userId },
          select: { id: true, familyId: true },
        });

        if (!user) {
          socket.emit('error', { message: 'User not found' });
          return;
        }

        if (user.familyId !== data.familyId) {
          console.error(
            `[join:family] Access denied for user ${payload.userId}. DB family: ${user.familyId}, requested: ${data.familyId}, token family: ${payload.familyId}`
          );
          socket.emit('error', { message: 'You are not a member of this family' });
          return;
        }

        const roomName = `family:${data.familyId}`;
        await socket.join(roomName);
        const socketsInRoom = await io.in(roomName).fetchSockets();
        console.log(
          `👨‍👩‍👧‍👦 User ${payload.userId} joined family room: ${data.familyId} (Total in room: ${socketsInRoom.length})`
        );
      } catch (error: any) {
        console.error('[join:family] Failed to join family room:', error?.message || error);
        socket.emit('error', { message: 'Authentication failed' });
      }
    });

    // Visitor joins their visitor-specific room (no auth needed)
    socket.on('join:visitor', (data: { visitorId: string }) => {
      socket.join(`visitor:${data.visitorId}`);
      console.log(`👤 Visitor joined room: ${data.visitorId}`);
    });

    // Leave rooms on disconnect
    socket.on('disconnect', (reason) => {
      console.log(`🔌 Client disconnected: ${socket.id} (${reason})`);
    });
  });

  return io;
}

export function getIO(): SocketServer {
  if (!io) {
    throw new Error('Socket.IO not initialized. Call initializeSocket first.');
  }
  return io;
}
