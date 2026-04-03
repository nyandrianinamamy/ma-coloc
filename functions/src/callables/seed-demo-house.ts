import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { generateInviteCode } from "../utils/invite-code";

export const seedDemoHouse = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const db = getFirestore();
  const uid = request.auth.uid;

  // Use a transaction to atomically check for existing house and create the
  // house doc. This prevents double-tap races from creating duplicate houses.
  // We use a sentinel doc keyed by uid so the transaction has a consistent read.
  const sentinelRef = db.collection("_demoLocks").doc(uid);

  const houseId = await db.runTransaction(async (tx) => {
    // Check if user already has a house
    const existing = await tx.get(
      db.collection("houses")
        .where("members", "array-contains", uid)
        .limit(1)
    );
    if (!existing.empty) {
      return existing.docs[0].id;
    }

    // Check sentinel to prevent concurrent creation
    const sentinel = await tx.get(sentinelRef);
    if (sentinel.exists) {
      // Another call is creating — return its houseId
      return sentinel.data()!.houseId as string;
    }

    const now = Timestamp.now();
    const houseRef = db.collection("houses").doc();
    const newHouseId = houseRef.id;
    const rooms = ["Kitchen", "Living Room", "Bathroom", "Hallway", "Bedroom"];
    const inviteCode = generateInviteCode();

    // Write sentinel
    tx.set(sentinelRef, { houseId: newHouseId, createdAt: now });

    // Create house doc
    tx.set(houseRef, {
      name: "Appart Rue Exemple",
      createdBy: uid,
      createdAt: now,
      inviteCode,
      members: [uid, "demo-alex", "demo-sam", "demo-jordan"],
      rooms,
      timezone: "Europe/Paris",
      lastResetDate: null,
      lastDeepCleanMonth: null,
      isDemo: true,
      settings: {
        deepCleanDay: 1,
        volunteerWindowHours: 48,
        disputeWindowHours: 48,
      },
    });

    return newHouseId;
  });

  // Seed subcollections outside the transaction (batch write).
  // If these already exist (retry), Firestore set() is idempotent.
  const houseRef = db.collection("houses").doc(houseId);
  const now = Timestamp.now();

  const demoMembers = [
    { id: "demo-alex", name: "Alex M.", points: 145, resolved: 12, created: 8, streak: 7, longest: 14, badges: ["first_issue", "ten_resolved", "streak_7"], deepClean: 3 },
    { id: "demo-sam", name: "Sam K.", points: 98, resolved: 8, created: 5, streak: 3, longest: 5, badges: ["first_issue"], deepClean: 1 },
    { id: "demo-jordan", name: "Jordan T.", points: 67, resolved: 5, created: 6, streak: 0, longest: 2, badges: [], deepClean: 0 },
  ];

  const batch = db.batch();

  // Caller member doc
  batch.set(houseRef.collection("members").doc(uid), {
    displayName: "You",
    avatarUrl: null,
    joinedAt: now,
    role: "admin",
    presence: "home",
    presenceUpdatedAt: now,
    stats: {
      totalPoints: 25,
      issuesCreated: 3,
      issuesResolved: 2,
      currentStreak: 1,
      longestStreak: 1,
      badges: [],
      lastRandomAssignMonth: null,
      deepCleanRoomsCompleted: 0,
    },
  });

  // Demo member docs
  for (const m of demoMembers) {
    batch.set(houseRef.collection("members").doc(m.id), {
      displayName: m.name,
      avatarUrl: null,
      joinedAt: Timestamp.fromMillis(now.toMillis() - 7 * 86400000),
      role: "member",
      presence: m.id === "demo-alex" ? "home" : "away",
      presenceUpdatedAt: now,
      stats: {
        totalPoints: m.points,
        issuesCreated: m.created,
        issuesResolved: m.resolved,
        currentStreak: m.streak,
        longestStreak: m.longest,
        badges: m.badges,
        lastRandomAssignMonth: null,
        deepCleanRoomsCompleted: m.deepClean,
      },
    });
  }

  // Issues
  const issues: Array<{
    title: string;
    type: string;
    status: string;
    createdBy: string;
    assignedTo: string | null;
    resolvedBy: string | null;
    disputedBy: string | null;
    disputeAgainst: string | null;
    disputeReason: string | null;
    points: number;
  }> = [
    { title: "Dirty dishes in the sink", type: "chore", status: "open", createdBy: "demo-jordan", assignedTo: null, resolvedBy: null, disputedBy: null, disputeAgainst: null, disputeReason: null, points: 5 },
    { title: "Buy oat milk", type: "grocery", status: "open", createdBy: "demo-sam", assignedTo: null, resolvedBy: null, disputedBy: null, disputeAgainst: null, disputeReason: null, points: 3 },
    { title: "Broken bathroom handle", type: "repair", status: "in_progress", createdBy: "demo-jordan", assignedTo: "demo-alex", resolvedBy: null, disputedBy: null, disputeAgainst: null, disputeReason: null, points: 10 },
    { title: "Vacuum the living room", type: "chore", status: "resolved", createdBy: "demo-alex", assignedTo: "demo-sam", resolvedBy: "demo-sam", disputedBy: null, disputeAgainst: null, disputeReason: null, points: 5 },
    { title: "Trash bags running low", type: "grocery", status: "open", createdBy: uid, assignedTo: null, resolvedBy: null, disputedBy: null, disputeAgainst: null, disputeReason: null, points: 3 },
    { title: "Hallway light flickering", type: "repair", status: "disputed", createdBy: "demo-jordan", assignedTo: "demo-alex", resolvedBy: "demo-alex", disputedBy: "demo-jordan", disputeAgainst: "demo-alex", disputeReason: "Not actually fixed", points: 10 },
    { title: "Clean fridge", type: "chore", status: "in_progress", createdBy: "demo-sam", assignedTo: uid, resolvedBy: null, disputedBy: null, disputeAgainst: null, disputeReason: null, points: 5 },
  ];

  for (const issue of issues) {
    const issueRef = houseRef.collection("issues").doc();
    const createdAt = Timestamp.fromMillis(
      now.toMillis() - Math.floor(Math.random() * 5 * 86400000)
    );
    batch.set(issueRef, {
      type: issue.type,
      title: issue.title,
      description: null,
      photoUrl: null,
      createdBy: issue.createdBy,
      anonymous: false,
      createdAt,
      assignedTo: issue.assignedTo,
      assignedAt: issue.assignedTo ? createdAt : null,
      status: issue.status,
      resolvedBy: issue.resolvedBy,
      resolvedAt: issue.resolvedBy ? now : null,
      resolutionPhotoUrl: null,
      resolutionNote: null,
      disputedBy: issue.disputedBy,
      disputeAgainst: issue.disputeAgainst,
      disputeReason: issue.disputeReason,
      reactions: {},
      autoCloseAt: issue.status === "disputed"
        ? Timestamp.fromMillis(now.toMillis() + 48 * 3600000)
        : null,
      closedAt: null,
      tags: [],
      points: issue.points,
      archived: false,
    });
  }

  // Deep clean for current month
  const currentMonth = new Date().toISOString().slice(0, 7);
  batch.set(houseRef.collection("deepCleans").doc(currentMonth), {
    month: currentMonth,
    status: "volunteering",
    volunteerDeadline: Timestamp.fromMillis(now.toMillis() + 48 * 3600000),
    createdAt: now,
    volunteerIntents: {
      Kitchen: [{ uid: "demo-alex", volunteeredAt: now }],
      Bathroom: [{ uid: "demo-sam", volunteeredAt: now }],
    },
    assignments: {},
  });

  // Activity events
  const activities = [
    { type: "badgeEarned", uid: "demo-alex", displayName: "Alex M.", detail: "streak_7" },
    { type: "streakMilestone", uid: "demo-alex", displayName: "Alex M.", detail: "7" },
    { type: "deepCleanDone", uid: "demo-sam", displayName: "Sam K.", detail: "Kitchen" },
  ];

  for (let i = 0; i < activities.length; i++) {
    const a = activities[i];
    batch.set(houseRef.collection("activityEvents").doc(), {
      type: a.type,
      uid: a.uid,
      displayName: a.displayName,
      detail: a.detail,
      createdAt: Timestamp.fromMillis(now.toMillis() - i * 3600000),
    });
  }

  await batch.commit();

  // Clean up sentinel
  await sentinelRef.delete();

  return { houseId };
});
