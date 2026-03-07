import { createServer } from 'http';
import app from './app';
import { env } from './config/env';
import { initializeSocket, getIO } from './socket';
import cron from 'node-cron';
import prisma from './config/database';

const httpServer = createServer(app);

// Initialize Socket.IO
initializeSocket(httpServer);

// Auto-expire pending visitors every minute (5 min timeout)
cron.schedule('* * * * *', async () => {
  try {
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);

    // Find pending visitors that should be expired (so we can emit events)
    const pendingExpired = await prisma.visitor.findMany({
      where: {
        status: 'pending',
        arrivedAt: { lt: fiveMinutesAgo },
      },
      select: { id: true, familyId: true },
    });

    if (pendingExpired.length > 0) {
      // Batch update status to expired
      await prisma.visitor.updateMany({
        where: {
          id: { in: pendingExpired.map((v) => v.id) },
        },
        data: { status: 'expired' },
      });

      // Emit visitor:expired Socket.IO events to both family and visitor rooms
      const io = getIO();
      for (const visitor of pendingExpired) {
        io.to(`family:${visitor.familyId}`).emit('visitor:expired', {
          visitorId: visitor.id,
        });
        io.to(`visitor:${visitor.id}`).emit('visitor:expired', {
          visitorId: visitor.id,
        });
      }

      console.log(`⏰ Auto-expired ${pendingExpired.length} visitor(s)`);
    }
  } catch (error) {
    console.error('Visitor expiry cron error:', error);
  }
});

const PORT = parseInt(env.PORT, 10);

httpServer.listen(PORT, '0.0.0.0', () => {
  const host = env.NODE_ENV === 'production' ? env.APP_URL : `http://localhost:${PORT}`;
  console.log(`
🏠 Ghar Server is running!
📡 API: ${host}/api
🌐 Web Form: ${host}/visit/:familyId
🔌 Socket.IO: ${host}
🔧 Environment: ${env.NODE_ENV}
  `);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received. Shutting down...');
  await prisma.$disconnect();
  httpServer.close();
  process.exit(0);
});
