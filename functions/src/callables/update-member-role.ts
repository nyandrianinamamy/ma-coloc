import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

export const updateMemberRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { houseId, targetUid, newRole } = request.data;

  if (!houseId || typeof houseId !== "string") {
    throw new HttpsError("invalid-argument", "houseId is required");
  }
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError("invalid-argument", "targetUid is required");
  }
  if (newRole !== "admin" && newRole !== "member") {
    throw new HttpsError("invalid-argument", "newRole must be 'admin' or 'member'");
  }

  const db = getFirestore();
  const uid = request.auth.uid;
  const houseRef = db.collection("houses").doc(houseId);

  await db.runTransaction(async (tx) => {
    const houseDoc = await tx.get(houseRef);
    if (!houseDoc.exists) {
      throw new HttpsError("not-found", "House not found");
    }

    const callerDoc = await tx.get(houseRef.collection("members").doc(uid));
    if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
      throw new HttpsError("permission-denied", "Only admins can change roles");
    }

    if (targetUid === uid) {
      throw new HttpsError("invalid-argument", "Cannot change your own role");
    }

    const targetDoc = await tx.get(houseRef.collection("members").doc(targetUid));
    if (!targetDoc.exists) {
      throw new HttpsError("not-found", "Target member not found");
    }

    if (newRole === "member" && targetDoc.data()?.role === "admin") {
      const allMembers = await tx.get(houseRef.collection("members"));
      const adminCount = allMembers.docs.filter(
        (doc) => doc.data().role === "admin"
      ).length;

      if (adminCount <= 1) {
        throw new HttpsError(
          "failed-precondition",
          "Cannot demote — house must have at least one admin"
        );
      }
    }

    tx.update(houseRef.collection("members").doc(targetUid), {
      role: newRole,
    });
  });

  return { success: true };
});
