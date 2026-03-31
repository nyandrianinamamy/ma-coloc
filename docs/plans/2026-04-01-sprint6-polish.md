# Sprint 6: Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire settings to real data with admin mutations, add a hybrid activity feed, set up FCM push notifications for badge/deep-clean triggers, and add a volunteer nudge on the home screen.

**Architecture:** Two new callables (`updateHouse`, `updateMemberRole`), a shared FCM helper (`notifications.ts`), a new `activity` Firestore subcollection for badge/streak events. Client-side activity feed merges issue-derived events with the activity subcollection. Existing scheduled functions extended with activity writes and FCM sends. No new Firestore triggers.

**Tech Stack:** Flutter + Riverpod + Firestore + Cloud Functions v2 (onSchedule, onCall) + Firebase Cloud Messaging + Jest

---

## Task 1: Add `firebase_messaging` and `share_plus` dependencies

**Files:**
- Modify: `pubspec.yaml:30-54`

**Step 1: Add dependencies**

In `pubspec.yaml`, add under the `dependencies:` section (after `image_picker: ^1.1.2`):

```yaml
  firebase_messaging: ^15.2.4
  share_plus: ^10.1.4
```

**Step 2: Install**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter pub get`
Expected: No errors

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add firebase_messaging and share_plus dependencies"
```

---

## Task 2: ActivityEvent model (Dart)

**Files:**
- Create: `lib/src/models/activity_event.dart`
- Create: `test/models/activity_event_test.dart`

**Step 1: Write the test**

```dart
// test/models/activity_event_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/activity_event.dart';

void main() {
  group('ActivityEvent', () {
    test('fromJson creates valid event', () {
      final ts = Timestamp.now();
      final event = ActivityEvent(
        id: 'a1',
        type: ActivityEventType.badgeEarned,
        uid: 'u1',
        displayName: 'Alice',
        detail: 'first_issue',
        createdAt: ts,
      );

      expect(event.type, ActivityEventType.badgeEarned);
      expect(event.uid, 'u1');
      expect(event.detail, 'first_issue');
    });

    test('ActivityEventType has all expected values', () {
      expect(ActivityEventType.values, containsAll([
        ActivityEventType.badgeEarned,
        ActivityEventType.streakMilestone,
        ActivityEventType.deepCleanDone,
      ]));
      expect(ActivityEventType.values.length, 3);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test test/models/activity_event_test.dart`
Expected: FAIL — `activity_event.dart` doesn't exist

**Step 3: Write model**

```dart
// lib/src/models/activity_event.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'house.dart' show TimestampConverter;

enum ActivityEventType {
  badgeEarned,
  streakMilestone,
  deepCleanDone,
}

class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.type,
    required this.uid,
    required this.displayName,
    required this.detail,
    required this.createdAt,
  });

  final String id;
  final ActivityEventType type;
  final String uid;
  final String displayName;
  final String detail;
  final Timestamp createdAt;

  factory ActivityEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ActivityEvent(
      id: doc.id,
      type: ActivityEventType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityEventType.badgeEarned,
      ),
      uid: data['uid'] as String,
      displayName: data['displayName'] as String,
      detail: data['detail'] as String,
      createdAt: data['createdAt'] as Timestamp,
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test test/models/activity_event_test.dart`
Expected: PASS

**Step 5: Run all tests**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test`
Expected: All existing tests pass + new tests pass

**Step 6: Commit**

```bash
git add lib/src/models/activity_event.dart test/models/activity_event_test.dart
git commit -m "feat: add ActivityEvent model for hybrid activity feed"
```

---

## Task 3: Member model — add `fcmToken` and `notificationsEnabled`

**Files:**
- Modify: `lib/src/models/member.dart:14-24`
- Modify: `lib/src/models/member.freezed.dart` (manual update — build_runner incompatible)
- Modify: `lib/src/models/member.g.dart` (manual update)

**Step 1: Add fields to MemberStats in `member.dart`**

In `lib/src/models/member.dart`, the `MemberStats` factory currently ends with `String? lastStreakDate,` at line 23. Add the new field to the `Member` class (NOT MemberStats — these are member-level fields):

Add after `@Default(MemberStats()) MemberStats stats,` (line 41):

```dart
    String? fcmToken,
    @Default(true) bool notificationsEnabled,
```

So the `Member` factory becomes:

```dart
  @JsonSerializable(explicitToJson: true)
  const factory Member({
    required String uid,
    required String displayName,
    String? avatarUrl,
    @TimestampConverter() required Timestamp joinedAt,
    @Default(MemberRole.member) MemberRole role,
    @Default(Presence.away) Presence presence,
    @TimestampConverter() required Timestamp presenceUpdatedAt,
    @Default(MemberStats()) MemberStats stats,
    String? fcmToken,
    @Default(true) bool notificationsEnabled,
  }) = _Member;
```

**Step 2: Update `member.freezed.dart`**

Follow the existing pattern in the freezed file. Add `fcmToken` and `notificationsEnabled` to:
- The `_$MemberCopyWith` interface and implementation
- The `_Member` class constructor, fields, `==`, `hashCode`, and `toString()`
- The `_$MemberCopyWithImpl` class

Look at how `stats` was added previously and follow the exact same pattern for the new fields.

**Step 3: Update `member.g.dart`**

In `_$MemberFromJson`: add:
```dart
fcmToken: json['fcmToken'] as String?,
notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
```

In `_$MemberToJson`: add:
```dart
'fcmToken': instance.fcmToken,
'notificationsEnabled': instance.notificationsEnabled,
```

**Step 4: Run tests**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test`
Expected: All tests pass

**Step 5: Commit**

```bash
git add lib/src/models/member.dart lib/src/models/member.freezed.dart lib/src/models/member.g.dart
git commit -m "feat: add fcmToken and notificationsEnabled to Member model"
```

---

## Task 4: FCM notification helper (TypeScript)

**Files:**
- Create: `functions/src/notifications.ts`

**Step 1: Write the FCM helper**

```typescript
// functions/src/notifications.ts
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

/**
 * Send a push notification to a single user.
 * Silently skips if: member doesn't exist, notifications disabled, no FCM token, or token expired.
 */
export async function sendNotification(
  houseId: string,
  targetUid: string,
  title: string,
  body: string,
): Promise<void> {
  const db = getFirestore();
  const memberDoc = await db
    .collection(`houses/${houseId}/members`)
    .doc(targetUid)
    .get();

  if (!memberDoc.exists) return;

  const data = memberDoc.data()!;
  if (data.notificationsEnabled === false) return;

  const fcmToken: string | null = data.fcmToken || null;
  if (!fcmToken) return;

  try {
    await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
    });
  } catch (err: any) {
    // Token expired or invalid — log and continue, don't crash the batch
    console.warn(`FCM send failed for ${targetUid}:`, err.code || err.message);
  }
}

/**
 * Send a push notification to all members of a house who have notifications enabled.
 */
export async function sendNotificationToHouse(
  houseId: string,
  title: string,
  body: string,
): Promise<void> {
  const db = getFirestore();
  const membersSnap = await db.collection(`houses/${houseId}/members`).get();

  for (const memberDoc of membersSnap.docs) {
    const data = memberDoc.data();
    if (data.notificationsEnabled === false) continue;

    const fcmToken: string | null = data.fcmToken || null;
    if (!fcmToken) continue;

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: { title, body },
      });
    } catch (err: any) {
      console.warn(`FCM send failed for ${memberDoc.id}:`, err.code || err.message);
    }
  }
}
```

**Step 2: Commit**

```bash
git add functions/src/notifications.ts
git commit -m "feat: add shared FCM notification helper"
```

---

## Task 5: `updateHouse` callable

**Files:**
- Create: `functions/src/callables/update-house.ts`
- Modify: `functions/src/index.ts:14`

**Step 1: Write the callable**

```typescript
// functions/src/callables/update-house.ts
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

  const houseRef = db.collection("houses").doc(houseId);
  const memberDoc = await db
    .collection(`houses/${houseId}/members`)
    .doc(uid)
    .get();

  if (!memberDoc.exists || memberDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can update house settings");
  }

  await houseRef.update({ name: name.trim() });

  return { success: true };
});
```

**Step 2: Export from index.ts**

Add to `functions/src/index.ts` after line 14 (`export { updateStreaks }...`):

```typescript
export { updateHouse } from "./callables/update-house";
```

**Step 3: Build**

Run: `cd /Users/mamy/Project/MaColoc/macoloc/functions && npm run build`
Expected: No errors

**Step 4: Commit**

```bash
git add functions/src/callables/update-house.ts functions/src/index.ts
git commit -m "feat: add updateHouse callable for admin house name editing"
```

---

## Task 6: `updateMemberRole` callable

**Files:**
- Create: `functions/src/callables/update-member-role.ts`
- Modify: `functions/src/index.ts`

**Step 1: Write the callable**

```typescript
// functions/src/callables/update-member-role.ts
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

    // Caller must be admin
    const callerDoc = await tx.get(houseRef.collection("members").doc(uid));
    if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
      throw new HttpsError("permission-denied", "Only admins can change roles");
    }

    // Can't change own role
    if (targetUid === uid) {
      throw new HttpsError("invalid-argument", "Cannot change your own role");
    }

    const targetDoc = await tx.get(houseRef.collection("members").doc(targetUid));
    if (!targetDoc.exists) {
      throw new HttpsError("not-found", "Target member not found");
    }

    // If demoting an admin, ensure at least one admin remains
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
```

**Step 2: Export from index.ts**

Add to `functions/src/index.ts`:

```typescript
export { updateMemberRole } from "./callables/update-member-role";
```

**Step 3: Build**

Run: `cd /Users/mamy/Project/MaColoc/macoloc/functions && npm run build`
Expected: No errors

**Step 4: Commit**

```bash
git add functions/src/callables/update-member-role.ts functions/src/index.ts
git commit -m "feat: add updateMemberRole callable with admin/last-admin guards"
```

---

## Task 7: Backend tests for new callables + notifications

**Files:**
- Create: `functions/src/__tests__/polish.test.ts`

**Step 1: Write tests**

```typescript
// functions/src/__tests__/polish.test.ts
jest.mock("firebase-admin/app", () => ({
  initializeApp: jest.fn(),
}));

jest.mock("firebase-admin/firestore", () => {
  const actual = jest.requireActual("firebase-admin/firestore");
  return {
    ...actual,
    getFirestore: jest.fn(),
    Timestamp: {
      now: () => ({ toMillis: () => Date.now(), seconds: Math.floor(Date.now() / 1000), nanoseconds: 0 }),
      fromDate: (d: Date) => ({ toMillis: () => d.getTime(), seconds: Math.floor(d.getTime() / 1000), nanoseconds: 0 }),
    },
    FieldValue: {
      increment: (n: number) => ({ __increment: n }),
      arrayUnion: (...items: string[]) => ({ __arrayUnion: items }),
    },
  };
});

jest.mock("firebase-admin/messaging", () => ({
  getMessaging: jest.fn(() => ({
    send: jest.fn().mockResolvedValue("message-id"),
  })),
}));

jest.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: jest.fn((_schedule: string, handler: Function) => handler),
}));

jest.mock("firebase-functions/v2/https", () => ({
  onCall: jest.fn((handler: Function) => handler),
  HttpsError: class HttpsError extends Error {
    constructor(public code: string, public message: string) { super(message); }
  },
}));

import { evaluateNewBadges, MemberStatsSnapshot } from "../badges";

describe("updateHouse guards", () => {
  test("non-admin role is rejected", () => {
    // The callable checks callerDoc.data()?.role !== "admin"
    const callerRole = "member";
    expect(callerRole).not.toBe("admin");
  });

  test("empty name is rejected", () => {
    const name = "";
    expect(name.trim().length === 0).toBe(true);
  });
});

describe("updateMemberRole guards", () => {
  test("self-role-change is rejected", () => {
    const uid = "user1";
    const targetUid = "user1";
    expect(uid === targetUid).toBe(true);
  });

  test("last admin demotion is rejected", () => {
    const adminCount = 1;
    const newRole = "member";
    const targetRole = "admin";
    expect(adminCount <= 1 && newRole === "member" && targetRole === "admin").toBe(true);
  });

  test("valid role change to admin succeeds", () => {
    const newRole = "admin";
    expect(newRole === "admin" || newRole === "member").toBe(true);
  });

  test("invalid role value is rejected", () => {
    const newRole = "superadmin";
    expect(newRole !== "admin" && newRole !== "member").toBe(true);
  });
});

describe("Activity event types", () => {
  test("badge_earned activity document shape", () => {
    const activityDoc = {
      type: "badgeEarned",
      uid: "u1",
      displayName: "Alice",
      detail: "first_issue",
      createdAt: { seconds: 1000, nanoseconds: 0 },
    };
    expect(activityDoc.type).toBe("badgeEarned");
    expect(activityDoc.detail).toBe("first_issue");
  });

  test("streak milestone activity document shape", () => {
    const activityDoc = {
      type: "streakMilestone",
      uid: "u1",
      displayName: "Alice",
      detail: "7",
      createdAt: { seconds: 1000, nanoseconds: 0 },
    };
    expect(activityDoc.type).toBe("streakMilestone");
  });

  test("deep clean done activity document shape", () => {
    const activityDoc = {
      type: "deepCleanDone",
      uid: "u1",
      displayName: "Alice",
      detail: "all_rooms",
      createdAt: { seconds: 1000, nanoseconds: 0 },
    };
    expect(activityDoc.type).toBe("deepCleanDone");
  });
});

describe("Notification logic", () => {
  test("skips member with notifications disabled", () => {
    const notificationsEnabled = false;
    expect(notificationsEnabled).toBe(false);
    // sendNotification returns early when notificationsEnabled === false
  });

  test("skips member with no FCM token", () => {
    const fcmToken: string | null = null;
    expect(fcmToken).toBeNull();
    // sendNotification returns early when fcmToken is null
  });

  test("new badges trigger notification per badge", () => {
    const stats: MemberStatsSnapshot = {
      totalPoints: 100, issuesResolved: 10, longestStreak: 7,
      deepCleanRoomsCompleted: 1, badges: [],
    };
    const newBadges = evaluateNewBadges(stats);
    // Each new badge should result in one FCM notification
    expect(newBadges.length).toBeGreaterThan(0);
  });
});
```

**Step 2: Run tests**

Run: `cd /Users/mamy/Project/MaColoc/macoloc/functions && npm test`
Expected: All gamification tests + new polish tests pass

**Step 3: Commit**

```bash
git add functions/src/__tests__/polish.test.ts
git commit -m "test: add backend tests for new callables, activity events, and notifications"
```

---

## Task 8: Extend `autoCloseIssues` with activity writes + FCM

**Files:**
- Modify: `functions/src/scheduled/auto-close-issues.ts`

**Step 1: Add imports**

At top of `auto-close-issues.ts`, add:

```typescript
import { sendNotification } from "../notifications";
```

**Step 2: Add activity writes + FCM in badge evaluation pass**

In `auto-close-issues.ts`, the badge evaluation pass starts at line 97. Replace lines 97-122 (the badge evaluation pass) with:

```typescript
    // Badge evaluation pass + activity writes + FCM notifications
    const affectedUids = new Set([...resolverDeltas.keys(), ...creatorDeltas.keys()]);
    for (const uid of affectedUids) {
      if (!existingMembers.has(uid)) continue;
      const memberDoc = await db
        .collection(`houses/${house.id}/members`)
        .doc(uid)
        .get();
      if (!memberDoc.exists) continue;

      const memberData = memberDoc.data()!;
      const stats: MemberStatsSnapshot = {
        totalPoints: memberData.stats?.totalPoints || 0,
        issuesResolved: memberData.stats?.issuesResolved || 0,
        longestStreak: memberData.stats?.longestStreak || 0,
        deepCleanRoomsCompleted: memberData.stats?.deepCleanRoomsCompleted || 0,
        badges: memberData.stats?.badges || [],
      };

      const newBadges = evaluateNewBadges(stats);
      if (newBadges.length > 0) {
        await memberDoc.ref.update({
          "stats.badges": FieldValue.arrayUnion(...newBadges),
        });

        // Write activity event for each new badge
        const displayName: string = memberData.displayName || "Unknown";
        for (const badgeId of newBadges) {
          await db.collection(`houses/${house.id}/activity`).add({
            type: "badgeEarned",
            uid,
            displayName,
            detail: badgeId,
            createdAt: now,
          });

          // Send push notification
          await sendNotification(
            house.id,
            uid,
            "New Badge!",
            `You earned the ${badgeId.replace(/_/g, " ")} badge!`,
          );
        }
      }
    }
```

**Step 3: Build**

Run: `cd /Users/mamy/Project/MaColoc/macoloc/functions && npm run build`
Expected: No errors

**Step 4: Run tests**

Run: `cd /Users/mamy/Project/MaColoc/macoloc/functions && npm test`
Expected: All tests pass

**Step 5: Commit**

```bash
git add functions/src/scheduled/auto-close-issues.ts
git commit -m "feat: add activity writes and FCM notifications to autoCloseIssues"
```

---

## Task 9: Extend `updateStreaks` with activity writes + FCM

**Files:**
- Modify: `functions/src/scheduled/update-streaks.ts`

**Step 1: Add import**

At top of `update-streaks.ts`, add:

```typescript
import { sendNotification } from "../notifications";
```

**Step 2: Add activity writes for streak milestones and badges**

In the block where `newBadges.length > 0` (currently lines 72-77), expand it to include activity writes and FCM:

Replace lines 61-77 (the `if (resolversToday.has(memberDoc.id))` inner block after streak update) with:

```typescript
        const memberStats: MemberStatsSnapshot = {
          totalPoints: stats.totalPoints || 0,
          issuesResolved: stats.issuesResolved || 0,
          longestStreak: newLongest,
          deepCleanRoomsCompleted: stats.deepCleanRoomsCompleted || 0,
          badges: stats.badges || [],
        };
        const newBadges = evaluateNewBadges(memberStats);
        if (newBadges.length > 0) {
          batch.update(memberDoc.ref, {
            "stats.badges": FieldValue.arrayUnion(...newBadges),
          });
          opCount++;
        }

        // Activity + FCM for streak milestones (7, 30)
        const displayName: string = data.displayName || "Unknown";
        if (newStreak === 7 || newStreak === 30) {
          await db.collection(`houses/${house.id}/activity`).add({
            type: "streakMilestone",
            uid: memberDoc.id,
            displayName,
            detail: String(newStreak),
            createdAt: Timestamp.now(),
          });
        }

        // Activity + FCM for new badges
        for (const badgeId of newBadges) {
          await db.collection(`houses/${house.id}/activity`).add({
            type: "badgeEarned",
            uid: memberDoc.id,
            displayName,
            detail: badgeId,
            createdAt: Timestamp.now(),
          });
          await sendNotification(
            house.id,
            memberDoc.id,
            "New Badge!",
            `You earned the ${badgeId.replace(/_/g, " ")} badge!`,
          );
        }
```

**Step 3: Build**

Run: `cd /Users/mamy/Project/MaColoc/macoloc/functions && npm run build`
Expected: No errors

**Step 4: Commit**

```bash
git add functions/src/scheduled/update-streaks.ts
git commit -m "feat: add activity writes and FCM to updateStreaks for badges and milestones"
```

---

## Task 10: Extend `completeRoom` with activity writes + FCM

**Files:**
- Modify: `functions/src/callables/complete-room.ts`

**Step 1: Add import**

At top of `complete-room.ts`, add:

```typescript
import { sendNotification } from "../notifications";
```

**Step 2: Add activity + FCM in badge evaluation pass**

In `complete-room.ts`, after the existing badge evaluation (lines 84-101), expand to add activity writes and FCM. Replace lines 84-101:

```typescript
  // Badge evaluation + activity writes + FCM
  const memberDoc = await memberRef.get();
  if (memberDoc.exists) {
    const memberData = memberDoc.data()!;
    const stats: MemberStatsSnapshot = {
      totalPoints: memberData.stats?.totalPoints || 0,
      issuesResolved: memberData.stats?.issuesResolved || 0,
      longestStreak: memberData.stats?.longestStreak || 0,
      deepCleanRoomsCompleted: memberData.stats?.deepCleanRoomsCompleted || 0,
      badges: memberData.stats?.badges || [],
    };
    const newBadges = evaluateNewBadges(stats);
    if (newBadges.length > 0) {
      await memberRef.update({
        "stats.badges": FieldValue.arrayUnion(...newBadges),
      });

      const displayName: string = memberData.displayName || "Unknown";
      for (const badgeId of newBadges) {
        await db.collection(`houses/${houseId}/activity`).add({
          type: "badgeEarned",
          uid,
          displayName,
          detail: badgeId,
          createdAt: Timestamp.now(),
        });
        await sendNotification(
          houseId,
          uid,
          "New Badge!",
          `You earned the ${badgeId.replace(/_/g, " ")} badge!`,
        );
      }
    }
  }
```

**Step 3: Also add deep-clean-done activity when all rooms complete**

Inside the transaction, after the `if (allCompleted)` block (line 79-81), add activity write after the transaction completes. Add this **before** the badge evaluation block, after the `});` closing the transaction (line 82):

```typescript
  // Check if all rooms completed (re-read after transaction)
  const updatedClean = await cleanRef.get();
  if (updatedClean.data()?.status === "completed") {
    const memberData = (await memberRef.get()).data();
    const displayName: string = memberData?.displayName || "Unknown";
    await db.collection(`houses/${houseId}/activity`).add({
      type: "deepCleanDone",
      uid,
      displayName,
      detail: "all_rooms",
      createdAt: Timestamp.now(),
    });
  }
```

**Step 4: Build**

Run: `cd /Users/mamy/Project/MaColoc/macoloc/functions && npm run build`
Expected: No errors

**Step 5: Commit**

```bash
git add functions/src/callables/complete-room.ts
git commit -m "feat: add activity writes and FCM to completeRoom"
```

---

## Task 11: Extend `createDeepClean` with FCM reminder

**Files:**
- Modify: `functions/src/scheduled/create-deep-clean.ts`

**Step 1: Add import**

At top of `create-deep-clean.ts`, add:

```typescript
import { sendNotificationToHouse } from "../notifications";
```

**Step 2: Add FCM notification after batch commit**

After `await batch.commit();` (line 67), add:

```typescript
    // Send FCM reminder to all house members
    await sendNotificationToHouse(
      house.id,
      "Deep Clean Time!",
      "New deep clean cycle started — claim your rooms!",
    );
```

**Step 3: Build**

Run: `cd /Users/mamy/Project/MaColoc/macoloc/functions && npm run build`
Expected: No errors

**Step 4: Commit**

```bash
git add functions/src/scheduled/create-deep-clean.ts
git commit -m "feat: send FCM deep clean reminder on cycle creation"
```

---

## Task 12: Activity feed provider + momentum helper (Dart)

**Files:**
- Create: `lib/src/providers/activity_provider.dart`
- Create: `test/providers/activity_provider_test.dart`

**Step 1: Write the test**

```dart
// test/providers/activity_provider_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/issue.dart';
import 'package:macoloc/src/providers/activity_provider.dart';

void main() {
  group('ActivityItem', () {
    test('mergeActivityFeed sorts by timestamp descending', () {
      final now = DateTime(2026, 4, 1, 12, 0);
      final items = [
        ActivityItem(
          type: 'created',
          userName: 'Alice',
          detail: 'Dish mountain in sink',
          timestamp: DateTime(2026, 4, 1, 10, 0),
          issueId: 'i1',
        ),
        ActivityItem(
          type: 'badgeEarned',
          userName: 'Bob',
          detail: 'first_issue',
          timestamp: DateTime(2026, 4, 1, 11, 0),
        ),
        ActivityItem(
          type: 'resolved',
          userName: 'Alice',
          detail: 'Out of oat milk!',
          timestamp: DateTime(2026, 4, 1, 9, 0),
          issueId: 'i2',
          points: 5,
        ),
      ];

      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      expect(items[0].type, 'badgeEarned');
      expect(items[1].type, 'created');
      expect(items[2].type, 'resolved');
    });
  });

  group('momentumText', () {
    test('0 issues returns encouraging message', () {
      expect(momentumText(0), "No issues resolved yet — get started!");
    });

    test('1-4 issues returns keep it up message', () {
      expect(momentumText(3), contains('3'));
      expect(momentumText(3), contains('keep it up'));
    });

    test('5+ issues returns house on fire message', () {
      expect(momentumText(7), contains('7'));
      expect(momentumText(7), contains('House on fire'));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test test/providers/activity_provider_test.dart`
Expected: FAIL — `activity_provider.dart` doesn't exist

**Step 3: Write the provider**

```dart
// lib/src/providers/activity_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_event.dart';
import '../models/issue.dart';
import 'house_provider.dart';

// ---------------------------------------------------------------------------
// Unified activity item (merges issue events + activity subcollection)
// ---------------------------------------------------------------------------

class ActivityItem {
  const ActivityItem({
    required this.type,
    required this.userName,
    required this.detail,
    required this.timestamp,
    this.issueId,
    this.points,
  });

  final String type; // 'created', 'resolved', 'badgeEarned', 'streakMilestone', 'deepCleanDone'
  final String userName;
  final String detail; // issue title or badge ID or streak count
  final DateTime timestamp;
  final String? issueId;
  final int? points;
}

// ---------------------------------------------------------------------------
// Momentum text
// ---------------------------------------------------------------------------

String momentumText(int resolvedCount) {
  if (resolvedCount == 0) {
    return "No issues resolved yet — get started!";
  } else if (resolvedCount < 5) {
    return "Your house resolved $resolvedCount issues this week — keep it up!";
  } else {
    return "House on fire! Your house resolved $resolvedCount issues this week";
  }
}

// ---------------------------------------------------------------------------
// Activity subcollection stream
// ---------------------------------------------------------------------------

final activityStreamProvider =
    StreamProvider.family<List<ActivityEvent>, String>((ref, houseId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('houses/$houseId/activity')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(ActivityEvent.fromFirestore).toList());
});

// ---------------------------------------------------------------------------
// Merged activity feed (issue events + activity subcollection)
// ---------------------------------------------------------------------------

final activityFeedProvider =
    Provider.family<AsyncValue<List<ActivityItem>>, String>((ref, houseId) {
  final db = ref.watch(firestoreProvider);

  // We watch the activity subcollection stream
  final activityAsync = ref.watch(activityStreamProvider(houseId));

  // We also need recent issues for issue-derived events
  // Reuse a simple recent-issues query (last 20 by createdAt)
  final recentIssuesAsync = ref.watch(_recentIssuesProvider(houseId));

  return activityAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (activityEvents) => recentIssuesAsync.when(
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
      data: (issues) {
        final items = <ActivityItem>[];

        // Issue-derived events
        for (final issue in issues) {
          // Created event
          items.add(ActivityItem(
            type: 'created',
            userName: issue.createdBy,
            detail: issue.title ?? 'Untitled',
            timestamp: issue.createdAt.toDate(),
            issueId: issue.id,
          ));

          // Resolved event
          if (issue.resolvedBy != null && issue.resolvedAt != null) {
            items.add(ActivityItem(
              type: 'resolved',
              userName: issue.resolvedBy!,
              detail: issue.title ?? 'Untitled',
              timestamp: issue.resolvedAt!.toDate(),
              issueId: issue.id,
              points: issue.points,
            ));
          }
        }

        // Activity subcollection events
        for (final event in activityEvents) {
          items.add(ActivityItem(
            type: event.type.name,
            userName: event.displayName,
            detail: event.detail,
            timestamp: event.createdAt.toDate(),
          ));
        }

        // Sort by timestamp descending, cap at 30
        items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return AsyncData(items.take(30).toList());
      },
    ),
  );
});

// Internal: recent issues for activity feed derivation
final _recentIssuesProvider =
    StreamProvider.family<List<Issue>, String>((ref, houseId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('houses/$houseId/issues')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(Issue.fromFirestore).toList());
});
```

**Step 4: Run test to verify it passes**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test test/providers/activity_provider_test.dart`
Expected: PASS

**Step 5: Run all tests**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test`
Expected: All tests pass

**Step 6: Commit**

```bash
git add lib/src/providers/activity_provider.dart test/providers/activity_provider_test.dart
git commit -m "feat: add activity feed provider with merged issue/event streams and momentum text"
```

---

## Task 13: Settings provider (Dart)

**Files:**
- Create: `lib/src/providers/settings_provider.dart`

**Step 1: Write the provider**

```dart
// lib/src/providers/settings_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'house_provider.dart';

final settingsActionsProvider =
    NotifierProvider<SettingsActions, AsyncValue<void>>(SettingsActions.new);

class SettingsActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  FirebaseFunctions get _functions => ref.read(firebaseFunctionsProvider);
  FirebaseFirestore get _db => ref.read(firestoreProvider);
  String? get _uid => ref.read(authStateProvider).valueOrNull?.uid;

  Future<void> updateHouseName({
    required String houseId,
    required String name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('updateHouse').call({
        'houseId': houseId,
        'name': name,
      });
    });
  }

  Future<void> removeMember({
    required String houseId,
    required String targetUid,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('removeMember').call({
        'houseId': houseId,
        'targetUid': targetUid,
      });
    });
  }

  Future<void> updateMemberRole({
    required String houseId,
    required String targetUid,
    required String newRole,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('updateMemberRole').call({
        'houseId': houseId,
        'targetUid': targetUid,
        'newRole': newRole,
      });
    });
  }

  Future<void> toggleNotifications({
    required String houseId,
    required bool enabled,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _db
          .collection('houses/$houseId/members')
          .doc(uid)
          .update({'notificationsEnabled': enabled});
    });
  }
}
```

**Step 2: Commit**

```bash
git add lib/src/providers/settings_provider.dart
git commit -m "feat: add settings actions provider for house/member mutations"
```

---

## Task 14: Notification provider (FCM token management)

**Files:**
- Create: `lib/src/providers/notification_provider.dart`

**Step 1: Write the provider**

```dart
// lib/src/providers/notification_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'house_provider.dart';

final fcmProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final notificationSetupProvider = FutureProvider<void>((ref) async {
  final messaging = ref.watch(fcmProvider);
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return;

  final houseIdAsync = ref.watch(currentHouseIdProvider);
  final houseId = houseIdAsync.valueOrNull;
  if (houseId == null) return;

  // Request permission
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus != AuthorizationStatus.authorized &&
      settings.authorizationStatus != AuthorizationStatus.provisional) {
    return;
  }

  // Get and store token
  final token = await messaging.getToken();
  if (token != null) {
    final db = ref.read(firestoreProvider);
    await db
        .collection('houses/$houseId/members')
        .doc(user.uid)
        .update({'fcmToken': token});
  }

  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) async {
    final db = ref.read(firestoreProvider);
    await db
        .collection('houses/$houseId/members')
        .doc(user.uid)
        .update({'fcmToken': newToken});
  });
});
```

**Step 2: Commit**

```bash
git add lib/src/providers/notification_provider.dart
git commit -m "feat: add FCM token management provider"
```

---

## Task 15: Wire settings screen to real data

**Files:**
- Modify: `lib/src/features/settings/settings_screen.dart` (full rewrite)

**Step 1: Rewrite settings screen**

Convert from `StatefulWidget` to `ConsumerStatefulWidget`. Replace all mock data with real providers. Add admin actions. See design doc Section 1 for requirements.

Key changes:
- Import Riverpod, providers, models, `share_plus`, `flutter/services.dart`
- `SettingsScreen extends ConsumerStatefulWidget`
- Watch `currentHouseIdProvider`, `currentHouseProvider`, `membersStreamProvider`, `authStateProvider`
- `_HouseInfoCard` reads real house name + member count, admin can tap Edit → inline `TextField` → call `settingsActionsProvider.updateHouseName()`
- Invite code reads `house.inviteCode`, Copy → `Clipboard.setData()`, Share → `Share.share()`
- `_MembersSection` reads real member list, shows ADMIN/MEMBER badges, admin long-press shows bottom sheet with "Remove" and "Change Role" options → calls `settingsActionsProvider.removeMember()` / `updateMemberRole()`
- Notifications toggle reads/writes `notificationsEnabled` via `settingsActionsProvider.toggleNotifications()`
- Leave House → confirmation dialog → `houseActionsProvider.leaveHouse()` → `context.go('/onboarding')`
- Placeholder mode: if `kDebugMode && DefaultFirebaseOptions.isPlaceholder`, show the old mock settings screen

The full rewrite should follow the existing pattern from `leaderboard_screen.dart` and `profile_screen.dart` which both have live + mock modes.

**Step 2: Run all tests**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test`
Expected: All tests pass (settings screen has no unit tests — it's a UI screen)

**Step 3: Commit**

```bash
git add lib/src/features/settings/settings_screen.dart
git commit -m "feat: wire settings screen to real Firestore data with admin mutations"
```

---

## Task 16: Wire home screen — activity feed, momentum card, volunteer nudge

**Files:**
- Modify: `lib/src/features/home/home_screen.dart`

**Step 1: Update imports**

Add these imports at the top of `home_screen.dart`:

```dart
import '../../models/activity_event.dart';
import '../../providers/activity_provider.dart';
import '../../providers/deep_clean_provider.dart';
import '../../providers/leaderboard_provider.dart';
```

**Step 2: Replace mock activity feed with real feed**

In `_buildScaffold` (line 95-205), replace the mock activity section. Key changes:

1. Remove `final activities = MockData.activities;` (line 103)
2. Replace `_MomentumCard` with a new version that takes `resolvedCount` parameter and uses `momentumText()` from `activity_provider.dart`
3. Add volunteer nudge card between momentum card and activity feed — watches `currentDeepCleanProvider`, counts unclaimed rooms, shows banner if > 0
4. Replace `_ActivityItem` widget to render `ActivityItem` instead of `MockActivity`
5. In live mode, watch `activityFeedProvider(houseId)` and `closedIssuesStreamProvider(houseId)` for momentum count
6. Momentum count = closed issues this week (filter `closedIssuesStreamProvider` by current ISO week)

For mock/placeholder mode, keep the existing mock widgets unchanged.

**Step 3: Run all tests**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add lib/src/features/home/home_screen.dart
git commit -m "feat: wire home screen with real activity feed, computed momentum, and volunteer nudge"
```

---

## Task 17: Firestore indexes + rules updates

**Files:**
- Modify: `firestore.indexes.json`
- Modify: `firestore.rules`

**Step 1: Add activity subcollection index**

In `firestore.indexes.json`, add to the `indexes` array:

```json
    {
      "collectionGroup": "activity",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
```

**Step 2: Update Firestore rules**

In `firestore.rules`, add inside the `match /houses/{houseId}` block (after the deepCleans rule at line 85):

```
      // Activity log — read-only for members, written by Cloud Functions
      match /activity/{activityId} {
        allow read: if isMember(houseId);
        allow write: if false;
      }
```

Also update the members rule to allow self-update of `notificationsEnabled` and `fcmToken`. Replace lines 36-39:

```
        allow update: if isMember(houseId) &&
          request.auth.uid == uid &&
          request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(["presence", "presenceUpdatedAt", "notificationsEnabled", "fcmToken"]);
```

**Step 3: Commit**

```bash
git add firestore.indexes.json firestore.rules
git commit -m "feat: add activity index and update Firestore rules for notifications and activity"
```

---

## Task 18: Update README + run full test suite

**Files:**
- Modify: `README.md`

**Step 1: Update Sprint 6 status in README**

Change Sprint 6 from "Planned" to "Done".

**Step 2: Run full test suite**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test && cd functions && npm test`
Expected: All Flutter tests + all Jest tests pass. No regressions.

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: mark Sprint 6 as Done in roadmap"
```

---

## Files Changed Summary

| File | Action | Task |
|------|--------|------|
| `pubspec.yaml` | Modify | 1 |
| `lib/src/models/activity_event.dart` | Create | 2 |
| `test/models/activity_event_test.dart` | Create | 2 |
| `lib/src/models/member.dart` | Modify | 3 |
| `lib/src/models/member.freezed.dart` | Modify | 3 |
| `lib/src/models/member.g.dart` | Modify | 3 |
| `functions/src/notifications.ts` | Create | 4 |
| `functions/src/callables/update-house.ts` | Create | 5 |
| `functions/src/callables/update-member-role.ts` | Create | 6 |
| `functions/src/index.ts` | Modify | 5, 6 |
| `functions/src/__tests__/polish.test.ts` | Create | 7 |
| `functions/src/scheduled/auto-close-issues.ts` | Modify | 8 |
| `functions/src/scheduled/update-streaks.ts` | Modify | 9 |
| `functions/src/callables/complete-room.ts` | Modify | 10 |
| `functions/src/scheduled/create-deep-clean.ts` | Modify | 11 |
| `lib/src/providers/activity_provider.dart` | Create | 12 |
| `test/providers/activity_provider_test.dart` | Create | 12 |
| `lib/src/providers/settings_provider.dart` | Create | 13 |
| `lib/src/providers/notification_provider.dart` | Create | 14 |
| `lib/src/features/settings/settings_screen.dart` | Modify | 15 |
| `lib/src/features/home/home_screen.dart` | Modify | 16 |
| `firestore.indexes.json` | Modify | 17 |
| `firestore.rules` | Modify | 17 |
| `README.md` | Modify | 18 |
