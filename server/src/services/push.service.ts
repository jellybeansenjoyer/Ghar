import { env } from '../config/env';

interface PushPayload {
  playerIds: string[];
  title: string;
  message: string;
  data: Record<string, string>;
}

export async function sendPushNotification(payload: PushPayload): Promise<void> {
  if (!env.ONESIGNAL_APP_ID || !env.ONESIGNAL_REST_API_KEY) {
    console.warn('⚠️ OneSignal not configured. Push notification skipped.');
    console.log('📣 [DEV] Push notification:', JSON.stringify(payload, null, 2));
    return;
  }

  const validPlayerIds = payload.playerIds.filter((id) => id && id.length > 0);
  if (validPlayerIds.length === 0) {
    console.warn('⚠️ No valid player IDs to send push notification to.');
    return;
  }

  try {
    console.log(`[sendPushNotification] Sending to ${validPlayerIds.length} devices:`, validPlayerIds);
    
    const requestBody = {
      app_id: env.ONESIGNAL_APP_ID,
      include_player_ids: validPlayerIds,
      headings: { en: payload.title },
      contents: { en: payload.message },
      data: payload.data,
      priority: 10,
      android_channel_id: 'visitor_alerts',
      ios_sound: 'doorbell.caf',
      android_sound: 'doorbell',
      ttl: 300, // 5 minutes TTL
    };

    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${env.ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('[sendPushNotification] OneSignal API error:', error);
      console.error('[sendPushNotification] Request body:', JSON.stringify(requestBody, null, 2));
    } else {
      const result = await response.json();
      console.log(`[sendPushNotification] ✅ Push notification sent successfully to ${validPlayerIds.length} devices`);
      console.log(`[sendPushNotification] OneSignal response:`, JSON.stringify(result, null, 2));
    }
  } catch (error: any) {
    console.error('[sendPushNotification] Failed to send push notification:', error?.message || error);
  }
}
