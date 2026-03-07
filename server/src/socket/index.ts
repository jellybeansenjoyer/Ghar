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
    socket.on('join:family', (data: { familyId: string; token: string }) => {
      try {
        const payload = verifyAccessToken(data.token);
        if (payload.familyId === data.familyId) {
          socket.join(`family:${data.familyId}`);
          console.log(`👨‍👩‍👧‍👦 User ${payload.userId} joined family room: ${data.familyId}`);
        }
      } catch (error) {
        console.error('Failed to join family room:', error);
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
