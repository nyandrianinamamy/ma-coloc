import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { evaluateNewBadges, MemberStatsSnapshot } from "../badges";
import { sendNotification } from "../notifications";

const DEEP_CLEAN_ROOM_POINTS = 5;

export const completeRoom = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { houseId, cleanId, roomName } = request.data;

  if (!houseId || typeof houseId !== "string") {
    throw new HttpsError("invalid-argument", "houseId is required");
  }
  if (!cleanId || typeof cleanId !== "string") {
    throw new HttpsError("invalid-argument", "cleanId is required");
  }
  if (!roomName || typeof roomName !== "string") {
    throw new HttpsError("invalid-argument", "roomName is required");
  }

  const db = getFirestore();
  const uid = request.auth.uid;

  const house = await db.collection("houses").doc(houseId).get();
  if (!house.exists) {
    throw new HttpsError("not-found", "House not found");
  }
  const members: string[] = house.data()?.members || [];
  if (!members.includes(uid)) {
    throw new HttpsError("permission-denied", "Not a member of this house");
  }

  const cleanRef = db.collection(`houses/${houseId}/deepCleans`).doc(cleanId);
  const memberRef = db.collection(`houses/${houseId}/members`).doc(uid);

  await db.runTransaction(async (tx) => {
    const cleanDoc = await tx.get(cleanRef);
    if (!cleanDoc.exists) {
      throw new HttpsError("not-found", "Deep clean not found");
    }

    const data = cleanDoc.data()!;
    const assignments = data.assignments || {};

    if (!(roomName in assignments)) {
      throw new HttpsError("not-found", `Room "${roomName}" not found`);
    }

    if (assignments[roomName].uid !== uid) {
      throw new HttpsError("permission-denied", "Only the assigned member can complete this room");
    }

    if (assignments[roomName].completed) {
      throw new HttpsError("already-exists", "Room is already completed");
    }

    tx.update(cleanRef, {
      [`assignments.${roomName}.completed`]: true,
      [`assignments.${roomName}.completedAt`]: Timestamp.now(),
    });

    // Award points and increment deepCleanRoomsCompleted
    tx.update(memberRef, {
      "stats.totalPoints": FieldValue.increment(DEEP_CLEAN_ROOM_POINTS),
      "stats.deepCleanRoomsCompleted": FieldValue.increment(1),
    });

    // Check if ALL rooms are now completed
    const allCompleted = Object.entries(assignments).every(
      ([name, room]: [string, any]) => {
        if (name === roomName) return true;
        return room.completed === true;
      }
    );

    if (allCompleted) {
      tx.update(cleanRef, { status: "completed" });
    }
  });

  // Check if all rooms completed (re-read after transaction)
  const updatedClean = await cleanRef.get();
  if (updatedClean.data()?.status === "completed") {
    const memberSnap = await memberRef.get();
    const displayName: string = memberSnap.data()?.displayName || "Unknown";
    await db.collection(`houses/${houseId}/activity`).add({
      type: "deepCleanDone",
      uid,
      displayName,
      detail: "all_rooms",
      createdAt: Timestamp.now(),
    });
  }

  // Badge evaluation + activity writes + FCM
  const memberDoc = await memberRef.get();
  if (memberDoc.exists) {
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
      await memberRef.update({
        "stats.badges": FieldValue.arrayUnion(...newBadges),
      });

      const displayName: string = memberData.displayName || "Unknown";
      for (const badgeId of newBadges) {
        await db.collection(`houses/${houseId}/activity`).add({
          type: "badgeEarned",
          uid,
          displayName,
          detail: badgeId,
          createdAt: Timestamp.now(),
        });
        await sendNotification(
          houseId,
          uid,
          "New Badge!",
          `You earned the ${badgeId.replace(/_/g, " ")} badge!`,
        );
      }
    }
  }

  return { success: true };
});
