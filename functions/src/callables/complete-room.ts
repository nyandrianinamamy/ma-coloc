import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

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

    // Check if ALL rooms are now completed
    const allCompleted = Object.entries(assignments).every(
      ([name, room]: [string, any]) => {
        if (name === roomName) return true; // this one is being completed now
        return room.completed === true;
      }
    );

    if (allCompleted) {
      tx.update(cleanRef, { status: "completed" });
    }
  });

  return { success: true };
});
