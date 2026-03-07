import { OAuth2Client } from 'google-auth-library';
import { env } from '../config/env';

let googleClient: OAuth2Client | null = null;

function getGoogleClient(): OAuth2Client {
  if (!googleClient) {
    googleClient = new OAuth2Client(env.GOOGLE_CLIENT_ID);
  }
  return googleClient;
}

export interface GoogleUserInfo {
  googleId: string;
  email: string;
  name: string;
  avatarUrl?: string;
}

export async function verifyGoogleToken(idToken: string): Promise<GoogleUserInfo> {
  const client = getGoogleClient();
  const ticket = await client.verifyIdToken({
    idToken,
    audience: env.GOOGLE_CLIENT_ID,
  });

  const payload = ticket.getPayload();
  if (!payload) {
    throw new Error('Invalid Google token');
  }

  return {
    googleId: payload.sub,
    email: payload.email || '',
    name: payload.name || '',
    avatarUrl: payload.picture,
  };
}
