import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

export const cleanupDemoHouse = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { houseId } = request.data;
  if (!houseId || typeof houseId !== "string") {
    throw new HttpsError("invalid-argument", "houseId is required");
  }

  const db = getFirestore();
  const uid = request.auth.uid;

  const houseDoc = await db.collection("houses").doc(houseId).get();
  if (!houseDoc.exists) {
    throw new HttpsError("not-found", "House not found");
  }

  const houseData = houseDoc.data()!;
  if (!houseData.isDemo) {
    throw new HttpsError("permission-denied", "Can only clean up demo houses");
  }
  if (!houseData.members.includes(uid)) {
    throw new HttpsError("permission-denied", "Not a member of this house");
  }

  // Delete all subcollections
  const subcollections = ["members", "issues", "deepCleans", "activityEvents"];
  for (const sub of subcollections) {
    const docs = await db.collection(`houses/${houseId}/${sub}`).listDocuments();
    const batch = db.batch();
    for (const doc of docs) {
      batch.delete(doc);
    }
    await batch.commit();
  }

  // Delete house doc and sentinel
  await db.collection("houses").doc(houseId).delete();
  await db.collection("_demoLocks").doc(uid).delete();

  // Only delete the auth account if it's anonymous
  try {
    const userRecord = await getAuth().getUser(uid);
    const isAnonymous =
      userRecord.providerData.length === 0 && !userRecord.email;
    if (isAnonymous) {
      await getAuth().deleteUser(uid);
    }
  } catch {
    // User may already be deleted — ignore
  }

  return { success: true };
});
