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
    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${env.ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify({
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
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('OneSignal push error:', error);
    } else {
      console.log(`📣 Push notification sent to ${validPlayerIds.length} devices`);
    }
  } catch (error) {
    console.error('Failed to send push notification:', error);
  }
}
