import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

export async function sendNotification(
  houseId: string,
  targetUid: string,
  title: string,
  body: string,
): Promise<void> {
  const db = getFirestore();
  const memberDoc = await db
    .collection(`houses/${houseId}/members`)
    .doc(targetUid)
    .get();

  if (!memberDoc.exists) return;

  const data = memberDoc.data()!;
  if (data.notificationsEnabled === false) return;

  const fcmToken: string | null = data.fcmToken || null;
  if (!fcmToken) return;

  try {
    await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
    });
  } catch (err: any) {
    console.warn(`FCM send failed for ${targetUid}:`, err.code || err.message);
  }
}

export async function sendNotificationToHouse(
  houseId: string,
  title: string,
  body: string,
): Promise<void> {
  const db = getFirestore();
  const membersSnap = await db.collection(`houses/${houseId}/members`).get();

  for (const memberDoc of membersSnap.docs) {
    const data = memberDoc.data();
    if (data.notificationsEnabled === false) continue;

    const fcmToken: string | null = data.fcmToken || null;
    if (!fcmToken) continue;

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: { title, body },
      });
    } catch (err: any) {
      console.warn(`FCM send failed for ${memberDoc.id}:`, err.code || err.message);
    }
  }
}
