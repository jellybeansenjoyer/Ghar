import twilio from 'twilio';
import { env } from '../config/env';
import { generateOtp, storeOtp, verifyOtp as verifyStoredOtp } from '../utils/otp';

let twilioClient: twilio.Twilio | null = null;

function getTwilioClient(): twilio.Twilio | null {
  if (!env.TWILIO_ACCOUNT_SID || !env.TWILIO_AUTH_TOKEN) {
    console.warn('⚠️ Twilio credentials not configured. OTP will be logged to console.');
    return null;
  }
  if (!twilioClient) {
    twilioClient = twilio(env.TWILIO_ACCOUNT_SID, env.TWILIO_AUTH_TOKEN);
  }
  return twilioClient;
}

export async function sendOtp(phone: string): Promise<void> {
  const otp = generateOtp();
  storeOtp(phone, otp);

  const client = getTwilioClient();
  if (client && env.TWILIO_PHONE_NUMBER) {
    await client.messages.create({
      body: `Your Ghar verification code is: ${otp}. Valid for 5 minutes.`,
      from: env.TWILIO_PHONE_NUMBER,
      to: phone,
    });
    console.log(`📱 OTP sent to ${phone}`);
  } else {
    // Development fallback: log OTP to console
    console.log(`🔑 [DEV] OTP for ${phone}: ${otp}`);
  }
}

export function verifyOtp(phone: string, otp: string): { valid: boolean; reason?: string } {
  return verifyStoredOtp(phone, otp);
}
