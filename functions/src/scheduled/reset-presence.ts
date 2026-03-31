import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const resetPresence = onSchedule("every day 00:00", async () => {
  const db = getFirestore();
  const now = Timestamp.now();
  const cutoff = Timestamp.fromMillis(now.toMillis() - 24 * 60 * 60 * 1000);

  const houses = await db.collection("houses").get();

  for (const house of houses.docs) {
    const staleMembers = await db
      .collection(`houses/${house.id}/members`)
      .where("presence", "==", "home")
      .where("presenceUpdatedAt", "<=", cutoff)
      .get();

    if (staleMembers.empty) continue;

    const BATCH_LIMIT = 499;
    let batch = db.batch();
    let opCount = 0;
    for (const doc of staleMembers.docs) {
      batch.update(doc.ref, {
        presence: "away",
        presenceUpdatedAt: now,
      });
      opCount++;
      if (opCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }
    if (opCount > 0) await batch.commit();
  }
});
