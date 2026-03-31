import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

export const joinHouse = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { inviteCode, displayName, avatarUrl } = request.data;

  if (!inviteCode || typeof inviteCode !== "string") {
    throw new HttpsError("invalid-argument", "Invite code is required");
  }
  if (!displayName || typeof displayName !== "string") {
    throw new HttpsError("invalid-argument", "Display name is required");
  }

  const db = getFirestore();
  const uid = request.auth.uid;

  // Find house by invite code
  const housesQuery = await db
    .collection("houses")
    .where("inviteCode", "==", inviteCode.toUpperCase())
    .limit(1)
    .get();

  if (housesQuery.empty) {
    throw new HttpsError("not-found", "Invalid invite code");
  }

  const houseDoc = housesQuery.docs[0];
  const houseRef = houseDoc.ref;
  const houseData = houseDoc.data();

  // Check if already a member
  if (houseData.members.includes(uid)) {
    return { houseId: houseRef.id };
  }

  const now = Timestamp.now();

  await db.runTransaction(async (tx) => {
    // Add to members array
    tx.update(houseRef, {
      members: FieldValue.arrayUnion(uid),
    });

    // Create member subdoc
    tx.set(houseRef.collection("members").doc(uid), {
      displayName: displayName.trim(),
      avatarUrl: avatarUrl || null,
      joinedAt: now,
      role: "member",
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
