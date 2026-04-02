import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

export const purgeArchivedIssues = onCall(
  { invoker: "public" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const { houseId, olderThanDays } = request.data;

    if (!houseId || typeof houseId !== "string") {
      throw new HttpsError("invalid-argument", "houseId is required");
    }

    if (
      olderThanDays !== undefined &&
      (typeof olderThanDays !== "number" || olderThanDays <= 0)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "olderThanDays must be a positive number"
      );
    }

    const db = getFirestore();
    const uid = request.auth.uid;
    const houseRef = db.collection("houses").doc(houseId);

    // Verify caller is an admin
    const callerMemberDoc = await houseRef.collection("members").doc(uid).get();
    if (!callerMemberDoc.exists || callerMemberDoc.data()?.role !== "admin") {
      throw new HttpsError("permission-denied", "Only admins can purge issues");
    }

    // Build query for archived issues
    let query = houseRef
      .collection("issues")
      .where("archived", "==", true) as FirebaseFirestore.Query;

    if (olderThanDays !== undefined) {
      const cutoff = Timestamp.fromMillis(
        Date.now() - olderThanDays * 24 * 60 * 60 * 1000
      );
      query = query.where("createdAt", "<", cutoff);
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      return { success: true, deletedCount: 0 };
    }

    const bucket = getStorage().bucket();
    const BATCH_SIZE = 500;
    let deletedCount = 0;

    // Process in batches of 500
    for (let i = 0; i < snapshot.docs.length; i += BATCH_SIZE) {
      const chunk = snapshot.docs.slice(i, i + BATCH_SIZE);
      const batch = db.batch();

      await Promise.all(
        chunk.map(async (doc) => {
          const issueId = doc.id;

          // Delete Storage photos — catch errors since files may not exist
          await Promise.all([
            bucket
              .deleteFiles({
                prefix: `houses/${houseId}/issues/${issueId}/`,
              })
              .catch(() => undefined),
            bucket
              .deleteFiles({
                prefix: `houses/${houseId}/resolutions/${issueId}/`,
              })
              .catch(() => undefined),
          ]);

          batch.delete(doc.ref);
        })
      );

      await batch.commit();
      deletedCount += chunk.length;
    }

    return { success: true, deletedCount };
  }
);
