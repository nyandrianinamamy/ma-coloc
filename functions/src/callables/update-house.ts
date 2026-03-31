import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

export const updateHouse = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { houseId, name } = request.data;

  if (!houseId || typeof houseId !== "string") {
    throw new HttpsError("invalid-argument", "houseId is required");
  }
  if (!name || typeof name !== "string" || name.trim().length === 0) {
    throw new HttpsError("invalid-argument", "name is required and must be non-empty");
  }

  const db = getFirestore();
  const uid = request.auth.uid;

  const memberDoc = await db
    .collection(`houses/${houseId}/members`)
    .doc(uid)
    .get();

  if (!memberDoc.exists || memberDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can update house settings");
  }

  await db.collection("houses").doc(houseId).update({ name: name.trim() });

  return { success: true };
});
