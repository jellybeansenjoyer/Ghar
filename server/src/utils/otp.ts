// In-memory OTP store (for production, use Redis)
const otpStore = new Map<string, { otp: string; expiresAt: number; attempts: number }>();

export function generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

export function storeOtp(phone: string, otp: string): void {
  otpStore.set(phone, {
    otp,
    expiresAt: Date.now() + 5 * 60 * 1000, // 5 minutes
    attempts: 0,
  });
}

export function verifyOtp(phone: string, otp: string): { valid: boolean; reason?: string } {
  const stored = otpStore.get(phone);

  if (!stored) {
    return { valid: false, reason: 'No OTP found. Please request a new one.' };
  }

  if (Date.now() > stored.expiresAt) {
    otpStore.delete(phone);
    return { valid: false, reason: 'OTP has expired. Please request a new one.' };
  }

  if (stored.attempts >= 3) {
    otpStore.delete(phone);
    return { valid: false, reason: 'Too many attempts. Please request a new OTP.' };
  }

  if (stored.otp !== otp) {
    stored.attempts++;
    return { valid: false, reason: 'Invalid OTP. Please try again.' };
  }

  otpStore.delete(phone);
  return { valid: true };
}

// Cleanup expired OTPs every 10 minutes
setInterval(() => {
  const now = Date.now();
  for (const [phone, data] of otpStore.entries()) {
    if (now > data.expiresAt) {
      otpStore.delete(phone);
    }
  }
}, 10 * 60 * 1000);
