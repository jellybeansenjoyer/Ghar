import { Router } from 'express';
import {
  createFamily,
  getFamily,
  getMembers,
  addMember,
  removeMember,
  getQrCode,
  createInvite,
  getInviteInfo,
  acceptInvite,
} from '../controllers/family.controller';
import { getVisitorHistory } from '../controllers/visitor.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();

router.post('/', authMiddleware, createFamily);
router.get('/:id', authMiddleware, getFamily);
router.get('/:id/members', authMiddleware, getMembers);
router.post('/:id/members', authMiddleware, addMember);
router.delete('/:id/members/:userId', authMiddleware, removeMember);
router.get('/:id/qr', authMiddleware, getQrCode);
router.get('/:id/visitors', authMiddleware, getVisitorHistory);
router.post('/:id/invites', authMiddleware, createInvite);
router.get('/invite/:token', getInviteInfo); // Public endpoint to check invite validity
router.post('/invite/:token/accept', authMiddleware, acceptInvite); // Accept invite (auth required)

export default router;
