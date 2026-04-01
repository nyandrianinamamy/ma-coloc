import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

export const removeMember = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { houseId, targetUid } = request.data;

  if (!houseId || !targetUid) {
    throw new HttpsError("invalid-argument", "houseId and targetUid required");
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

    // Check caller is admin
    const callerMemberDoc = await tx.get(
      houseRef.collection("members").doc(uid)
    );
    if (
      !callerMemberDoc.exists ||
      callerMemberDoc.data()?.role !== "admin"
    ) {
      throw new HttpsError("permission-denied", "Only admins can remove members");
    }

    // Can't remove yourself via removeMember — use leaveHouse
    if (targetUid === uid) {
      throw new HttpsError("invalid-argument", "Use leaveHouse to remove yourself");
    }

    if (!data.members.includes(targetUid)) {
      throw new HttpsError("not-found", "Target is not a member");
    }

    tx.update(houseRef, {
      members: FieldValue.arrayRemove(targetUid),
    });

    tx.delete(houseRef.collection("members").doc(targetUid));
  });

  return { success: true };
});
