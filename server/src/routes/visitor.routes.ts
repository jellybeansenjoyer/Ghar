import { Router } from 'express';
import multer from 'multer';
import {
  createVisitor,
  respondToVisitor,
  getVisitor,
  getMessages,
  sendMessage,
} from '../controllers/visitor.controller';
import { authMiddleware } from '../middleware/auth';
import { visitorLimiter } from '../middleware/rate-limiter';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
  fileFilter: (_req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, PNG, and WebP images are allowed'));
    }
  },
});

const router = Router();

// Public endpoints (visitor web form)
router.post('/', visitorLimiter, upload.single('photo'), createVisitor);
router.get('/:id', getVisitor);
router.get('/:id/messages', getMessages);
router.post('/:id/messages', sendMessage);

// Authenticated endpoints (family members)
router.post('/:id/respond', authMiddleware, respondToVisitor);

export default router;
