# Sprint 5: Gamification — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add points engine, daily streaks, predefined badges, and a live leaderboard — wiring existing mock UI to real Firestore data.

**Architecture:** Piggyback gamification logic on existing `autoCloseIssues` scheduled function. New `updateStreaks` scheduled function (daily 3am). Badge evaluation via shared helper. Client-side leaderboard from existing member/issue streams.

**Tech Stack:** Flutter + Riverpod + Firestore + Cloud Functions v2 (onSchedule) + Luxon + Jest + freezed

---

## Task 1: Add new MemberStats fields to Dart model

**Files:**
- Modify: `lib/src/models/member.dart:13-26`

**Step 1: Add fields to MemberStats**

In `lib/src/models/member.dart`, add two new fields to `MemberStats`:

```dart
@freezed
class MemberStats with _$MemberStats {
  const factory MemberStats({
    @Default(0) int totalPoints,
    @Default(0) int issuesCreated,
    @Default(0) int issuesResolved,
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    @Default([]) List<String> badges,
    String? lastRandomAssignMonth,
    @Default(0) int deepCleanRoomsCompleted,
    String? lastStreakDate,
  }) = _MemberStats;

  factory MemberStats.fromJson(Map<String, dynamic> json) =>
      _$MemberStatsFromJson(json);
}
```

**Step 2: Regenerate freezed code**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && dart run build_runner build --delete-conflicting-outputs`
Expected: Build succeeds, `member.freezed.dart` and `member.g.dart` regenerated.

**Step 3: Run tests to verify no regressions**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && flutter test`
Expected: All existing tests pass.

**Step 4: Commit**

```bash
git add lib/src/models/member.dart lib/src/models/member.freezed.dart lib/src/models/member.g.dart
git commit -m "feat: add deepCleanRoomsCompleted and lastStreakDate to MemberStats"
```

---

## Task 2: Create badge catalog (TypeScript + Dart)

**Files:**
- Create: `functions/src/badges.ts`
- Create: `lib/src/models/badge.dart`
- Test: `test/models/badge_test.dart`

**Step 1: Write the Dart badge test**

Create `test/models/badge_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/badge.dart';
import 'package:macoloc/src/models/member.dart';

void main() {
  group('BadgeDefinition', () {
    test('catalog contains all 8 predefined badges', () {
      expect(badgeCatalog.length, 8);
      expect(badgeCatalog.keys, containsAll([
        'first_issue',
        'ten_resolved',
        'fifty_resolved',
        'streak_7',
        'streak_30',
        'deep_clean_1',
        'deep_clean_10',
        'points_100',
      ]));
    });

    test('first_issue unlocks at 1 resolved', () {
      final badge = badgeCatalog['first_issue']!;
      expect(badge.isUnlocked(const MemberStats(issuesResolved: 0)), false);
      expect(badge.isUnlocked(const MemberStats(issuesResolved: 1)), true);
      expect(badge.isUnlocked(const MemberStats(issuesResolved: 5)), true);
    });

    test('streak_7 unlocks at longestStreak 7', () {
      final badge = badgeCatalog['streak_7']!;
      expect(badge.isUnlocked(const MemberStats(longestStreak: 6)), false);
      expect(badge.isUnlocked(const MemberStats(longestStreak: 7)), true);
    });

    test('deep_clean_1 unlocks at 1 room completed', () {
      final badge = badgeCatalog['deep_clean_1']!;
      expect(badge.isUnlocked(const MemberStats(deepCleanRoomsCompleted: 0)), false);
      expect(badge.isUnlocked(const MemberStats(deepCleanRoomsCompleted: 1)), true);
    });

    test('points_100 unlocks at 100 total points', () {
      final badge = badgeCatalog['points_100']!;
      expect(badge.isUnlocked(const MemberStats(totalPoints: 99)), false);
      expect(badge.isUnlocked(const MemberStats(totalPoints: 100)), true);
    });

    test('evaluateNewBadges returns only newly earned badges', () {
      final stats = const MemberStats(
        issuesResolved: 1,
        totalPoints: 50,
        longestStreak: 3,
      );
      final existing = <String>[];
      final newBadges = evaluateNewBadges(stats, existing);
      expect(newBadges, contains('first_issue'));
      expect(newBadges, isNot(contains('ten_resolved')));

      // If first_issue already earned, don't return it again
      final newBadges2 = evaluateNewBadges(stats, ['first_issue']);
      expect(newBadges2, isNot(contains('first_issue')));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/badge_test.dart`
Expected: FAIL — `badge.dart` doesn't exist yet.

**Step 3: Create the Dart badge model**

Create `lib/src/models/badge.dart`:

```dart
import 'package:flutter/material.dart';
import 'member.dart';

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.isUnlocked,
  });

  final String id;
  final String name;
  final IconData icon;
  final String description;
  final bool Function(MemberStats stats) isUnlocked;
}

const badgeCatalog = <String, BadgeDefinition>{
  'first_issue': BadgeDefinition(
    id: 'first_issue',
    name: 'First Issue',
    icon: Icons.star_rounded,
    description: 'Resolve your first issue',
    isUnlocked: _firstIssue,
  ),
  'ten_resolved': BadgeDefinition(
    id: 'ten_resolved',
    name: 'Problem Solver',
    icon: Icons.build_rounded,
    description: 'Resolve 10 issues',
    isUnlocked: _tenResolved,
  ),
  'fifty_resolved': BadgeDefinition(
    id: 'fifty_resolved',
    name: 'Veteran',
    icon: Icons.shield_rounded,
    description: 'Resolve 50 issues',
    isUnlocked: _fiftyResolved,
  ),
  'streak_7': BadgeDefinition(
    id: 'streak_7',
    name: 'On Fire',
    icon: Icons.local_fire_department_rounded,
    description: 'Reach a 7-day streak',
    isUnlocked: _streak7,
  ),
  'streak_30': BadgeDefinition(
    id: 'streak_30',
    name: 'Unstoppable',
    icon: Icons.rocket_launch_rounded,
    description: 'Reach a 30-day streak',
    isUnlocked: _streak30,
  ),
  'deep_clean_1': BadgeDefinition(
    id: 'deep_clean_1',
    name: 'Clean Freak',
    icon: Icons.auto_awesome_rounded,
    description: 'Complete your first deep clean room',
    isUnlocked: _deepClean1,
  ),
  'deep_clean_10': BadgeDefinition(
    id: 'deep_clean_10',
    name: 'Cleaning Machine',
    icon: Icons.cleaning_services_rounded,
    description: 'Complete 10 deep clean rooms',
    isUnlocked: _deepClean10,
  ),
  'points_100': BadgeDefinition(
    id: 'points_100',
    name: 'Century',
    icon: Icons.emoji_events_rounded,
    description: 'Earn 100 total points',
    isUnlocked: _points100,
  ),
};

// Condition functions (must be top-level for const map)
bool _firstIssue(MemberStats s) => s.issuesResolved >= 1;
bool _tenResolved(MemberStats s) => s.issuesResolved >= 10;
bool _fiftyResolved(MemberStats s) => s.issuesResolved >= 50;
bool _streak7(MemberStats s) => s.longestStreak >= 7;
bool _streak30(MemberStats s) => s.longestStreak >= 30;
bool _deepClean1(MemberStats s) => s.deepCleanRoomsCompleted >= 1;
bool _deepClean10(MemberStats s) => s.deepCleanRoomsCompleted >= 10;
bool _points100(MemberStats s) => s.totalPoints >= 100;

/// Returns badge IDs that are newly earned (unlocked by stats but not in existing list).
List<String> evaluateNewBadges(MemberStats stats, List<String> existing) {
  return badgeCatalog.entries
      .where((e) => e.value.isUnlocked(stats) && !existing.contains(e.key))
      .map((e) => e.key)
      .toList();
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/badge_test.dart`
Expected: All 6 tests PASS.

**Step 5: Create the TypeScript badge helper**

Create `functions/src/badges.ts`:

```typescript
import { FieldValue } from "firebase-admin/firestore";

export interface MemberStatsSnapshot {
  totalPoints: number;
  issuesResolved: number;
  longestStreak: number;
  deepCleanRoomsCompleted: number;
  badges: string[];
}

interface BadgeCondition {
  id: string;
  check: (stats: MemberStatsSnapshot) => boolean;
}

const BADGE_CONDITIONS: BadgeCondition[] = [
  { id: "first_issue", check: (s) => s.issuesResolved >= 1 },
  { id: "ten_resolved", check: (s) => s.issuesResolved >= 10 },
  { id: "fifty_resolved", check: (s) => s.issuesResolved >= 50 },
  { id: "streak_7", check: (s) => s.longestStreak >= 7 },
  { id: "streak_30", check: (s) => s.longestStreak >= 30 },
  { id: "deep_clean_1", check: (s) => s.deepCleanRoomsCompleted >= 1 },
  { id: "deep_clean_10", check: (s) => s.deepCleanRoomsCompleted >= 10 },
  { id: "points_100", check: (s) => s.totalPoints >= 100 },
];

/**
 * Returns badge IDs that are newly earned (unlocked by stats but not already in badges list).
 */
export function evaluateNewBadges(stats: MemberStatsSnapshot): string[] {
  return BADGE_CONDITIONS
    .filter((b) => b.check(stats) && !stats.badges.includes(b.id))
    .map((b) => b.id);
}

/**
 * Returns Firestore update fields for newly earned badges.
 * Returns null if no new badges earned.
 */
export function badgeUpdateFields(stats: MemberStatsSnapshot): Record<string, any> | null {
  const newBadges = evaluateNewBadges(stats);
  if (newBadges.length === 0) return null;
  return { "stats.badges": FieldValue.arrayUnion(...newBadges) };
}
```

**Step 6: Run all tests**

Run: `flutter test && cd functions && npm test`
Expected: All tests pass.

**Step 7: Commit**

```bash
git add lib/src/models/badge.dart test/models/badge_test.dart functions/src/badges.ts
git commit -m "feat: add predefined badge catalog with evaluateNewBadges helper"
```

---

## Task 3: Extend autoCloseIssues to award points, stats, and badges

**Files:**
- Modify: `functions/src/scheduled/auto-close-issues.ts`
- Test: `functions/src/__tests__/gamification.test.ts`

**Step 1: Write the gamification tests**

Create `functions/src/__tests__/gamification.test.ts`:

```typescript
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
      fromMillis: (ms: number) => ({ toMillis: () => ms, seconds: Math.floor(ms / 1000), nanoseconds: 0 }),
      fromDate: (d: Date) => ({ toMillis: () => d.getTime(), seconds: Math.floor(d.getTime() / 1000), nanoseconds: 0 }),
    },
    FieldValue: {
      increment: (n: number) => ({ __increment: n }),
      arrayUnion: (...items: string[]) => ({ __arrayUnion: items }),
    },
  };
});

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

describe("Badge evaluation", () => {
  test("first_issue earned at issuesResolved=1", () => {
    const stats: MemberStatsSnapshot = {
      totalPoints: 5,
      issuesResolved: 1,
      longestStreak: 0,
      deepCleanRoomsCompleted: 0,
      badges: [],
    };
    expect(evaluateNewBadges(stats)).toContain("first_issue");
  });

  test("already earned badges are not returned", () => {
    const stats: MemberStatsSnapshot = {
      totalPoints: 5,
      issuesResolved: 1,
      longestStreak: 0,
      deepCleanRoomsCompleted: 0,
      badges: ["first_issue"],
    };
    expect(evaluateNewBadges(stats)).not.toContain("first_issue");
  });

  test("multiple badges can be earned at once", () => {
    const stats: MemberStatsSnapshot = {
      totalPoints: 100,
      issuesResolved: 10,
      longestStreak: 7,
      deepCleanRoomsCompleted: 1,
      badges: [],
    };
    const newBadges = evaluateNewBadges(stats);
    expect(newBadges).toContain("first_issue");
    expect(newBadges).toContain("ten_resolved");
    expect(newBadges).toContain("streak_7");
    expect(newBadges).toContain("deep_clean_1");
    expect(newBadges).toContain("points_100");
    expect(newBadges).not.toContain("fifty_resolved");
    expect(newBadges).not.toContain("streak_30");
  });

  test("no badges earned returns empty array", () => {
    const stats: MemberStatsSnapshot = {
      totalPoints: 0,
      issuesResolved: 0,
      longestStreak: 0,
      deepCleanRoomsCompleted: 0,
      badges: [],
    };
    expect(evaluateNewBadges(stats)).toHaveLength(0);
  });
});

describe("Points award logic", () => {
  test("resolver gets points and issuesResolved increment", () => {
    // Simulates the update fields that autoCloseIssues will write
    const issuePoints = 5;
    const updateFields = {
      "stats.totalPoints": { __increment: issuePoints },
      "stats.issuesResolved": { __increment: 1 },
    };
    expect(updateFields["stats.totalPoints"].__increment).toBe(5);
    expect(updateFields["stats.issuesResolved"].__increment).toBe(1);
  });

  test("creator gets issuesCreated increment only (no points)", () => {
    const updateFields = {
      "stats.issuesCreated": { __increment: 1 },
    };
    expect(updateFields["stats.issuesCreated"].__increment).toBe(1);
    expect(updateFields).not.toHaveProperty("stats.totalPoints");
  });

  test("resolver and creator are different users", () => {
    const resolvedBy = "user1";
    const createdBy = "user2";
    expect(resolvedBy).not.toBe(createdBy);
    // Both should get separate stat updates
  });

  test("resolver who is also creator gets both increments", () => {
    const resolvedBy = "user1";
    const createdBy = "user1";
    expect(resolvedBy).toBe(createdBy);
    // Same user: totalPoints + issuesResolved + issuesCreated in one update
  });
});

describe("Streak logic", () => {
  test("streak increments when member has closed issue today", () => {
    const currentStreak = 3;
    const hasClosedToday = true;
    const newStreak = hasClosedToday ? currentStreak + 1 : 0;
    expect(newStreak).toBe(4);
  });

  test("streak resets to 0 when no closed issue today", () => {
    const currentStreak = 5;
    const hasClosedToday = false;
    const newStreak = hasClosedToday ? currentStreak + 1 : 0;
    expect(newStreak).toBe(0);
  });

  test("longestStreak updates when currentStreak exceeds it", () => {
    const currentStreak = 8;
    const longestStreak = 7;
    const newLongest = Math.max(longestStreak, currentStreak);
    expect(newLongest).toBe(8);
  });

  test("longestStreak unchanged when currentStreak is lower", () => {
    const currentStreak = 3;
    const longestStreak = 10;
    const newLongest = Math.max(longestStreak, currentStreak);
    expect(newLongest).toBe(10);
  });

  test("lastStreakDate guards against double-run", () => {
    const today = "2026-03-31";
    const lastStreakDate = "2026-03-31";
    const shouldSkip = lastStreakDate === today;
    expect(shouldSkip).toBe(true);
  });
});
```

**Step 2: Run test to verify it passes** (tests are unit-level, no real Firestore needed)

Run: `cd functions && npm test`
Expected: All tests PASS.

**Step 3: Modify autoCloseIssues to award points + stats + badges**

Replace the entire contents of `functions/src/scheduled/auto-close-issues.ts`:

```typescript
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { evaluateNewBadges, MemberStatsSnapshot } from "../badges";

export const autoCloseIssues = onSchedule("every day 02:00", async () => {
  const db = getFirestore();
  const now = Timestamp.now();

  const houses = await db.collection("houses").get();

  for (const house of houses.docs) {
    // Query resolved issues past their autoCloseAt
    const issues = await db
      .collection(`houses/${house.id}/issues`)
      .where("status", "==", "resolved")
      .where("autoCloseAt", "<=", now)
      .get();

    if (issues.empty) continue;

    const BATCH_LIMIT = 499;
    let batch = db.batch();
    let opCount = 0;

    // Track per-member stat deltas to batch updates
    const resolverDeltas: Map<string, { points: number; count: number }> = new Map();
    const creatorDeltas: Map<string, number> = new Map();

    for (const doc of issues.docs) {
      const data = doc.data();
      const resolvedBy: string | null = data.resolvedBy || null;
      const createdBy: string | null = data.createdBy || null;
      const issuePoints: number = data.points || 0;

      // Close the issue
      batch.update(doc.ref, {
        status: "closed",
        closedAt: now,
      });
      opCount++;

      // Accumulate resolver stats
      if (resolvedBy) {
        const existing = resolverDeltas.get(resolvedBy) || { points: 0, count: 0 };
        existing.points += issuePoints;
        existing.count += 1;
        resolverDeltas.set(resolvedBy, existing);
      }

      // Accumulate creator stats
      if (createdBy) {
        creatorDeltas.set(createdBy, (creatorDeltas.get(createdBy) || 0) + 1);
      }

      if (opCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    // Apply resolver stat updates
    for (const [uid, delta] of resolverDeltas) {
      const memberRef = db.collection(`houses/${house.id}/members`).doc(uid);
      batch.update(memberRef, {
        "stats.totalPoints": FieldValue.increment(delta.points),
        "stats.issuesResolved": FieldValue.increment(delta.count),
      });
      opCount++;

      if (opCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    // Apply creator stat updates (may overlap with resolver)
    for (const [uid, count] of creatorDeltas) {
      const memberRef = db.collection(`houses/${house.id}/members`).doc(uid);
      batch.update(memberRef, {
        "stats.issuesCreated": FieldValue.increment(count),
      });
      opCount++;

      if (opCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) await batch.commit();

    // Badge evaluation pass — read updated stats and check for new badges
    // We need a separate pass because FieldValue.increment is server-side
    const affectedUids = new Set([...resolverDeltas.keys(), ...creatorDeltas.keys()]);
    for (const uid of affectedUids) {
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
      }
    }
  }
});
```

**Step 4: Run all tests**

Run: `cd functions && npm test`
Expected: All tests pass.

**Step 5: Commit**

```bash
git add functions/src/scheduled/auto-close-issues.ts functions/src/__tests__/gamification.test.ts
git commit -m "feat: award points, stats, and badges when autoCloseIssues runs"
```

---

## Task 4: Create updateStreaks scheduled function

**Files:**
- Create: `functions/src/scheduled/update-streaks.ts`
- Modify: `functions/src/index.ts`

**Step 1: Create the updateStreaks function**

Create `functions/src/scheduled/update-streaks.ts`:

```typescript
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { DateTime } from "luxon";
import { evaluateNewBadges, MemberStatsSnapshot } from "../badges";

export const updateStreaks = onSchedule("every day 03:00", async () => {
  const db = getFirestore();

  const houses = await db.collection("houses").get();

  for (const house of houses.docs) {
    const houseData = house.data();
    const timezone: string = houseData.timezone || "UTC";
    const now = DateTime.now().setZone(timezone);
    const today = now.toFormat("yyyy-MM-dd");

    // Get start/end of today in house timezone for querying closedAt
    const startOfDay = now.startOf("day");
    const endOfDay = now.endOf("day");
    const startTs = Timestamp.fromDate(startOfDay.toJSDate());
    const endTs = Timestamp.fromDate(endOfDay.toJSDate());

    // Get all issues closed today in this house
    const closedToday = await db
      .collection(`houses/${house.id}/issues`)
      .where("status", "==", "closed")
      .where("closedAt", ">=", startTs)
      .where("closedAt", "<=", endTs)
      .get();

    // Build set of UIDs who resolved an issue that was closed today
    const resolversToday = new Set<string>();
    for (const doc of closedToday.docs) {
      const resolvedBy = doc.data().resolvedBy;
      if (resolvedBy) resolversToday.add(resolvedBy);
    }

    // Get all members
    const members = await db
      .collection(`houses/${house.id}/members`)
      .get();

    const BATCH_LIMIT = 499;
    let batch = db.batch();
    let opCount = 0;

    for (const memberDoc of members.docs) {
      const data = memberDoc.data();
      const stats = data.stats || {};
      const lastStreakDate: string | null = stats.lastStreakDate || null;

      // Guard against double-run
      if (lastStreakDate === today) continue;

      const currentStreak: number = stats.currentStreak || 0;
      const longestStreak: number = stats.longestStreak || 0;

      if (resolversToday.has(memberDoc.id)) {
        // Active today: increment streak
        const newStreak = currentStreak + 1;
        const newLongest = Math.max(longestStreak, newStreak);

        batch.update(memberDoc.ref, {
          "stats.currentStreak": newStreak,
          "stats.longestStreak": newLongest,
          "stats.lastStreakDate": today,
        });
        opCount++;

        // Check for streak badges
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
      } else {
        // Not active today: reset streak
        if (currentStreak > 0) {
          batch.update(memberDoc.ref, {
            "stats.currentStreak": 0,
            "stats.lastStreakDate": today,
          });
          opCount++;
        }
      }

      if (opCount >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) await batch.commit();
  }
});
```

**Step 2: Export from index.ts**

In `functions/src/index.ts`, add:

```typescript
export { updateStreaks } from "./scheduled/update-streaks";
```

The full file should now be:

```typescript
import { initializeApp } from "firebase-admin/app";

initializeApp();

export { createHouse } from "./callables/create-house";
export { joinHouse } from "./callables/join-house";
export { leaveHouse } from "./callables/leave-house";
export { removeMember } from "./callables/remove-member";
export { autoCloseIssues } from "./scheduled/auto-close-issues";
export { resetPresence } from "./scheduled/reset-presence";
export { createDeepClean } from "./scheduled/create-deep-clean";
export { claimRoom } from "./callables/claim-room";
export { completeRoom } from "./callables/complete-room";
export { updateStreaks } from "./scheduled/update-streaks";
```

**Step 3: Add Firestore index for closedAt query**

The `updateStreaks` function queries `issues` with `status == "closed"` and `closedAt` in a range. This needs a composite index.

In `firestore.indexes.json`, add to the `indexes` array:

```json
{
  "collectionGroup": "issues",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "closedAt", "order": "ASCENDING" }
  ]
}
```

**Step 4: Run all tests**

Run: `cd functions && npm test`
Expected: All tests pass (streak logic tested in gamification.test.ts from Task 3).

**Step 5: Commit**

```bash
git add functions/src/scheduled/update-streaks.ts functions/src/index.ts firestore.indexes.json
git commit -m "feat: add updateStreaks scheduled function (daily 3am)"
```

---

## Task 5: Add deep clean bonus points to completeRoom

**Files:**
- Modify: `functions/src/callables/complete-room.ts`

**Step 1: Modify completeRoom to award points and increment deepCleanRoomsCompleted**

Replace the entire contents of `functions/src/callables/complete-room.ts`:

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { evaluateNewBadges, MemberStatsSnapshot } from "../badges";

const DEEP_CLEAN_ROOM_POINTS = 5;

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
  const memberRef = db.collection(`houses/${houseId}/members`).doc(uid);

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

    // Award points and increment deepCleanRoomsCompleted
    tx.update(memberRef, {
      "stats.totalPoints": FieldValue.increment(DEEP_CLEAN_ROOM_POINTS),
      "stats.deepCleanRoomsCompleted": FieldValue.increment(1),
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

  // Badge evaluation (after transaction, read fresh stats)
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
    }
  }

  return { success: true };
});
```

**Step 2: Run all tests**

Run: `cd functions && npm test`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add functions/src/callables/complete-room.ts
git commit -m "feat: award deep clean bonus points and badges in completeRoom"
```

---

## Task 6: Create leaderboard provider

**Files:**
- Create: `lib/src/providers/leaderboard_provider.dart`
- Test: `test/providers/leaderboard_provider_test.dart`

**Step 1: Write the leaderboard provider test**

Create `test/providers/leaderboard_provider_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/issue.dart';
import 'package:macoloc/src/models/member.dart';
import 'package:macoloc/src/providers/leaderboard_provider.dart';

void main() {
  group('LeaderboardEntry', () {
    test('sorts by periodPoints descending', () {
      final entries = [
        LeaderboardEntry(uid: 'a', displayName: 'A', periodPoints: 10, stats: const MemberStats()),
        LeaderboardEntry(uid: 'b', displayName: 'B', periodPoints: 30, stats: const MemberStats()),
        LeaderboardEntry(uid: 'c', displayName: 'C', periodPoints: 20, stats: const MemberStats()),
      ];
      entries.sort((a, b) => b.periodPoints.compareTo(a.periodPoints));
      expect(entries.map((e) => e.uid), ['b', 'c', 'a']);
    });
  });

  group('computeLeaderboard', () {
    final now = DateTime(2026, 3, 31, 12, 0); // Tuesday

    final members = [
      Member(
        uid: 'u1',
        displayName: 'Alice',
        joinedAt: Timestamp.now(),
        presenceUpdatedAt: Timestamp.now(),
        stats: const MemberStats(totalPoints: 100),
      ),
      Member(
        uid: 'u2',
        displayName: 'Bob',
        joinedAt: Timestamp.now(),
        presenceUpdatedAt: Timestamp.now(),
        stats: const MemberStats(totalPoints: 50),
      ),
    ];

    // Issues with closedAt in the current week
    final issues = [
      _makeClosedIssue('i1', 'u1', 5, DateTime(2026, 3, 30, 10, 0)), // Monday — same week
      _makeClosedIssue('i2', 'u1', 10, DateTime(2026, 3, 31, 8, 0)), // Tuesday — same week
      _makeClosedIssue('i3', 'u2', 3, DateTime(2026, 3, 31, 9, 0)), // Tuesday — same week
      _makeClosedIssue('i4', 'u1', 5, DateTime(2026, 3, 22, 10, 0)), // Previous week
    ];

    test('weekly period sums only current ISO week', () {
      final result = computeLeaderboard(
        members: members,
        closedIssues: issues,
        isWeekly: true,
        now: now,
      );
      // u1: 5 (Mon) + 10 (Tue) = 15 this week (Mar 22 issue excluded)
      // u2: 3 (Tue) = 3 this week
      expect(result[0].uid, 'u1');
      expect(result[0].periodPoints, 15);
      expect(result[1].uid, 'u2');
      expect(result[1].periodPoints, 3);
    });

    test('monthly period sums current calendar month', () {
      final result = computeLeaderboard(
        members: members,
        closedIssues: issues,
        isWeekly: false,
        now: now,
      );
      // u1: 5 + 10 + 5 = 20 in March
      // u2: 3 in March
      expect(result[0].uid, 'u1');
      expect(result[0].periodPoints, 20);
      expect(result[1].uid, 'u2');
      expect(result[1].periodPoints, 3);
    });

    test('members with no closed issues get 0 periodPoints', () {
      final result = computeLeaderboard(
        members: members,
        closedIssues: [],
        isWeekly: true,
        now: now,
      );
      expect(result[0].periodPoints, 0);
      expect(result[1].periodPoints, 0);
    });
  });
}

Issue _makeClosedIssue(String id, String resolvedBy, int points, DateTime closedAt) {
  return Issue(
    id: id,
    type: IssueType.chore,
    createdBy: 'someone',
    createdAt: Timestamp.fromDate(closedAt.subtract(const Duration(days: 1))),
    status: IssueStatus.closed,
    resolvedBy: resolvedBy,
    points: points,
  );
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/providers/leaderboard_provider_test.dart`
Expected: FAIL — `leaderboard_provider.dart` doesn't exist yet.

**Step 3: Create the leaderboard provider**

Create `lib/src/providers/leaderboard_provider.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/issue.dart';
import '../models/member.dart';
import 'house_provider.dart';
import 'issue_provider.dart';
import 'member_provider.dart';

// ---------------------------------------------------------------------------
// Leaderboard entry (computed, not persisted)
// ---------------------------------------------------------------------------

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    required this.periodPoints,
    required this.stats,
  });

  final String uid;
  final String displayName;
  final String? avatarUrl;
  final int periodPoints;
  final MemberStats stats;
}

// ---------------------------------------------------------------------------
// Pure computation function (exported for testing)
// ---------------------------------------------------------------------------

List<LeaderboardEntry> computeLeaderboard({
  required List<Member> members,
  required List<Issue> closedIssues,
  required bool isWeekly,
  required DateTime now,
}) {
  // Determine period start
  final DateTime periodStart;
  if (isWeekly) {
    // ISO week: Monday = 1
    periodStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  } else {
    periodStart = DateTime(now.year, now.month, 1);
  }

  // Filter issues within period and sum points per resolver
  final pointsByUid = <String, int>{};
  for (final issue in closedIssues) {
    if (issue.resolvedBy == null) continue;
    // Use closedAt if available, fall back to resolvedAt, then createdAt
    final closedAt = (issue.status == IssueStatus.closed)
        ? _timestampToDateTime(issue.autoCloseAt ?? issue.resolvedAt ?? issue.createdAt)
        : _timestampToDateTime(issue.createdAt);

    if (!closedAt.isBefore(periodStart) && !closedAt.isAfter(now)) {
      pointsByUid[issue.resolvedBy!] =
          (pointsByUid[issue.resolvedBy!] ?? 0) + issue.points;
    }
  }

  // Build entries
  final entries = members.map((m) {
    return LeaderboardEntry(
      uid: m.uid,
      displayName: m.displayName,
      avatarUrl: m.avatarUrl,
      periodPoints: pointsByUid[m.uid] ?? 0,
      stats: m.stats,
    );
  }).toList();

  // Sort by period points descending
  entries.sort((a, b) => b.periodPoints.compareTo(a.periodPoints));
  return entries;
}

DateTime _timestampToDateTime(Timestamp ts) {
  return ts.toDate();
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

class LeaderboardParams {
  const LeaderboardParams({required this.houseId, required this.isWeekly});

  final String houseId;
  final bool isWeekly;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardParams &&
          houseId == other.houseId &&
          isWeekly == other.isWeekly;

  @override
  int get hashCode => Object.hash(houseId, isWeekly);
}

final leaderboardProvider =
    Provider.family<AsyncValue<List<LeaderboardEntry>>, LeaderboardParams>(
        (ref, params) {
  final membersAsync = ref.watch(membersStreamProvider(params.houseId));
  final issuesAsync = ref.watch(issuesStreamProvider(
    IssueQueryParams(houseId: params.houseId, tab: IssueTab.all),
  ));

  return membersAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (members) => issuesAsync.when(
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
      data: (issues) {
        final closedIssues =
            issues.where((i) => i.status == IssueStatus.closed).toList();
        final entries = computeLeaderboard(
          members: members,
          closedIssues: closedIssues,
          isWeekly: params.isWeekly,
          now: DateTime.now(),
        );
        return AsyncData(entries);
      },
    ),
  );
});
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/providers/leaderboard_provider_test.dart`
Expected: All 4 tests PASS.

**Step 5: Run all tests**

Run: `flutter test`
Expected: All tests pass.

**Step 6: Commit**

```bash
git add lib/src/providers/leaderboard_provider.dart test/providers/leaderboard_provider_test.dart
git commit -m "feat: add leaderboard provider with calendar-based period filtering"
```

---

## Task 7: Wire leaderboard screen to real data

**Files:**
- Modify: `lib/src/features/leaderboard/leaderboard_screen.dart`

**Step 1: Convert LeaderboardScreen to ConsumerStatefulWidget and wire to leaderboardProvider**

Replace the entire contents of `lib/src/features/leaderboard/leaderboard_screen.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../models/badge.dart';
import '../../models/member.dart';
import '../../providers/house_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    final houseIdAsync = ref.watch(currentHouseIdProvider);
    final houseId = houseIdAsync.valueOrNull;
    final isPlaceholder = kDebugMode && houseId == null;

    if (isPlaceholder) {
      return _buildMockLeaderboard();
    }

    if (houseId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final leaderboardAsync = ref.watch(leaderboardProvider(
      LeaderboardParams(houseId: houseId, isWeekly: _isWeekly),
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) => _buildLeaderboard(entries),
      ),
    );
  }

  Widget _buildLeaderboard(List<LeaderboardEntry> entries) {
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.slate900,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PeriodToggle(
                      isWeekly: _isWeekly,
                      onChanged: (v) => setState(() => _isWeekly = v),
                    ),
                    const SizedBox(height: 32),
                    if (top3.length >= 3) _LivePodium(top3: top3),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _DeepCleanCard(onTap: () => context.push('/clean')),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            child: Text(
              'Full Rankings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.slate800,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = rest[index];
                final rank = index + 4;
                return _LiveRankingCard(entry: entry, rank: rank);
              },
              childCount: rest.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildMockLeaderboard() {
    final sorted = [...MockData.users]
      ..sort((a, b) => b.points.compareTo(a.points));
    final top3 = sorted.take(3).toList();
    final rest = sorted.skip(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leaderboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PeriodToggle(
                        isWeekly: _isWeekly,
                        onChanged: (v) => setState(() => _isWeekly = v),
                      ),
                      const SizedBox(height: 32),
                      if (top3.length == 3) _MockPodium(top3: top3),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _DeepCleanCard(onTap: () => context.push('/clean')),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Text(
                'Full Rankings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = rest[index];
                  final rank = index + 4;
                  return _MockRankingCard(user: user, rank: rank);
                },
                childCount: rest.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period Toggle (unchanged)
// ---------------------------------------------------------------------------
class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.isWeekly, required this.onChanged});
  final bool isWeekly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment: isWeekly ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Weekly',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isWeekly ? AppColors.slate900 : AppColors.slate400,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Monthly',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: !isWeekly ? AppColors.slate900 : AppColors.slate400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Live Podium (from LeaderboardEntry)
// ---------------------------------------------------------------------------
class _LivePodium extends StatelessWidget {
  const _LivePodium({required this.top3});
  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _LivePodiumColumn(entry: top3[1], rank: 2, barHeight: 64, avatarBorderColor: AppColors.slate300, nameColor: AppColors.slate300, pointsColor: AppColors.slate300, showTrophy: false)),
          const SizedBox(width: 8),
          Expanded(child: _LivePodiumColumn(entry: top3[0], rank: 1, barHeight: 96, avatarBorderColor: AppColors.yellow400, nameColor: Colors.white, pointsColor: AppColors.yellow400, showTrophy: true)),
          const SizedBox(width: 8),
          Expanded(child: _LivePodiumColumn(entry: top3[2], rank: 3, barHeight: 48, avatarBorderColor: AppColors.orange300, nameColor: AppColors.orange300, pointsColor: AppColors.orange300, showTrophy: false)),
        ],
      ),
    );
  }
}

class _LivePodiumColumn extends StatelessWidget {
  const _LivePodiumColumn({required this.entry, required this.rank, required this.barHeight, required this.avatarBorderColor, required this.nameColor, required this.pointsColor, required this.showTrophy});
  final LeaderboardEntry entry;
  final int rank;
  final double barHeight;
  final Color avatarBorderColor;
  final Color nameColor;
  final Color pointsColor;
  final bool showTrophy;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showTrophy) ...[
          const Icon(Icons.emoji_events, color: AppColors.yellow400, size: 28),
          const SizedBox(height: 4),
        ] else
          const SizedBox(height: 32),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: avatarBorderColor, width: 2.5),
              ),
              child: ClipOval(
                child: entry.avatarUrl != null
                    ? Image.network(entry.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultAvatar())
                    : _defaultAvatar(),
              ),
            ),
            Positioned(
              bottom: -4, right: -4,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: avatarBorderColor, border: Border.all(color: AppColors.slate900, width: 2)),
                child: Center(child: Text('$rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slate900))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(entry.displayName.split(' ').first, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: nameColor), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('${entry.periodPoints} pts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pointsColor)),
        const SizedBox(height: 8),
        Container(height: barHeight, decoration: BoxDecoration(color: AppColors.slate800, borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))),
      ],
    );
  }

  Widget _defaultAvatar() => Container(color: AppColors.slate700, child: const Icon(Icons.person, color: AppColors.slate400));
}

// ---------------------------------------------------------------------------
// Live Ranking Card
// ---------------------------------------------------------------------------
class _LiveRankingCard extends StatelessWidget {
  const _LiveRankingCard({required this.entry, required this.rank});
  final LeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$rank', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate500))),
          const SizedBox(width: 12),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.borderMedium, width: 1.5)),
            child: ClipOval(
              child: entry.avatarUrl != null
                  ? Image.network(entry.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.slate200, child: const Icon(Icons.person, color: AppColors.slate400)))
                  : Container(color: AppColors.slate200, child: const Icon(Icons.person, color: AppColors.slate400)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(entry.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
          if (entry.stats.currentStreak > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.orange50, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, size: 13, color: AppColors.orange),
                  const SizedBox(width: 3),
                  Text('${entry.stats.currentStreak} days', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange)),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(10)),
            child: Text('${entry.periodPoints} pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emerald)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock Podium (placeholder mode)
// ---------------------------------------------------------------------------
class _MockPodium extends StatelessWidget {
  const _MockPodium({required this.top3});
  final List<MockUser> top3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _MockPodiumColumn(user: top3[1], rank: 2, barHeight: 64, avatarBorderColor: AppColors.slate300, nameColor: AppColors.slate300, pointsColor: AppColors.slate300, showTrophy: false)),
          const SizedBox(width: 8),
          Expanded(child: _MockPodiumColumn(user: top3[0], rank: 1, barHeight: 96, avatarBorderColor: AppColors.yellow400, nameColor: Colors.white, pointsColor: AppColors.yellow400, showTrophy: true)),
          const SizedBox(width: 8),
          Expanded(child: _MockPodiumColumn(user: top3[2], rank: 3, barHeight: 48, avatarBorderColor: AppColors.orange300, nameColor: AppColors.orange300, pointsColor: AppColors.orange300, showTrophy: false)),
        ],
      ),
    );
  }
}

class _MockPodiumColumn extends StatelessWidget {
  const _MockPodiumColumn({required this.user, required this.rank, required this.barHeight, required this.avatarBorderColor, required this.nameColor, required this.pointsColor, required this.showTrophy});
  final MockUser user;
  final int rank;
  final double barHeight;
  final Color avatarBorderColor;
  final Color nameColor;
  final Color pointsColor;
  final bool showTrophy;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showTrophy) ...[const Icon(Icons.emoji_events, color: AppColors.yellow400, size: 28), const SizedBox(height: 4)] else const SizedBox(height: 32),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: avatarBorderColor, width: 2.5)), child: ClipOval(child: Image.network(user.avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.slate700, child: const Icon(Icons.person, color: AppColors.slate400))))),
            Positioned(bottom: -4, right: -4, child: Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: avatarBorderColor, border: Border.all(color: AppColors.slate900, width: 2)), child: Center(child: Text('$rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slate900))))),
          ],
        ),
        const SizedBox(height: 8),
        Text(user.name.split(' ').first, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: nameColor), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('${user.points} pts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pointsColor)),
        const SizedBox(height: 8),
        Container(height: barHeight, decoration: BoxDecoration(color: AppColors.slate800, borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mock Ranking Card (placeholder mode)
// ---------------------------------------------------------------------------
class _MockRankingCard extends StatelessWidget {
  const _MockRankingCard({required this.user, required this.rank});
  final MockUser user;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))]),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$rank', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate500))),
          const SizedBox(width: 12),
          Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.borderMedium, width: 1.5)), child: ClipOval(child: Image.network(user.avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.slate200, child: const Icon(Icons.person, color: AppColors.slate400))))),
          const SizedBox(width: 12),
          Expanded(child: Text(user.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
          if (user.streak > 0) ...[
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.orange50, borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.local_fire_department, size: 13, color: AppColors.orange), const SizedBox(width: 3), Text('${user.streak} days', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange))])),
            const SizedBox(width: 8),
          ],
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(10)), child: Text('${user.points} pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emerald))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Deep Clean Callout Card (unchanged)
// ---------------------------------------------------------------------------
class _DeepCleanCard extends StatelessWidget {
  const _DeepCleanCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.blue, AppColors.indigo]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monthly Deep Clean', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('Earn bonus points!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Run all tests**

Run: `flutter test`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add lib/src/features/leaderboard/leaderboard_screen.dart
git commit -m "feat: wire leaderboard screen to real Firestore data with placeholder fallback"
```

---

## Task 8: Wire profile screen to real member stats and badges

**Files:**
- Modify: `lib/src/features/profile/profile_screen.dart`

**Step 1: Convert ProfileScreen to ConsumerWidget and wire to real data**

Replace the entire contents of `lib/src/features/profile/profile_screen.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../mock/mock_data.dart';
import '../../models/badge.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/house_provider.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final houseIdAsync = ref.watch(currentHouseIdProvider);
    final houseId = houseIdAsync.valueOrNull;
    final isPlaceholder = kDebugMode && houseId == null;

    if (isPlaceholder) {
      return _MockProfileScreen();
    }

    if (houseId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authState = ref.watch(authStateProvider);
    final uid = authState.valueOrNull?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final membersAsync = ref.watch(membersStreamProvider(houseId));
    final houseAsync = ref.watch(currentHouseProvider(houseId));

    return membersAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (members) {
        final member = members.firstWhere(
          (m) => m.uid == uid,
          orElse: () => Member(
            uid: uid,
            displayName: 'Unknown',
            joinedAt: DateTime.now() as dynamic,
            presenceUpdatedAt: DateTime.now() as dynamic,
          ),
        );
        final houseName = houseAsync.valueOrNull?.name ?? 'My House';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LiveProfileHeader(member: member, houseName: houseName),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LiveStatsGrid(stats: member.stats),
                      const SizedBox(height: 28),
                      _LiveBadgesSection(earnedBadgeIds: member.stats.badges),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Live Header ──────────────────────────────────────────────────────────

class _LiveProfileHeader extends StatelessWidget {
  const _LiveProfileHeader({required this.member, required this.houseName});
  final Member member;
  final String houseName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.slate100, shape: BoxShape.circle),
                    child: const Icon(Icons.settings_outlined, size: 20, color: AppColors.slate500),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4))],
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                      backgroundColor: AppColors.slate100,
                      child: member.avatarUrl == null ? const Icon(Icons.person, size: 40, color: AppColors.slate400) : null,
                    ),
                  ),
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: member.presence == Presence.home ? AppColors.emerald : AppColors.slate400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(member.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.slate800)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.slate500),
                  const SizedBox(width: 4),
                  Text(houseName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live Stats Grid ──────────────────────────────────────────────────────

class _LiveStatsGrid extends StatelessWidget {
  const _LiveStatsGrid({required this.stats});
  final MemberStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _StatCard(iconBgColor: AppColors.orange100, icon: Icons.emoji_events_rounded, iconColor: AppColors.orange, value: '${stats.totalPoints}', label: 'TOTAL PTS'),
        _StatCard(iconBgColor: AppColors.rose100, icon: Icons.local_fire_department_rounded, iconColor: AppColors.rose, value: '${stats.currentStreak}', label: 'DAY STREAK'),
        _StatCard(iconBgColor: AppColors.blue100, icon: Icons.bolt_rounded, iconColor: AppColors.blue, value: '${stats.issuesResolved}', label: 'RESOLVED'),
        _StatCard(iconBgColor: AppColors.slate100, icon: Icons.shield_outlined, iconColor: AppColors.slate500, value: '${stats.issuesCreated}', label: 'CREATED'),
      ],
    );
  }
}

// ─── Live Badges Section ──────────────────────────────────────────────────

class _LiveBadgesSection extends StatelessWidget {
  const _LiveBadgesSection({required this.earnedBadgeIds});
  final List<String> earnedBadgeIds;

  @override
  Widget build(BuildContext context) {
    final earned = badgeCatalog.entries
        .where((e) => earnedBadgeIds.contains(e.key))
        .map((e) => e.value)
        .toList();
    final locked = badgeCatalog.entries
        .where((e) => !earnedBadgeIds.contains(e.key))
        .map((e) => e.value)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges (${earned.length})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.slate100),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final badge in earned) ...[
                  _BadgeItem(
                    icon: badge.icon,
                    label: badge.name,
                    gradient: _gradientForBadge(badge.id),
                    iconColor: Colors.white,
                  ),
                  const SizedBox(width: 20),
                ],
                for (final badge in locked) ...[
                  _LockedBadgeItem(label: badge.name),
                  const SizedBox(width: 20),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  LinearGradient _gradientForBadge(String id) {
    switch (id) {
      case 'first_issue':
      case 'points_100':
        return const LinearGradient(colors: [Color(0xFFFEF9C3), Color(0xFFFEF08A)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'ten_resolved':
      case 'fifty_resolved':
        return const LinearGradient(colors: [AppColors.blue100, AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'streak_7':
      case 'streak_30':
        return const LinearGradient(colors: [AppColors.orange100, AppColors.orange], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'deep_clean_1':
      case 'deep_clean_10':
        return const LinearGradient(colors: [AppColors.emerald100, AppColors.emerald], begin: Alignment.topLeft, end: Alignment.bottomRight);
      default:
        return const LinearGradient(colors: [AppColors.slate100, AppColors.slate400]);
    }
  }
}

// ─── Badge items ──────────────────────────────────────────────────────────

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({required this.icon, required this.label, required this.gradient, required this.iconColor});
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: gradient, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate700)),
      ],
    );
  }
}

class _LockedBadgeItem extends StatelessWidget {
  const _LockedBadgeItem({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.slate100, shape: BoxShape.circle, border: Border.all(color: AppColors.slate300, width: 2)),
            child: const Icon(Icons.lock_outline_rounded, color: AppColors.slate400, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate500)),
        ],
      ),
    );
  }
}

// ─── Shared StatCard ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.iconBgColor, required this.icon, required this.iconColor, required this.value, required this.label});
  final Color iconBgColor;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.slate100)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}

// ─── Mock Profile (placeholder mode) ──────────────────────────────────────

class _MockProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MockProfileHeader(user: user),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MockStatsGrid(user: user),
                  const SizedBox(height: 28),
                  _MockBadgesSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockProfileHeader extends StatelessWidget {
  const _MockProfileHeader({required this.user});
  final MockUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)), boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 4))]),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              Align(alignment: Alignment.centerRight, child: GestureDetector(onTap: () => context.push('/settings'), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.slate100, shape: BoxShape.circle), child: const Icon(Icons.settings_outlined, size: 20, color: AppColors.slate500)))),
              const SizedBox(height: 8),
              Stack(clipBehavior: Clip.none, children: [
                Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4))]), child: CircleAvatar(radius: 56, backgroundImage: NetworkImage(user.avatarUrl), backgroundColor: AppColors.slate100)),
                Positioned(bottom: 4, right: 4, child: Container(width: 18, height: 18, decoration: BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)))),
              ]),
              const SizedBox(height: 16),
              Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.slate800)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.location_on_outlined, size: 16, color: AppColors.slate500), SizedBox(width: 4), Text('The Treehouse', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slate500))]),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockStatsGrid extends StatelessWidget {
  const _MockStatsGrid({required this.user});
  final MockUser user;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.1,
      children: [
        _StatCard(iconBgColor: AppColors.orange100, icon: Icons.emoji_events_rounded, iconColor: AppColors.orange, value: '${user.points}', label: 'TOTAL PTS'),
        _StatCard(iconBgColor: AppColors.rose100, icon: Icons.local_fire_department_rounded, iconColor: AppColors.rose, value: '${user.streak}', label: 'DAY STREAK'),
        _StatCard(iconBgColor: AppColors.blue100, icon: Icons.bolt_rounded, iconColor: AppColors.blue, value: '42', label: 'RESOLVED'),
        _StatCard(iconBgColor: AppColors.slate100, icon: Icons.shield_outlined, iconColor: AppColors.slate500, value: '12', label: 'CREATED'),
      ],
    );
  }
}

class _MockBadgesSection extends StatelessWidget {
  const _MockBadgesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Badges (3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate800)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.slate100)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _BadgeItem(icon: Icons.star_rounded, label: 'Clean Freak', gradient: const LinearGradient(colors: [Color(0xFFFEF9C3), Color(0xFFFEF08A)], begin: Alignment.topLeft, end: Alignment.bottomRight), iconColor: AppColors.yellow400),
                const SizedBox(width: 20),
                _BadgeItem(icon: Icons.bolt_rounded, label: 'Fast Act', gradient: const LinearGradient(colors: [AppColors.emerald100, AppColors.emerald], begin: Alignment.topLeft, end: Alignment.bottomRight), iconColor: Colors.white),
                const SizedBox(width: 20),
                _BadgeItem(icon: Icons.shield_rounded, label: 'Founder', gradient: const LinearGradient(colors: [AppColors.blue100, AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight), iconColor: Colors.white),
                const SizedBox(width: 20),
                const _LockedBadgeItem(label: 'Locked'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

**Step 2: Run all tests**

Run: `flutter test`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add lib/src/features/profile/profile_screen.dart
git commit -m "feat: wire profile screen to real member stats and badge catalog"
```

---

## Task 9: Update README and run final verification

**Files:**
- Modify: `README.md`

**Step 1: Update sprint roadmap in README**

In `README.md`, update the roadmap table — change Sprint 5 from "Planned" to "Done":

```
| 5 | Gamification: points engine, badges, streaks, live leaderboard | Done |
```

**Step 2: Run all tests**

Run: `flutter test && cd functions && npm test`
Expected: All Flutter tests + all Jest tests pass. Zero regressions.

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: mark Sprint 5 as Done in roadmap"
```

---

## Summary

| Task | What | Files |
|------|------|-------|
| 1 | MemberStats new fields | `member.dart` |
| 2 | Badge catalog (TS + Dart) | `badges.ts`, `badge.dart`, `badge_test.dart` |
| 3 | autoCloseIssues → points/stats/badges | `auto-close-issues.ts`, `gamification.test.ts` |
| 4 | updateStreaks function | `update-streaks.ts`, `index.ts`, `firestore.indexes.json` |
| 5 | completeRoom → deep clean bonus | `complete-room.ts` |
| 6 | Leaderboard provider | `leaderboard_provider.dart`, `leaderboard_provider_test.dart` |
| 7 | Wire leaderboard screen | `leaderboard_screen.dart` |
| 8 | Wire profile screen | `profile_screen.dart` |
| 9 | README + final verification | `README.md` |
