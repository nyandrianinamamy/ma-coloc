import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

export const leaveHouse = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { houseId } = request.data;

  if (!houseId || typeof houseId !== "string") {
    throw new HttpsError("invalid-argument", "House ID is required");
  }

  const db = getFirestore();
  const uid = request.auth.uid;
  const houseRef = db.collection("houses").doc(houseId);

  await db.runTransaction(async (tx) => {
    const houseDoc = await tx.get(houseRef);
    if (!houseDoc.exists) {
      throw new HttpsError("not-found", "House not found");
    }

    const data = houseDoc.data()!;
    if (!data.members.includes(uid)) {
      throw new HttpsError("permission-denied", "Not a member of this house");
    }

    // Prevent the last admin from leaving
    if (data.createdBy === uid && data.members.length > 1) {
      throw new HttpsError(
        "failed-precondition",
        "Transfer admin role before leaving"
      );
    }

    tx.update(houseRef, {
      members: FieldValue.arrayRemove(uid),
    });

    tx.delete(houseRef.collection("members").doc(uid));
  });

  return { success: true };
});
