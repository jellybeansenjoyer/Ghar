import rateLimit from 'express-rate-limit';

export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: { success: false, message: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

export const otpSendLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 3,
  message: { success: false, message: 'Too many OTP requests. Please wait 5 minutes.' },
  keyGenerator: (req) => req.body?.phone || req.ip || 'unknown',
  standardHeaders: true,
  legacyHeaders: false,
});

export const otpVerifyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  message: { success: false, message: 'Too many verification attempts. Please wait.' },
  keyGenerator: (req) => req.body?.phone || req.ip || 'unknown',
  standardHeaders: true,
  legacyHeaders: false,
});

export const visitorLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: 5,
  message: { success: false, message: 'Too many visitor requests. Please wait.' },
  keyGenerator: (req) => req.body?.familyId || req.ip || 'unknown',
  standardHeaders: true,
  legacyHeaders: false,
});
