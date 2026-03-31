import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { DateTime } from "luxon";
import { evaluateNewBadges, MemberStatsSnapshot } from "../badges";
import { sendNotification } from "../notifications";

export const updateStreaks = onSchedule("every day 03:00", async () => {
  const db = getFirestore();

  const houses = await db.collection("houses").get();

  for (const house of houses.docs) {
    const houseData = house.data();
    const timezone: string = houseData.timezone || "UTC";
    const now = DateTime.now().setZone(timezone);
    const today = now.toFormat("yyyy-MM-dd");

    const startOfDay = now.startOf("day");
    const endOfDay = now.endOf("day");
    const startTs = Timestamp.fromDate(startOfDay.toJSDate());
    const endTs = Timestamp.fromDate(endOfDay.toJSDate());

    const closedToday = await db
      .collection(`houses/${house.id}/issues`)
      .where("status", "==", "closed")
      .where("closedAt", ">=", startTs)
      .where("closedAt", "<=", endTs)
      .get();

    const resolversToday = new Set<string>();
    for (const doc of closedToday.docs) {
      const resolvedBy = doc.data().resolvedBy;
      if (resolvedBy) resolversToday.add(resolvedBy);
    }

    const members = await db
      .collection(`houses/${house.id}/members`)
      .get();

    const BATCH_LIMIT = 499;
    let batch = db.batch();
    let opCount = 0;

    for (const memberDoc of members.docs) {
      const data = memberDoc.data();
      const stats = data.stats || {};
      const lastStreakDate: string | null = stats.lastStreakDate || null;

      if (lastStreakDate === today) continue;

      const currentStreak: number = stats.currentStreak || 0;
      const longestStreak: number = stats.longestStreak || 0;

      if (resolversToday.has(memberDoc.id)) {
        const newStreak = currentStreak + 1;
        const newLongest = Math.max(longestStreak, newStreak);

        batch.update(memberDoc.ref, {
          "stats.currentStreak": newStreak,
          "stats.longestStreak": newLongest,
          "stats.lastStreakDate": today,
        });
        opCount++;

        const memberStats: MemberStatsSnapshot = {
          totalPoints: stats.totalPoints || 0,
          issuesResolved: stats.issuesResolved || 0,
          longestStreak: newLongest,
          deepCleanRoomsCompleted: stats.deepCleanRoomsCompleted || 0,
          badges: stats.badges || [],
        };
        const newBadges = evaluateNewBadges(memberStats);
        if (newBadges.length > 0) {
          batch.update(memberDoc.ref, {
            "stats.badges": FieldValue.arrayUnion(...newBadges),
          });
          opCount++;
        }

        // Activity + FCM for streak milestones (7, 30)
        const displayName: string = data.displayName || "Unknown";
        if (newStreak === 7 || newStreak === 30) {
          await db.collection(`houses/${house.id}/activity`).add({
            type: "streakMilestone",
            uid: memberDoc.id,
            displayName,
            detail: String(newStreak),
            createdAt: Timestamp.now(),
          });
        }

        // Activity + FCM for new badges
        for (const badgeId of newBadges) {
          await db.collection(`houses/${house.id}/activity`).add({
            type: "badgeEarned",
            uid: memberDoc.id,
            displayName,
            detail: badgeId,
            createdAt: Timestamp.now(),
          });
          await sendNotification(
            house.id,
            memberDoc.id,
            "New Badge!",
            `You earned the ${badgeId.replace(/_/g, " ")} badge!`,
          );
        }
      } else {
        if (currentStreak > 0) {
          batch.update(memberDoc.ref, {
            "stats.currentStreak": 0,
            "stats.lastStreakDate": today,
          });
          opCount++;
        }
      }

      if (opCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) await batch.commit();
  }
});
