import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, CollectionReference } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

const VALID_SCOPES = ["all", "issues", "activity", "leaderboard", "stats"] as const;
type Scope = typeof VALID_SCOPES[number];

const BATCH_LIMIT = 500;

async function deleteSubcollection(
  db: FirebaseFirestore.Firestore,
  collectionRef: CollectionReference
): Promise<void> {
  let snapshot = await collectionRef.limit(BATCH_LIMIT).get();

  while (!snapshot.empty) {
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    if (snapshot.size < BATCH_LIMIT) break;
    snapshot = await collectionRef.limit(BATCH_LIMIT).get();
  }
}

async function deleteStoragePrefix(prefix: string): Promise<void> {
  await getStorage().bucket().deleteFiles({ prefix, force: true });
}

async function resetAllMemberStats(
  db: FirebaseFirestore.Firestore,
  houseRef: FirebaseFirestore.DocumentReference
): Promise<void> {
  const membersSnap = await houseRef.collection("members").get();

  const zeroStats = {
    "stats.totalPoints": 0,
    "stats.issuesCreated": 0,
    "stats.issuesResolved": 0,
    "stats.currentStreak": 0,
    "stats.longestStreak": 0,
    "stats.badges": [],
    "stats.deepCleanRoomsCompleted": 0,
    "stats.lastStreakDate": null,
    "stats.lastRandomAssignMonth": null,
  };

  let i = 0;
  let batch = db.batch();

  for (const memberDoc of membersSnap.docs) {
    batch.update(memberDoc.ref, zeroStats);
    i++;

    if (i % BATCH_LIMIT === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }

  if (i % BATCH_LIMIT !== 0) {
    await batch.commit();
  }
}

export const resetHouseData = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { houseId, scope } = request.data;

  if (!houseId || typeof houseId !== "string") {
    throw new HttpsError("invalid-argument", "House ID is required");
  }

  if (!scope || !VALID_SCOPES.includes(scope as Scope)) {
    throw new HttpsError(
      "invalid-argument",
      `scope must be one of: ${VALID_SCOPES.join(", ")}`
    );
  }

  const db = getFirestore();
  const uid = request.auth.uid;
  const houseRef = db.collection("houses").doc(houseId);

  const memberDoc = await houseRef.collection("members").doc(uid).get();
  if (!memberDoc.exists || memberDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Must be an admin of this house");
  }

  const typedScope = scope as Scope;

  const tasks: Promise<void>[] = [];

  if (typedScope === "issues" || typedScope === "all") {
    tasks.push(deleteSubcollection(db, houseRef.collection("issues")));
    tasks.push(deleteStoragePrefix(`houses/${houseId}/issues/`));
    tasks.push(deleteStoragePrefix(`houses/${houseId}/resolutions/`));
  }

  if (typedScope === "activity" || typedScope === "all") {
    tasks.push(deleteSubcollection(db, houseRef.collection("activity")));
  }

  if (typedScope === "leaderboard" || typedScope === "all") {
    tasks.push(deleteSubcollection(db, houseRef.collection("leaderboard")));
  }

  if (typedScope === "all") {
    tasks.push(deleteSubcollection(db, houseRef.collection("deepCleans")));
  }

  if (typedScope === "stats" || typedScope === "all") {
    tasks.push(resetAllMemberStats(db, houseRef));
  }

  await Promise.all(tasks);

  return { success: true };
});
