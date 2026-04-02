import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

export const deleteAccount = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const db = getFirestore();
  const uid = request.auth.uid;

  // Find the caller's house
  const housesSnap = await db
    .collection("houses")
    .where("members", "array-contains", uid)
    .limit(1)
    .get();

  // If no house found, just delete the auth account
  if (housesSnap.empty) {
    await getAuth().deleteUser(uid);
    return { success: true };
  }

  const houseDoc = housesSnap.docs[0];
  const houseRef = houseDoc.ref;
  const houseData = houseDoc.data();
  const members: string[] = houseData.members ?? [];

  // If caller is the last member, recursively delete the house then delete auth
  if (members.length === 1) {
    await db.recursiveDelete(houseRef);
    await getAuth().deleteUser(uid);
    return { success: true };
  }

  // Check if caller is the only admin with other members still present
  const allMembersSnap = await houseRef.collection("members").get();
  const callerMemberDoc = allMembersSnap.docs.find((doc) => doc.id === uid);
  const callerRole = callerMemberDoc?.data()?.role;

  if (callerRole === "admin") {
    const otherAdmins = allMembersSnap.docs.filter(
      (doc) => doc.id !== uid && doc.data().role === "admin"
    );
    if (otherAdmins.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "Transfer admin role to another member before deleting your account"
      );
    }
  }

  // Batch-update issues: anonymise uid references
  const issuesSnap = await houseRef.collection("issues").get();
  const BATCH_LIMIT = 500;
  const batches = [];
  let currentBatch = db.batch();
  let opCount = 0;

  for (const issueDoc of issuesSnap.docs) {
    const data = issueDoc.data();
    const updates: Record<string, unknown> = {};

    if (data.createdBy === uid) updates.createdBy = "deleted_user";
    if (data.resolvedBy === uid) updates.resolvedBy = "deleted_user";
    if (data.disputedBy === uid) updates.disputedBy = "deleted_user";
    if (data.disputeAgainst === uid) updates.disputeAgainst = "deleted_user";
    if (data.assignedTo === uid) updates.assignedTo = null;

    if (Object.keys(updates).length > 0) {
      currentBatch.update(issueDoc.ref, updates);
      opCount++;
      if (opCount >= BATCH_LIMIT) {
        batches.push(currentBatch);
        currentBatch = db.batch();
        opCount = 0;
      }
    }
  }

  // Batch-update activity events: anonymise uid references
  const activitySnap = await houseRef.collection("activity").get();

  for (const activityDoc of activitySnap.docs) {
    const data = activityDoc.data();
    if (data.uid === uid) {
      currentBatch.update(activityDoc.ref, {
        uid: "deleted_user",
        displayName: "Deleted User",
      });
      opCount++;
      if (opCount >= BATCH_LIMIT) {
        batches.push(currentBatch);
        currentBatch = db.batch();
        opCount = 0;
      }
    }
  }

  // Remove uid from house.members array and delete the member sub-document
  currentBatch.update(houseRef, {
    members: FieldValue.arrayRemove(uid),
  });
  opCount++;
  if (opCount >= BATCH_LIMIT) {
    batches.push(currentBatch);
    currentBatch = db.batch();
    opCount = 0;
  }

  currentBatch.delete(houseRef.collection("members").doc(uid));
  opCount++;

  // Always push the last batch (it has at least the member removal ops)
  batches.push(currentBatch);

  // Commit all batches
  for (const batch of batches) {
    await batch.commit();
  }

  // Delete Firebase Auth account
  await getAuth().deleteUser(uid);

  return { success: true };
});
