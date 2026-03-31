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

    const batch = db.batch();
    for (const member of staleMembers.docs) {
      batch.update(member.ref, {
        presence: "away",
        presenceUpdatedAt: now,
      });
    }
    await batch.commit();
  }
});
