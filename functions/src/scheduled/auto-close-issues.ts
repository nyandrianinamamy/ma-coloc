import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { evaluateNewBadges, MemberStatsSnapshot } from "../badges";
import { sendNotification } from "../notifications";

export const autoCloseIssues = onSchedule("every day 02:00", async () => {
  const db = getFirestore();
  const now = Timestamp.now();

  const houses = await db.collection("houses").get();

  for (const house of houses.docs) {
    const issues = await db
      .collection(`houses/${house.id}/issues`)
      .where("status", "==", "resolved")
      .where("autoCloseAt", "<=", now)
      .get();

    if (issues.empty) continue;

    const BATCH_LIMIT = 499;
    let batch = db.batch();
    let opCount = 0;

    const resolverDeltas: Map<string, { points: number; count: number }> = new Map();
    const creatorDeltas: Map<string, number> = new Map();

    for (const doc of issues.docs) {
      const data = doc.data();
      const resolvedBy: string | null = data.resolvedBy || null;
      const createdBy: string | null = data.createdBy || null;
      const issuePoints: number = data.points || 0;

      batch.update(doc.ref, {
        status: "closed",
        closedAt: now,
      });
      opCount++;

      if (resolvedBy) {
        const existing = resolverDeltas.get(resolvedBy) || { points: 0, count: 0 };
        existing.points += issuePoints;
        existing.count += 1;
        resolverDeltas.set(resolvedBy, existing);
      }

      if (createdBy) {
        creatorDeltas.set(createdBy, (creatorDeltas.get(createdBy) || 0) + 1);
      }

      if (opCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    // Collect existing member UIDs to skip departed users
    const existingMembers = new Set<string>();
    const membersSnap = await db.collection(`houses/${house.id}/members`).get();
    for (const m of membersSnap.docs) {
      existingMembers.add(m.id);
    }

    for (const [uid, delta] of resolverDeltas) {
      if (!existingMembers.has(uid)) continue;  // skip departed members
      const memberRef = db.collection(`houses/${house.id}/members`).doc(uid);
      batch.update(memberRef, {
        "stats.totalPoints": FieldValue.increment(delta.points),
        "stats.issuesResolved": FieldValue.increment(delta.count),
      });
      opCount++;

      if (opCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    for (const [uid, count] of creatorDeltas) {
      if (!existingMembers.has(uid)) continue;  // skip departed members
      const memberRef = db.collection(`houses/${house.id}/members`).doc(uid);
      batch.update(memberRef, {
        "stats.issuesCreated": FieldValue.increment(count),
      });
      opCount++;

      if (opCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) await batch.commit();

    // Badge evaluation pass + activity writes + FCM notifications
    const affectedUids = new Set([...resolverDeltas.keys(), ...creatorDeltas.keys()]);
    for (const uid of affectedUids) {
      if (!existingMembers.has(uid)) continue;
      const memberDoc = await db
        .collection(`houses/${house.id}/members`)
        .doc(uid)
        .get();
      if (!memberDoc.exists) continue;

      const memberData = memberDoc.data()!;
      const stats: MemberStatsSnapshot = {
        totalPoints: memberData.stats?.totalPoints || 0,
        issuesResolved: memberData.stats?.issuesResolved || 0,
        longestStreak: memberData.stats?.longestStreak || 0,
        deepCleanRoomsCompleted: memberData.stats?.deepCleanRoomsCompleted || 0,
        badges: memberData.stats?.badges || [],
      };

      const newBadges = evaluateNewBadges(stats);
      if (newBadges.length > 0) {
        await memberDoc.ref.update({
          "stats.badges": FieldValue.arrayUnion(...newBadges),
        });

        const displayName: string = memberData.displayName || "Unknown";
        for (const badgeId of newBadges) {
          await db.collection(`houses/${house.id}/activity`).add({
            type: "badgeEarned",
            uid,
            displayName,
            detail: badgeId,
            createdAt: now,
          });

          await sendNotification(
            house.id,
            uid,
            "New Badge!",
            `You earned the ${badgeId.replace(/_/g, " ")} badge!`,
          );
        }
      }
    }
  }
});
