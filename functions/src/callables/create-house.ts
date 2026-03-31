import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { generateInviteCode } from "../utils/invite-code";

export const createHouse = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { name, displayName, timezone, rooms } = request.data;

  if (!name || typeof name !== "string" || name.trim().length === 0) {
    throw new HttpsError("invalid-argument", "House name is required");
  }
  if (!displayName || typeof displayName !== "string" || displayName.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Display name is required");
  }
  if (!timezone || typeof timezone !== "string") {
    throw new HttpsError("invalid-argument", "Timezone is required");
  }
  if (!Array.isArray(rooms) || rooms.length === 0) {
    throw new HttpsError("invalid-argument", "At least one room is required");
  }

  const db = getFirestore();
  const uid = request.auth.uid;
  const inviteCode = generateInviteCode();
  const now = Timestamp.now();

  const houseRef = db.collection("houses").doc();

  await db.runTransaction(async (tx) => {
    // Create house document
    tx.set(houseRef, {
      name: name.trim(),
      createdBy: uid,
      createdAt: now,
      inviteCode,
      members: [uid],
      rooms,
      timezone,
      lastResetDate: null,
      lastDeepCleanMonth: null,
      settings: {
        deepCleanDay: 1,
        volunteerWindowHours: 48,
        disputeWindowHours: 48,
      },
    });

    // Create member subdoc for the creator
    tx.set(houseRef.collection("members").doc(uid), {
      displayName: displayName.trim(),
      avatarUrl: request.auth!.token.picture || null,
      joinedAt: now,
      role: "admin",
      presence: "away",
      presenceUpdatedAt: now,
      stats: {
        totalPoints: 0,
        issuesCreated: 0,
        issuesResolved: 0,
        currentStreak: 0,
        longestStreak: 0,
        badges: [],
        lastRandomAssignMonth: null,
      },
    });
  });

  return { houseId: houseRef.id };
});
