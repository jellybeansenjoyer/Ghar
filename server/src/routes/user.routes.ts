import { Router } from 'express';
import { getProfile, updateProfile, updatePushToken } from '../controllers/user.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();

router.get('/me', authMiddleware, getProfile);
router.put('/me', authMiddleware, updateProfile);
router.put('/me/push-token', authMiddleware, updatePushToken);

export default router;
