import { Server as SocketServer } from 'socket.io';
import { Server as HttpServer } from 'http';
import { verifyAccessToken } from '../utils/jwt';

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
        if (payload.familyId === data.familyId) {
          const roomName = `family:${data.familyId}`;
          await socket.join(roomName);
          const socketsInRoom = await io.in(roomName).fetchSockets();
          console.log(`👨‍👩‍👧‍👦 User ${payload.userId} joined family room: ${data.familyId} (Total in room: ${socketsInRoom.length})`);
        } else {
          console.error(`[join:family] User ${payload.userId} tried to join wrong family. Token family: ${payload.familyId}, Requested: ${data.familyId}`);
          socket.emit('error', { message: 'Family ID mismatch' });
        }
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
