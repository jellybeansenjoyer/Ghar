import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import { generalLimiter } from './middleware/rate-limiter';
import { errorHandler } from './middleware/error-handler';
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import familyRoutes from './routes/family.routes';
import visitorRoutes from './routes/visitor.routes';

const app = express();

// Security middleware
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: '*', credentials: true }));
app.use(generalLimiter);

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve visitor web form static files
app.use('/visit', express.static(path.join(__dirname, '../public/visit')));

// Visitor web form route - serve index.html for /visit/:familyId
app.get('/visit/:familyId', (_req, res) => {
  res.sendFile(path.join(__dirname, '../public/visit/index.html'));
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/families', familyRoutes);
app.use('/api/visitors', visitorRoutes);

// Health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handler
app.use(errorHandler);

export default app;
