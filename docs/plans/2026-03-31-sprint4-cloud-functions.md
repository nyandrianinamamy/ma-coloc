# Sprint 4: Cloud Functions + Client Wiring — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add scheduled Cloud Functions (auto-close issues, reset presence, create monthly deep clean), deep clean callables (claim/complete room), and wire the home screen (presence toggle, who's around) and deep clean screen to live Firestore data.

**Architecture:** Three `onSchedule` Cloud Functions for background automation. Two new `onCall` callables for deep clean room operations. Riverpod StreamProviders for real-time UI. Direct Firestore writes for presence toggle (security rules already permit self-update). Placeholder mode fallback on all screens.

**Tech Stack:** Flutter + Riverpod + Firestore + Cloud Functions v2 (`onSchedule`, `onCall`) + TypeScript + `firebase-functions-test` + `integration_test`

---

## Task 1: Auto-Close Issues — Scheduled Function

**Files:**
- Create: `functions/src/scheduled/auto-close-issues.ts`
- Modify: `functions/src/index.ts`

**Step 1: Create the scheduled function**

Create `functions/src/scheduled/auto-close-issues.ts`:

```typescript
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const autoCloseIssues = onSchedule("every day 02:00", async () => {
  const db = getFirestore();
  const now = Timestamp.now();

  // Get all houses
  const houses = await db.collection("houses").get();

  for (const house of houses.docs) {
    // Query resolved issues past their autoCloseAt
    const issues = await db
      .collection(`houses/${house.id}/issues`)
      .where("status", "==", "resolved")
      .where("autoCloseAt", "<=", now)
      .get();

    if (issues.empty) continue;

    const batch = db.batch();
    for (const issue of issues.docs) {
      batch.update(issue.ref, {
        status: "closed",
        closedAt: now,
      });
    }
    await batch.commit();
  }
});
```

**Step 2: Export from index.ts**

Add to `functions/src/index.ts`:

```typescript
export { autoCloseIssues } from "./scheduled/auto-close-issues";
```

**Step 3: Verify TypeScript compiles**

Run: `cd functions && npm run build`
Expected: No errors

**Step 4: Commit**

```bash
git add functions/src/scheduled/auto-close-issues.ts functions/src/index.ts
git commit -m "feat: add auto-close issues scheduled function (daily 2am)"
```

---

## Task 2: Reset Presence — Scheduled Function

**Files:**
- Create: `functions/src/scheduled/reset-presence.ts`
- Modify: `functions/src/index.ts`

**Step 1: Create the scheduled function**

Create `functions/src/scheduled/reset-presence.ts`:

```typescript
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const resetPresence = onSchedule("every day 00:00", async () => {
  const db = getFirestore();
  const now = Timestamp.now();
  const cutoff = Timestamp.fromMillis(now.toMillis() - 24 * 60 * 60 * 1000);

  const houses = await db.collection("houses").get();

  for (const house of houses.docs) {
    const staleMembers = await db
      .collection(`houses/${house.id}/members`)
      .where("presence", "==", "home")
      .where("presenceUpdatedAt", "<=", cutoff)
      .get();

    if (staleMembers.empty) continue;

    const batch = db.batch();
    for (const member of staleMembers.docs) {
      batch.update(member.ref, {
        presence: "away",
        presenceUpdatedAt: now,
      });
    }
    await batch.commit();
  }
});
```

**Step 2: Export from index.ts**

Add to `functions/src/index.ts`:

```typescript
export { resetPresence } from "./scheduled/reset-presence";
```

**Step 3: Verify TypeScript compiles**

Run: `cd functions && npm run build`
Expected: No errors

**Step 4: Commit**

```bash
git add functions/src/scheduled/reset-presence.ts functions/src/index.ts
git commit -m "feat: add presence reset scheduled function (daily midnight, 24h stale)"
```

---

## Task 3: Create Deep Clean — Scheduled Function

**Files:**
- Create: `functions/src/scheduled/create-deep-clean.ts`
- Modify: `functions/src/index.ts`

**Step 1: Create the scheduled function**

Create `functions/src/scheduled/create-deep-clean.ts`:

```typescript
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { DateTime } from "luxon";

export const createDeepClean = onSchedule("every day 09:00", async () => {
  const db = getFirestore();
  const now = DateTime.utc();
  const currentMonth = now.toFormat("yyyy-MM");
  const todayWeekday = now.weekday; // 1=Mon, 7=Sun (ISO)

  const houses = await db.collection("houses").get();

  for (const house of houses.docs) {
    const data = house.data();
    const settings = data.settings || {};
    const deepCleanDay: number = settings.deepCleanDay || 1;
    const lastDeepCleanMonth: string | null = data.lastDeepCleanMonth || null;

    // Only create if today matches deepCleanDay AND we haven't created for this month
    if (todayWeekday !== deepCleanDay) continue;
    if (lastDeepCleanMonth === currentMonth) continue;

    const rooms: string[] = data.rooms || [];
    if (rooms.length === 0) continue;

    // Build empty assignments map: { roomName: { uid: null, completed: false } }
    const assignments: Record<string, object> = {};
    for (const room of rooms) {
      assignments[room] = {
        uid: null,
        fromVolunteer: false,
        completed: false,
      };
    }

    // Build empty volunteerIntents map
    const volunteerIntents: Record<string, never[]> = {};
    for (const room of rooms) {
      volunteerIntents[room] = [];
    }

    const cleanRef = db
      .collection(`houses/${house.id}/deepCleans`)
      .doc(currentMonth);

    const batch = db.batch();

    batch.set(cleanRef, {
      month: currentMonth,
      status: "in_progress",
      volunteerDeadline: Timestamp.fromDate(
        now.plus({ hours: settings.volunteerWindowHours || 48 }).toJSDate()
      ),
      createdAt: Timestamp.now(),
      volunteerIntents,
      assignments,
    });

    // Update house to track last deep clean month
    batch.update(house.ref, {
      lastDeepCleanMonth: currentMonth,
    });

    await batch.commit();
  }
});
```

**Step 2: Export from index.ts**

Add to `functions/src/index.ts`:

```typescript
export { createDeepClean } from "./scheduled/create-deep-clean";
```

**Step 3: Verify TypeScript compiles**

Run: `cd functions && npm run build`
Expected: No errors

**Step 4: Commit**

```bash
git add functions/src/scheduled/create-deep-clean.ts functions/src/index.ts
git commit -m "feat: add monthly deep clean creation scheduled function"
```

---

## Task 4: Deep Clean Callables — claimRoom & completeRoom

**Files:**
- Create: `functions/src/callables/claim-room.ts`
- Create: `functions/src/callables/complete-room.ts`
- Modify: `functions/src/index.ts`

**Step 1: Create claimRoom callable**

Create `functions/src/callables/claim-room.ts`:

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const claimRoom = onCall(async (request) => {
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

  const cleanRef = db
    .collection(`houses/${houseId}/deepCleans`)
    .doc(cleanId);

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
      throw new HttpsError(
        "already-exists",
        `Room "${roomName}" is already assigned`
      );
    }

    tx.update(cleanRef, {
      [`assignments.${roomName}.uid`]: uid,
      [`assignments.${roomName}.assignedAt`]: Timestamp.now(),
    });
  });

  return { success: true };
});
```

**Step 2: Create completeRoom callable**

Create `functions/src/callables/complete-room.ts`:

```typescript
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

  const cleanRef = db
    .collection(`houses/${houseId}/deepCleans`)
    .doc(cleanId);

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
      throw new HttpsError(
        "permission-denied",
        "Only the assigned member can complete this room"
      );
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
```

**Step 3: Export from index.ts**

Add to `functions/src/index.ts`:

```typescript
export { claimRoom } from "./callables/claim-room";
export { completeRoom } from "./callables/complete-room";
```

**Step 4: Verify TypeScript compiles**

Run: `cd functions && npm run build`
Expected: No errors

**Step 5: Commit**

```bash
git add functions/src/callables/claim-room.ts functions/src/callables/complete-room.ts functions/src/index.ts
git commit -m "feat: add claimRoom and completeRoom callables for deep clean"
```

---

## Task 5: Firestore Rules — Allow autoCloseAt in Resolve Path

**Files:**
- Modify: `firestore.rules:60-61`

**Step 1: Update the resolve rule**

In `firestore.rules`, find the resolve update rule (line 60-61):

```
(request.resource.data.diff(resource.data).affectedKeys().hasOnly(["resolvedBy", "resolvedAt", "resolutionPhotoUrl", "resolutionNote", "status"]) &&
```

Replace with:

```
(request.resource.data.diff(resource.data).affectedKeys().hasOnly(["resolvedBy", "resolvedAt", "resolutionPhotoUrl", "resolutionNote", "status", "autoCloseAt"]) &&
```

**Step 2: Verify rules syntax**

Run: `cd /Users/mamy/Project/MaColoc/macoloc && firebase emulators:start --only firestore` (should start without rules errors, then Ctrl+C)

Or just check the file looks right.

**Step 3: Commit**

```bash
git add firestore.rules
git commit -m "feat: allow autoCloseAt field in issue resolve update rule"
```

---

## Task 6: Member Provider — Presence Toggle Backend

**Files:**
- Create: `lib/src/providers/member_provider.dart`
- Create: `test/providers/member_provider_test.dart`

**Step 1: Create the provider**

Create `lib/src/providers/member_provider.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/member.dart';
import 'auth_provider.dart';
import 'house_provider.dart';

// ---------------------------------------------------------------------------
// Stream provider: all members of a house
// ---------------------------------------------------------------------------

final membersStreamProvider =
    StreamProvider.family<List<Member>, String>((ref, houseId) {
  final db = ref.watch(firestoreProvider);

  return db
      .collection('houses/$houseId/members')
      .snapshots()
      .map((snap) => snap.docs.map(Member.fromFirestore).toList());
});

// ---------------------------------------------------------------------------
// Presence actions
// ---------------------------------------------------------------------------

final presenceActionsProvider =
    NotifierProvider<PresenceActions, AsyncValue<void>>(PresenceActions.new);

class PresenceActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  FirebaseFirestore get _db => ref.read(firestoreProvider);
  String? get _uid => ref.read(authStateProvider).valueOrNull?.uid;

  Future<void> togglePresence({
    required String houseId,
    required Presence newPresence,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _db.collection('houses/$houseId/members').doc(uid).update({
        'presence': newPresence.name,
        'presenceUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
```

**Step 2: Write unit tests**

Create `test/providers/member_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/member.dart';

void main() {
  group('Presence enum', () {
    test('has home and away values', () {
      expect(Presence.values, containsAll([Presence.home, Presence.away]));
      expect(Presence.values.length, 2);
    });

    test('name returns correct string', () {
      expect(Presence.home.name, 'home');
      expect(Presence.away.name, 'away');
    });
  });

  group('MemberRole enum', () {
    test('has admin and member values', () {
      expect(MemberRole.values, containsAll([MemberRole.admin, MemberRole.member]));
      expect(MemberRole.values.length, 2);
    });
  });
}
```

**Step 3: Run tests**

Run: `flutter test test/providers/member_provider_test.dart`
Expected: All tests pass

**Step 4: Run all tests to verify no regressions**

Run: `flutter test`
Expected: 37+ tests pass (35 existing + 2 new)

**Step 5: Commit**

```bash
git add lib/src/providers/member_provider.dart test/providers/member_provider_test.dart
git commit -m "feat: add member provider with presence toggle and members stream"
```

---

## Task 7: Deep Clean Provider — Stream + Callable Actions

**Files:**
- Create: `lib/src/providers/deep_clean_provider.dart`
- Create: `test/providers/deep_clean_provider_test.dart`

**Step 1: Create the provider**

Create `lib/src/providers/deep_clean_provider.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/deep_clean.dart';
import 'house_provider.dart';

// ---------------------------------------------------------------------------
// Stream provider: current month's deep clean
// ---------------------------------------------------------------------------

final currentDeepCleanProvider =
    StreamProvider.family<DeepClean?, String>((ref, houseId) {
  final db = ref.watch(firestoreProvider);
  final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  return db
      .collection('houses/$houseId/deepCleans')
      .doc(currentMonth)
      .snapshots()
      .map((doc) => doc.exists ? DeepClean.fromFirestore(doc) : null);
});

// ---------------------------------------------------------------------------
// Deep clean actions (via callables)
// ---------------------------------------------------------------------------

final deepCleanActionsProvider =
    NotifierProvider<DeepCleanActions, AsyncValue<void>>(DeepCleanActions.new);

class DeepCleanActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  FirebaseFunctions get _functions => ref.read(firebaseFunctionsProvider);

  Future<void> claimRoom({
    required String houseId,
    required String cleanId,
    required String roomName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('claimRoom').call({
        'houseId': houseId,
        'cleanId': cleanId,
        'roomName': roomName,
      });
    });
  }

  Future<void> completeRoom({
    required String houseId,
    required String cleanId,
    required String roomName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _functions.httpsCallable('completeRoom').call({
        'houseId': houseId,
        'cleanId': cleanId,
        'roomName': roomName,
      });
    });
  }
}
```

**Step 2: Write unit tests**

Create `test/providers/deep_clean_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:macoloc/src/models/deep_clean.dart';

void main() {
  group('DeepCleanStatus enum', () {
    test('has all expected values', () {
      expect(DeepCleanStatus.values, containsAll([
        DeepCleanStatus.volunteering,
        DeepCleanStatus.assigned,
        DeepCleanStatus.inProgress,
        DeepCleanStatus.completed,
      ]));
      expect(DeepCleanStatus.values.length, 4);
    });
  });

  group('currentMonth format', () {
    test('produces yyyy-MM format', () {
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      expect(currentMonth, matches(RegExp(r'^\d{4}-\d{2}$')));
    });
  });

  group('RoomAssignment', () {
    test('default values', () {
      const assignment = RoomAssignment();
      expect(assignment.uid, isNull);
      expect(assignment.fromVolunteer, false);
      expect(assignment.completed, false);
    });

    test('fromJson with uid', () {
      final json = {'uid': 'user1', 'fromVolunteer': false, 'completed': true};
      final assignment = RoomAssignment.fromJson(json);
      expect(assignment.uid, 'user1');
      expect(assignment.completed, true);
    });
  });
}
```

**Step 3: Run tests**

Run: `flutter test test/providers/deep_clean_provider_test.dart`
Expected: All tests pass

**Step 4: Run all tests**

Run: `flutter test`
Expected: 40+ tests pass (37 + 3 new)

**Step 5: Commit**

```bash
git add lib/src/providers/deep_clean_provider.dart test/providers/deep_clean_provider_test.dart
git commit -m "feat: add deep clean provider with stream and callable actions"
```

---

## Task 8: Modify Issue Provider — Set autoCloseAt on Resolve

**Files:**
- Modify: `lib/src/providers/issue_provider.dart:204-230`
- Modify: `test/providers/issue_provider_test.dart`

**Step 1: Update the resolve method**

In `lib/src/providers/issue_provider.dart`, replace the `resolve` method (lines 204-231) with:

```dart
  Future<void> resolve({
    required String houseId,
    required String issueId,
    String? note,
    XFile? resolutionPhoto,
    int disputeWindowHours = 48,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      String? resolutionPhotoUrl;
      if (resolutionPhoto != null) {
        resolutionPhotoUrl = await _uploadPhoto(
          'houses/$houseId/issues/$issueId/resolution.jpg',
          resolutionPhoto,
        );
      }

      final now = Timestamp.now();
      final autoCloseAt = Timestamp.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch + (disputeWindowHours * 60 * 60 * 1000),
      );

      await _issuesCol(houseId).doc(issueId).update({
        'resolvedBy': uid,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolutionNote': note,
        'resolutionPhotoUrl': resolutionPhotoUrl,
        'status': 'resolved',
        'autoCloseAt': autoCloseAt,
      });
    });
  }
```

**Step 2: Add test for autoCloseAt computation**

Add to `test/providers/issue_provider_test.dart`:

```dart
  group('autoCloseAt computation', () {
    test('Timestamp arithmetic produces future value', () {
      final now = Timestamp.now();
      const disputeWindowHours = 48;
      final autoCloseAt = Timestamp.fromMillisecondsSinceEpoch(
        now.millisecondsSinceEpoch + (disputeWindowHours * 60 * 60 * 1000),
      );
      final diff = autoCloseAt.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
      expect(diff, 48 * 60 * 60 * 1000);
    });
  });
```

**Step 3: Run tests**

Run: `flutter test test/providers/issue_provider_test.dart`
Expected: All tests pass (9 existing + 1 new)

**Step 4: Run all tests**

Run: `flutter test`
Expected: 41+ tests pass

**Step 5: Commit**

```bash
git add lib/src/providers/issue_provider.dart test/providers/issue_provider_test.dart
git commit -m "feat: set autoCloseAt timestamp when resolving issues"
```

---

## Task 9: Wire Home Screen — Presence Toggle + Who's Around

**Files:**
- Modify: `lib/src/features/home/home_screen.dart`

**Step 1: Convert to ConsumerStatefulWidget and wire providers**

Replace the full `home_screen.dart` content. Key changes:
- `StatefulWidget` → `ConsumerStatefulWidget`
- Add imports for providers, models, firebase_options
- `_isHome` state derived from members stream (current user's presence)
- `_PresenceToggle.onChanged` calls `presenceActionsProvider.togglePresence()`
- `_WhosAround` receives `List<Member>` instead of using `MockData.users`
- `_AvatarItem` accepts `Member` instead of `MockUser`
- Placeholder mode fallback: keep mock data when `isPlaceholder`
- Activity feed stays mock (documented as out of scope)

Replace `home_screen.dart` — the full file:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../firebase_options.dart';
import '../../mock/mock_data.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/house_provider.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isPlaceholder =
        kDebugMode && DefaultFirebaseOptions.isPlaceholder;

    if (isPlaceholder) {
      return _buildWithMockData(context);
    }

    final houseIdAsync = ref.watch(currentHouseIdProvider);
    final houseId = houseIdAsync.valueOrNull;

    if (houseId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final houseAsync = ref.watch(currentHouseProvider);
    final house = houseAsync.valueOrNull;
    final membersAsync = ref.watch(membersStreamProvider(houseId));
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return membersAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $e')),
      ),
      data: (members) {
        final currentMember = members.where((m) => m.uid == currentUid).toList();
        final isHome = currentMember.isNotEmpty &&
            currentMember.first.presence == Presence.home;
        final homeMembers =
            members.where((m) => m.presence == Presence.home).toList();
        final activities = MockData.activities; // stays mock

        return _buildScaffold(
          context,
          houseName: house?.name ?? 'My House',
          memberCount: members.length,
          isHome: isHome,
          onPresenceChanged: (value) {
            ref.read(presenceActionsProvider.notifier).togglePresence(
                  houseId: houseId,
                  newPresence: value ? Presence.home : Presence.away,
                );
          },
          homeCount: homeMembers.length,
          members: members,
          activities: activities,
        );
      },
    );
  }

  Widget _buildWithMockData(BuildContext context) {
    final homeUsers =
        MockData.users.where((u) => u.presence == 'home').toList();
    final activities = MockData.activities;

    // Convert MockUsers to a simple format for the mock scaffold
    return _buildMockScaffold(
      context,
      isHome: true,
      homeCount: homeUsers.length,
      activities: activities,
    );
  }

  Widget _buildMockScaffold(
    BuildContext context, {
    required bool isHome,
    required int homeCount,
    required List<MockActivity> activities,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 8)
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleRow(
                          houseName: 'The Treehouse', memberCount: 6),
                      const SizedBox(height: 24),
                      _PresenceToggle(
                        isHome: isHome,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 24),
                      _MockWhosAround(homeCount: homeCount),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: _MomentumCard(
                onLeaderboardTap: () => context.go('/leaderboard'),
              ),
            ),
          ),
          _activityHeader(),
          _activityList(activities),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required String houseName,
    required int memberCount,
    required bool isHome,
    required ValueChanged<bool> onPresenceChanged,
    required int homeCount,
    required List<Member> members,
    required List<MockActivity> activities,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 8)
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleRow(
                          houseName: houseName,
                          memberCount: memberCount),
                      const SizedBox(height: 24),
                      _PresenceToggle(
                        isHome: isHome,
                        onChanged: onPresenceChanged,
                      ),
                      const SizedBox(height: 24),
                      _LiveWhosAround(
                          homeCount: homeCount, members: members),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: _MomentumCard(
                onLeaderboardTap: () => context.go('/leaderboard'),
              ),
            ),
          ),
          _activityHeader(),
          _activityList(activities),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _activityHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.slate800,
              ),
            ),
            Text(
              'View all',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _activityList(List<MockActivity> activities) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ActivityItem(
            activity: activities[index],
            isLast: index == activities.length - 1,
          ),
          childCount: activities.length,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Title Row
// ---------------------------------------------------------------------------
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.houseName, required this.memberCount});

  final String houseName;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              houseName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 2),
            Text(
              '$memberCount Roommates',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.slate700,
                size: 24,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.slate100, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Presence Toggle (unchanged UI)
// ---------------------------------------------------------------------------
class _PresenceToggle extends StatelessWidget {
  const _PresenceToggle({
    required this.isHome,
    required this.onChanged,
  });

  final bool isHome;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment:
                isHome ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 4),
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
                      "I'm Home",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isHome
                            ? AppColors.emerald
                            : AppColors.textSecondary,
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
                      "I'm Away",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: !isHome
                            ? AppColors.orange
                            : AppColors.textSecondary,
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
// Who's Around — Mock version (placeholder mode)
// ---------------------------------------------------------------------------
class _MockWhosAround extends StatelessWidget {
  const _MockWhosAround({required this.homeCount});

  final int homeCount;

  @override
  Widget build(BuildContext context) {
    final users = MockData.users;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WhosAroundHeader(homeCount: homeCount),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final user = users[index];
              final isAtHome = user.presence == 'home';
              return _MockAvatarItem(user: user, isAtHome: isAtHome);
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Who's Around — Live version (Firestore)
// ---------------------------------------------------------------------------
class _LiveWhosAround extends StatelessWidget {
  const _LiveWhosAround({
    required this.homeCount,
    required this.members,
  });

  final int homeCount;
  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WhosAroundHeader(homeCount: homeCount),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final member = members[index];
              final isAtHome = member.presence == Presence.home;
              return _LiveAvatarItem(
                  member: member, isAtHome: isAtHome);
            },
          ),
        ),
      ],
    );
  }
}

class _WhosAroundHeader extends StatelessWidget {
  const _WhosAroundHeader({required this.homeCount});

  final int homeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Who's around?",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.slate800,
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.emerald100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$homeCount Home',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.emerald,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockAvatarItem extends StatelessWidget {
  const _MockAvatarItem({required this.user, required this.isAtHome});

  final MockUser user;
  final bool isAtHome;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAtHome ? 1.0 : 0.5,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAtHome
                        ? AppColors.emerald
                        : AppColors.slate300,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.slate200,
                      child: const Icon(
                          Icons.person, color: AppColors.slate400),
                    ),
                  ),
                ),
              ),
              if (isAtHome)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emerald,
                      border:
                          Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 56,
            child: Text(
              user.name.split(' ').first,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveAvatarItem extends StatelessWidget {
  const _LiveAvatarItem({required this.member, required this.isAtHome});

  final Member member;
  final bool isAtHome;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAtHome ? 1.0 : 0.5,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAtHome
                        ? AppColors.emerald
                        : AppColors.slate300,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: member.avatarUrl != null
                      ? Image.network(
                          member.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.slate200,
                            child: const Icon(Icons.person,
                                color: AppColors.slate400),
                          ),
                        )
                      : Container(
                          color: AppColors.slate200,
                          child: const Icon(Icons.person,
                              color: AppColors.slate400),
                        ),
                ),
              ),
              if (isAtHome)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emerald,
                      border:
                          Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 56,
            child: Text(
              member.displayName.split(' ').first,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Momentum Card (unchanged)
// ---------------------------------------------------------------------------
class _MomentumCard extends StatelessWidget {
  const _MomentumCard({required this.onLeaderboardTap});

  final VoidCallback onLeaderboardTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFDE047),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'House on fire!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your house resolved 12 issues this week. Keep up the momentum!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onLeaderboardTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'View Leaderboard',
                style: TextStyle(
                  color: AppColors.emerald,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity Feed Item (unchanged — stays mock)
// ---------------------------------------------------------------------------
class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.activity,
    required this.isLast,
  });

  final MockActivity activity;
  final bool isLast;

  Color get _dotColor {
    switch (activity.type) {
      case 'created':
        return AppColors.orange;
      case 'resolved':
        return AppColors.emerald;
      case 'disputed':
        return AppColors.rose;
      case 'claimed':
        return AppColors.blue;
      default:
        return AppColors.slate400;
    }
  }

  IconData get _dotIcon {
    switch (activity.type) {
      case 'created':
        return Icons.error_outline;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'disputed':
        return Icons.chat_bubble_outline;
      case 'claimed':
        return Icons.search;
      default:
        return Icons.circle_outlined;
    }
  }

  String get _verb {
    switch (activity.type) {
      case 'created':
        return ' flagged an issue: ';
      case 'resolved':
        return ' resolved ';
      case 'disputed':
        return ' disputed ';
      case 'claimed':
        return ' claimed ';
      default:
        return ' ${activity.type} ';
    }
  }

  int get _points {
    switch (activity.type) {
      case 'resolved':
        return 50;
      case 'claimed':
        return 10;
      case 'created':
        return 10;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/issues/${activity.issue.id}'),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _dotColor.withValues(alpha: 0.12),
                    ),
                    child:
                        Icon(_dotIcon, color: _dotColor, size: 18),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.slate200,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: activity.user.name
                                        .split(' ')
                                        .first,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            AppColors.textPrimary),
                                  ),
                                  TextSpan(
                                    text: _verb,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: AppColors
                                            .textSecondary),
                                  ),
                                  TextSpan(
                                    text:
                                        '"${activity.issue.title}"',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            activity.time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_points > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '+$_points pts',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Verify app compiles**

Run: `flutter analyze`
Expected: No errors

**Step 3: Run all tests**

Run: `flutter test`
Expected: 41+ tests pass (no regressions)

**Step 4: Commit**

```bash
git add lib/src/features/home/home_screen.dart
git commit -m "feat: wire home screen presence toggle and who's around to Firestore"
```

---

## Task 10: Wire Deep Clean Screen to Firestore

**Files:**
- Modify: `lib/src/features/deep_clean/deep_clean_screen.dart`

**Step 1: Convert to ConsumerStatefulWidget and wire providers**

Replace `deep_clean_screen.dart`. Key changes:
- `StatefulWidget` → `ConsumerStatefulWidget`
- Add imports for providers, models, firebase_options, auth
- Replace local `_rooms` with `ref.watch(currentDeepCleanProvider(houseId))`
- `_claimRoom` calls `deepCleanActionsProvider.claimRoom()`
- `_completeRoom` calls `deepCleanActionsProvider.completeRoom()`
- Progress from `DeepClean.assignments`
- Header title uses month from deep clean doc
- Empty state when no deep clean for current month
- Placeholder mode fallback

Replace `deep_clean_screen.dart` — the full file:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../firebase_options.dart';
import '../../mock/mock_data.dart';
import '../../models/deep_clean.dart';
import '../../providers/auth_provider.dart';
import '../../providers/deep_clean_provider.dart';
import '../../providers/house_provider.dart';
import '../../theme/app_theme.dart';

class DeepCleanScreen extends ConsumerStatefulWidget {
  const DeepCleanScreen({super.key});

  @override
  ConsumerState<DeepCleanScreen> createState() => _DeepCleanScreenState();
}

class _DeepCleanScreenState extends ConsumerState<DeepCleanScreen> {
  @override
  Widget build(BuildContext context) {
    final isPlaceholder =
        kDebugMode && DefaultFirebaseOptions.isPlaceholder;

    if (isPlaceholder) {
      return _buildMockScreen(context);
    }

    final houseIdAsync = ref.watch(currentHouseIdProvider);
    final houseId = houseIdAsync.valueOrNull;

    if (houseId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final deepCleanAsync = ref.watch(currentDeepCleanProvider(houseId));
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return deepCleanAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $e')),
      ),
      data: (deepClean) {
        if (deepClean == null) {
          return _buildEmptyState(context);
        }
        return _buildLiveScreen(
          context,
          deepClean: deepClean,
          houseId: houseId,
          currentUid: currentUid,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state — no deep clean for this month
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _DeepCleanHeader(
            title: '${DateFormat.MMMM().format(DateTime.now())} Deep Clean',
            progressDisplay: '—',
            progressPercent: 0,
            deadlineLabel: 'Not scheduled',
            onBack: () => context.pop(),
          ),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 64, color: AppColors.slate300),
                    SizedBox(height: 16),
                    Text(
                      'No deep clean scheduled this month',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Live Firestore screen
  // ---------------------------------------------------------------------------

  Widget _buildLiveScreen(
    BuildContext context, {
    required DeepClean deepClean,
    required String houseId,
    required String? currentUid,
  }) {
    final assignments = deepClean.assignments;
    final totalRooms = assignments.length;
    final completedCount =
        assignments.values.where((a) => a.completed).length;
    final progressPercent =
        totalRooms > 0 ? completedCount / totalRooms : 0.0;
    final progressDisplay = '${(progressPercent * 100).round()}%';

    // Format month name from deepClean.month (e.g. "2026-03" → "March")
    final monthDate = DateTime.parse('${deepClean.month}-01');
    final monthName = DateFormat.MMMM().format(monthDate);

    // Deadline
    final deadline = deepClean.volunteerDeadline.toDate();
    final deadlineLabel = DateFormat('EEEE h:mma').format(deadline);

    final roomEntries = assignments.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeepCleanHeader(
              title: '$monthName Deep Clean',
              progressDisplay: progressDisplay,
              progressPercent: progressPercent,
              deadlineLabel: deadlineLabel,
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoomAssignmentsHeader(totalRooms: totalRooms),
                  const SizedBox(height: 14),
                  for (final entry in roomEntries) ...[
                    _LiveRoomCard(
                      roomName: entry.key,
                      assignment: entry.value,
                      currentUid: currentUid,
                      onClaim: () {
                        ref
                            .read(deepCleanActionsProvider.notifier)
                            .claimRoom(
                              houseId: houseId,
                              cleanId: deepClean.id,
                              roomName: entry.key,
                            );
                      },
                      onComplete: () {
                        ref
                            .read(deepCleanActionsProvider.notifier)
                            .completeRoom(
                              houseId: houseId,
                              cleanId: deepClean.id,
                              roomName: entry.key,
                            );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mock screen (placeholder mode)
  // ---------------------------------------------------------------------------

  Widget _buildMockScreen(BuildContext context) {
    final rooms = MockData.rooms;
    final cleanCount = rooms.where((r) => r.status == 'clean').length;
    final progressPercent =
        rooms.isNotEmpty ? cleanCount / rooms.length : 0.0;
    final progressDisplay = '${(progressPercent * 100).round()}%';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeepCleanHeader(
              title: '${DateFormat.MMMM().format(DateTime.now())} Deep Clean',
              progressDisplay: progressDisplay,
              progressPercent: progressPercent,
              deadlineLabel: 'Sunday 5PM',
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoomAssignmentsHeader(totalRooms: rooms.length),
                  const SizedBox(height: 14),
                  for (final room in rooms) ...[
                    _MockRoomCard(room: room),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _DeepCleanHeader extends StatelessWidget {
  const _DeepCleanHeader({
    required this.title,
    required this.progressDisplay,
    required this.progressPercent,
    required this.deadlineLabel,
    required this.onBack,
  });

  final String title;
  final String progressDisplay;
  final double progressPercent;
  final String deadlineLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue600, AppColors.indigo700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.auto_awesome_rounded,
                      size: 22, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'House Progress',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                progressDisplay,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Deadline',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                deadlineLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 12,
                        child: Stack(
                          children: [
                            Container(
                              color: Colors.black
                                  .withValues(alpha: 0.2),
                            ),
                            FractionallySizedBox(
                              widthFactor:
                                  progressPercent.clamp(0.0, 1.0),
                              child:
                                  Container(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Room Assignments Header ─────────────────────────────────────────────────

class _RoomAssignmentsHeader extends StatelessWidget {
  const _RoomAssignmentsHeader({required this.totalRooms});

  final int totalRooms;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Room Assignments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.slate800,
            ),
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${totalRooms * 100} pts total',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.blue600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Live Room Card ──────────────────────────────────────────────────────────

class _LiveRoomCard extends StatelessWidget {
  const _LiveRoomCard({
    required this.roomName,
    required this.assignment,
    required this.currentUid,
    required this.onClaim,
    required this.onComplete,
  });

  final String roomName;
  final RoomAssignment assignment;
  final String? currentUid;
  final VoidCallback onClaim;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final isCompleted = assignment.completed;
    final isAssignedToMe =
        assignment.uid != null && assignment.uid == currentUid;
    final isAssignedToOther =
        assignment.uid != null && assignment.uid != currentUid;
    final isUnclaimed = assignment.uid == null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '100 points',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                _StatusBadge(
                  label: 'Done',
                  bgColor: AppColors.emerald100,
                  textColor: AppColors.emerald,
                )
              else if (isAssignedToMe || isAssignedToOther)
                _StatusBadge(
                  label: 'Assigned',
                  bgColor: AppColors.blue100,
                  textColor: AppColors.blue600,
                )
              else
                _StatusBadge(
                  label: 'Unclaimed',
                  bgColor: AppColors.orange100,
                  textColor: AppColors.orange,
                ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 14),
            if (isAssignedToMe)
              _ActionButton(
                label: 'Mark as Spotless',
                bgColor: AppColors.emerald,
                textColor: Colors.white,
                onTap: onComplete,
              )
            else if (isUnclaimed)
              _ActionButton(
                label: "I'll do it",
                bgColor: Colors.white,
                textColor: AppColors.slate700,
                borderColor: AppColors.slate200,
                onTap: onClaim,
              )
            else if (isAssignedToOther)
              _ActionButton(
                label: 'Assigned to someone',
                bgColor: AppColors.slate100,
                textColor: AppColors.slate400,
                onTap: null,
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Mock Room Card (placeholder mode) ───────────────────────────────────────

class _MockRoomCard extends StatelessWidget {
  const _MockRoomCard({required this.room});

  final MockRoom room;

  @override
  Widget build(BuildContext context) {
    final isClean = room.status == 'clean';
    final isAssigned = room.status == 'assigned';
    final isUnclaimed = room.status == 'dirty';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '100 points',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClean)
                _StatusBadge(
                  label: 'Done',
                  bgColor: AppColors.emerald100,
                  textColor: AppColors.emerald,
                )
              else if (isAssigned)
                _StatusBadge(
                  label: 'Assigned',
                  bgColor: AppColors.blue100,
                  textColor: AppColors.blue600,
                )
              else
                _StatusBadge(
                  label: 'Unclaimed',
                  bgColor: AppColors.orange100,
                  textColor: AppColors.orange,
                ),
            ],
          ),
          if (!isClean) ...[
            const SizedBox(height: 14),
            if (isUnclaimed)
              _ActionButton(
                label: "I'll do it",
                bgColor: Colors.white,
                textColor: AppColors.slate700,
                borderColor: AppColors.slate200,
                onTap: () {},
              )
            else if (isAssigned)
              _ActionButton(
                label: 'Assigned',
                bgColor: AppColors.slate100,
                textColor: AppColors.slate400,
                onTap: null,
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Verify app compiles**

Run: `flutter analyze`
Expected: No errors

**Step 3: Run all tests**

Run: `flutter test`
Expected: 41+ tests pass (no regressions)

**Step 4: Commit**

```bash
git add lib/src/features/deep_clean/deep_clean_screen.dart
git commit -m "feat: wire deep clean screen to Firestore with real-time room assignments"
```

---

## Task 11: Issue Detail — Closed Status Timeline Step

**Files:**
- Modify: `lib/src/features/issues/issue_detail_screen.dart:943-964`

**Step 1: Add closed step to timeline**

In `_TimelineSection.build()`, after the disputed block (around line 964), add:

```dart
    // Step: Closed (auto-closed after dispute window)
    if (issue.status == IssueStatus.closed) {
      // If there was a resolved step too, add it first
      if (issue.resolvedBy != null) {
        steps.add(_TimelineStep(
          iconBg: AppColors.emerald,
          icon: Icons.check,
          iconColor: Colors.white,
          title: 'Resolved',
          subtitle: 'by Resolver',
          isLast: false,
        ));
      }
      steps.add(_TimelineStep(
        iconBg: AppColors.slate400,
        icon: Icons.lock_outline,
        iconColor: Colors.white,
        title: 'Closed',
        subtitle: 'Auto-closed after dispute window',
        isLast: true,
      ));
    }
```

**Step 2: Verify app compiles**

Run: `flutter analyze`
Expected: No errors

**Step 3: Run all tests**

Run: `flutter test`
Expected: 41+ tests pass (no regressions)

**Step 4: Commit**

```bash
git add lib/src/features/issues/issue_detail_screen.dart
git commit -m "feat: add closed status timeline step to issue detail screen"
```

---

## Task 12: Update README Sprint Roadmap

**Files:**
- Modify: `README.md:196-203`

**Step 1: Update sprint statuses**

Update the sprint roadmap table:

```markdown
| Sprint | Scope | Status |
|--------|-------|--------|
| 1 | Foundation: scaffold, models, Firebase auth, onboarding, Cloud Functions | Done |
| 2 | UI Shell: all 9 screens with mock data, bottom nav, GoRouter, design system | Done |
| 3 | Issue system: Firestore CRUD, photo upload, real-time streams, issue lifecycle | Done |
| 4 | Cloud Functions: auto-close, presence, deep clean + client wiring | Done |
| 5 | Gamification: points engine, badges, streaks, live leaderboard | Planned |
| 6 | Polish: notifications, settings mutations, activity feed, volunteer flow | Planned |
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update sprint roadmap — mark Sprint 3-4 as Done"
```

---

## Summary

| Task | Component | Files |
|------|-----------|-------|
| 1 | Auto-close issues (scheduled) | `functions/src/scheduled/auto-close-issues.ts` |
| 2 | Reset presence (scheduled) | `functions/src/scheduled/reset-presence.ts` |
| 3 | Create deep clean (scheduled) | `functions/src/scheduled/create-deep-clean.ts` |
| 4 | claimRoom + completeRoom (callables) | `functions/src/callables/claim-room.ts`, `complete-room.ts` |
| 5 | Firestore rules (autoCloseAt) | `firestore.rules` |
| 6 | Member provider + presence toggle | `lib/src/providers/member_provider.dart` |
| 7 | Deep clean provider + actions | `lib/src/providers/deep_clean_provider.dart` |
| 8 | Issue provider (autoCloseAt on resolve) | `lib/src/providers/issue_provider.dart` |
| 9 | Home screen wiring | `lib/src/features/home/home_screen.dart` |
| 10 | Deep clean screen wiring | `lib/src/features/deep_clean/deep_clean_screen.dart` |
| 11 | Issue detail (closed timeline) | `lib/src/features/issues/issue_detail_screen.dart` |
| 12 | README update | `README.md` |
