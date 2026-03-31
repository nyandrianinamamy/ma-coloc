import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const autoCloseIssues = onSchedule("every day 02:00", async () => {
  const db = getFirestore();
  const now = Timestamp.now();

  // Get all houses
  const houses = await db.collection("houses").get();

  for (const house of houses.docs) {
    // Query resolved issues past their autoCloseAt
    const issues = await db
      .collection(`houses/${house.id}/issues`)
      .where("status", "==", "resolved")
      .where("autoCloseAt", "<=", now)
      .get();

    if (issues.empty) continue;

    const batch = db.batch();
    for (const issue of issues.docs) {
      batch.update(issue.ref, {
        status: "closed",
        closedAt: now,
      });
    }
    await batch.commit();
  }
});
