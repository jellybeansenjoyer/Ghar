import { Router } from 'express';
import {
  sendOtpHandler,
  verifyOtpHandler,
  googleAuthHandler,
  emailAuthHandler,
  refreshTokenHandler,
  logoutHandler,
} from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth';
import { otpSendLimiter, otpVerifyLimiter } from '../middleware/rate-limiter';

const router = Router();

router.post('/send-otp', otpSendLimiter, sendOtpHandler);
router.post('/verify-otp', otpVerifyLimiter, verifyOtpHandler);
router.post('/google', googleAuthHandler);
router.post('/email', emailAuthHandler);
router.post('/refresh', refreshTokenHandler);
router.post('/logout', authMiddleware, logoutHandler);

export default router;
