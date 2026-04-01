import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

export const leaveHouse = onCall({ invoker: "public" }, async (request) => {
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

  let deleteEntireHouse = false;

  await db.runTransaction(async (tx) => {
    const houseDoc = await tx.get(houseRef);
    if (!houseDoc.exists) {
      throw new HttpsError("not-found", "House not found");
    }

    const data = houseDoc.data()!;
    if (!data.members.includes(uid)) {
      throw new HttpsError("permission-denied", "Not a member of this house");
    }

    // If this is the last member, flag for full recursive cleanup
    if (data.members.length === 1) {
      deleteEntireHouse = true;
      return;
    }

    // Check if the caller is an admin
    const callerMemberDoc = await tx.get(
      houseRef.collection("members").doc(uid)
    );
    const callerRole = callerMemberDoc.data()?.role;

    if (callerRole === "admin") {
      // Count remaining admins (read all member docs in the transaction)
      const allMembersSnap = await tx.get(houseRef.collection("members"));
      const otherAdmins = allMembersSnap.docs.filter(
        (doc) => doc.id !== uid && doc.data().role === "admin"
      );

      if (otherAdmins.length === 0) {
        throw new HttpsError(
          "failed-precondition",
          "Promote another member to admin before leaving"
        );
      }
    }

    tx.update(houseRef, {
      members: FieldValue.arrayRemove(uid),
    });

    tx.delete(houseRef.collection("members").doc(uid));
  });

  // Recursive delete outside the transaction — cleans up all subcollections
  // (members, issues, deepCleans, leaderboard) along with the house doc.
  if (deleteEntireHouse) {
    await db.recursiveDelete(houseRef);
  }

  return { success: true };
});
