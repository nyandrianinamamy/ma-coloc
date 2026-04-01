import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const claimRoom = onCall({ invoker: "public" }, async (request) => {
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

  // Verify membership
  const house = await db.collection("houses").doc(houseId).get();
  if (!house.exists) {
    throw new HttpsError("not-found", "House not found");
  }
  const members: string[] = house.data()?.members || [];
  if (!members.includes(uid)) {
    throw new HttpsError("permission-denied", "Not a member of this house");
  }

  const cleanRef = db.collection(`houses/${houseId}/deepCleans`).doc(cleanId);

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

    if (assignments[roomName].uid !== null) {
      throw new HttpsError("already-exists", `Room "${roomName}" is already assigned`);
    }

    tx.update(cleanRef, {
      [`assignments.${roomName}.uid`]: uid,
      [`assignments.${roomName}.assignedAt`]: Timestamp.now(),
    });
  });

  return { success: true };
});
