# Demo Data Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add "Explore with demo data" to the Welcome screen so TestFlight reviewers can experience the full app via anonymous auth + server-seeded data.

**Architecture:** Anonymous Firebase Auth on the client, a `seedDemoHouse` Cloud Function that batch-writes a fully populated house (members, issues, deep clean, activity), and a `cleanupDemoHouse` function for teardown. An `isDemo` field on the House model flags demo houses. Settings screen shows "Exit demo" for demo users.

**Tech Stack:** Flutter/Riverpod (client), Firebase Cloud Functions v2 (server), Firestore batch writes, Firebase Auth anonymous sign-in, freezed models with codegen.

---

### Task 1: Add `isDemo` field to House model

**Files:**
- Modify: `lib/src/models/house.dart:32` (add field before closing paren)

**Step 1: Add the field**

In `lib/src/models/house.dart`, add `isDemo` to the House factory:

```dart
    @Default(HouseSettings()) HouseSettings settings,
    @Default(false) bool isDemo,
  }) = _House;
```

**Step 2: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Regenerates `house.freezed.dart` and `house.g.dart` with `isDemo` field.

**Step 3: Verify build**

Run: `flutter analyze`
Expected: No errors.

**Step 4: Commit**

```bash
git add lib/src/models/house.dart lib/src/models/house.freezed.dart lib/src/models/house.g.dart
git commit -m "feat: add isDemo field to House model"
```

---

### Task 2: Add anonymous sign-in to AuthNotifier

**Files:**
- Modify: `lib/src/providers/auth_provider.dart:51` (add method after `signInWithGoogle`)

**Step 1: Add `signInAnonymously` method**

In `lib/src/providers/auth_provider.dart`, add after `signInWithGoogle()` (after line 51):

```dart
  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(firebaseAuthProvider).signInAnonymously();
    });
  }
```

**Step 2: Verify build**

Run: `flutter analyze`
Expected: No errors.

**Step 3: Commit**

```bash
git add lib/src/providers/auth_provider.dart
git commit -m "feat: add anonymous sign-in to AuthNotifier"
```

---

### Task 3: Add `seedDemoHouse` and `exploreDemo` to HouseActions

**Files:**
- Modify: `lib/src/providers/house_provider.dart:97` (add methods to HouseActions class)

**Step 1: Add `seedDemoHouse` method**

In `lib/src/providers/house_provider.dart`, add inside `HouseActions` class after `leaveHouse` (after line 97):

```dart
  Future<String> seedDemoHouse() async {
    final functions = ref.read(firebaseFunctionsProvider);
    final result = await functions
        .httpsCallable('seedDemoHouse')
        .call<Map<String, dynamic>>({});
    final houseId = result.data['houseId'] as String;
    ref.invalidate(currentHouseIdProvider);
    return houseId;
  }

  Future<void> cleanupDemoHouse(String houseId) async {
    final functions = ref.read(firebaseFunctionsProvider);
    await functions
        .httpsCallable('cleanupDemoHouse')
        .call({'houseId': houseId});
    ref.invalidate(currentHouseIdProvider);
  }
```

**Step 2: Verify build**

Run: `flutter analyze`
Expected: No errors.

**Step 3: Commit**

```bash
git add lib/src/providers/house_provider.dart
git commit -m "feat: add seedDemoHouse and cleanupDemoHouse actions"
```

---

### Task 4: Add "Explore with demo data" button to Welcome screen

**Files:**
- Modify: `lib/src/features/onboarding/welcome_screen.dart:44-48`

**Step 1: Add the button**

In `lib/src/features/onboarding/welcome_screen.dart`, replace lines 44-48 (between Google and Email buttons):

```dart
              const SizedBox(height: 16),
              _EmailButton(
                onTap: () => context.go('/sign-in'),
              ),
              const SizedBox(height: 16),
              _DemoButton(
                isLoading: authState.isLoading,
                onTap: () async {
                  final auth = ref.read(authNotifierProvider.notifier);
                  final houseActions = ref.read(houseActionsProvider.notifier);
                  await auth.signInAnonymously();
                  await houseActions.seedDemoHouse();
                },
              ),
              const SizedBox(height: 32),
```

**Step 2: Add the `_DemoButton` widget**

Add after the `_EmailButton` class (after line 285):

```dart
// ---------------------------------------------------------------------------
// Demo explore button
// ---------------------------------------------------------------------------
class _DemoButton extends StatelessWidget {
  const _DemoButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        child: Text(
          'Explore with demo data',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.slate500,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.slate300,
          ),
        ),
      ),
    );
  }
}
```

**Step 3: Verify build**

Run: `flutter analyze`
Expected: No errors.

**Step 4: Commit**

```bash
git add lib/src/features/onboarding/welcome_screen.dart
git commit -m "feat: add Explore with demo data button to Welcome screen"
```

---

### Task 5: Add "Exit demo" to Settings screen

**Files:**
- Modify: `lib/src/features/settings/settings_screen.dart:399` (add `onExitDemo` callback)
- Modify: `lib/src/features/settings/settings_screen.dart:1367` (update `_DangerZone` widget)

**Step 1: Add `isDemo` detection**

The settings screen needs access to the current house's `isDemo` field. Find where the settings screen watches `currentHouseProvider` and extract the `isDemo` value. Pass it to `_DangerZone`.

Update the `_DangerZone` constructor and widget at line 1367:

```dart
class _DangerZone extends StatelessWidget {
  const _DangerZone({
    required this.onLeave,
    required this.onSignOut,
    this.isDemo = false,
    this.onExitDemo,
  });

  final VoidCallback onLeave;
  final VoidCallback onSignOut;
  final bool isDemo;
  final VoidCallback? onExitDemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isDemo && onExitDemo != null) ...[
          GestureDetector(
            onTap: onExitDemo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.amber200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.explore_off_rounded, size: 20, color: AppColors.amber700),
                  SizedBox(width: 10),
                  Text(
                    'Exit Demo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // ... existing Leave House and Sign Out buttons unchanged
```

**Step 2: Pass `isDemo` and `onExitDemo` from the settings screen**

At the `_DangerZone` usage site (~line 399), update to:

```dart
_DangerZone(
  isDemo: house?.isDemo ?? false,
  onExitDemo: () async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Demo'),
        content: const Text('This will delete the demo data and sign you out.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit Demo'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final houseId = ref.read(currentHouseIdProvider).valueOrNull;
      if (houseId != null) {
        await ref.read(houseActionsProvider.notifier).cleanupDemoHouse(houseId);
      }
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  },
  onLeave: _leaveHouse,
  onSignOut: () async { ... },  // existing code
),
```

**Step 3: Check that `AppColors.amber50`, `amber200`, `amber700` exist**

If not, add them to `lib/src/theme/app_theme.dart`. Use standard amber values:
- `amber50: Color(0xFFFFFBEB)`
- `amber200: Color(0xFFFDE68A)`
- `amber700: Color(0xFFB45309)`

**Step 4: Verify build**

Run: `flutter analyze`
Expected: No errors.

**Step 5: Commit**

```bash
git add lib/src/features/settings/settings_screen.dart lib/src/theme/app_theme.dart
git commit -m "feat: add Exit Demo button to settings danger zone"
```

---

### Task 6: Create `seedDemoHouse` Cloud Function

**Files:**
- Create: `functions/src/callables/seed-demo-house.ts`
- Modify: `functions/src/index.ts:19` (add export)

**Step 1: Write the Cloud Function**

Create `functions/src/callables/seed-demo-house.ts`:

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

export const seedDemoHouse = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const db = getFirestore();
  const uid = request.auth.uid;

  // If user already has a house, return it
  const existing = await db
    .collection("houses")
    .where("members", "array-contains", uid)
    .limit(1)
    .get();
  if (!existing.empty) {
    return { houseId: existing.docs[0].id };
  }

  const now = Timestamp.now();
  const houseRef = db.collection("houses").doc();
  const houseId = houseRef.id;
  const rooms = ["Kitchen", "Living Room", "Bathroom", "Hallway", "Bedroom"];

  const demoMembers = [
    { id: "demo-alex", name: "Alex M.", points: 145, resolved: 12, created: 8, streak: 7, longest: 14, badges: ["first_issue", "ten_resolved", "streak_7"], deepClean: 3 },
    { id: "demo-sam", name: "Sam K.", points: 98, resolved: 8, created: 5, streak: 3, longest: 5, badges: ["first_issue"], deepClean: 1 },
    { id: "demo-jordan", name: "Jordan T.", points: 67, resolved: 5, created: 6, streak: 0, longest: 2, badges: [], deepClean: 0 },
  ];

  const batch = db.batch();

  // House doc
  batch.set(houseRef, {
    name: "Appart Rue Exemple",
    createdBy: uid,
    createdAt: now,
    inviteCode: "DEMO01",
    members: [uid, ...demoMembers.map((m) => m.id)],
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
  const currentMonth = new Date().toISOString().slice(0, 7); // "YYYY-MM"
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

  return { houseId };
});
```

**Step 2: Add export to index.ts**

In `functions/src/index.ts`, add after line 19:

```typescript
export { seedDemoHouse } from "./callables/seed-demo-house";
```

**Step 3: Verify build**

Run: `cd functions && npm run build`
Expected: No errors.

**Step 4: Commit**

```bash
git add functions/src/callables/seed-demo-house.ts functions/src/index.ts
git commit -m "feat: add seedDemoHouse Cloud Function"
```

---

### Task 7: Create `cleanupDemoHouse` Cloud Function

**Files:**
- Create: `functions/src/callables/cleanup-demo-house.ts`
- Modify: `functions/src/index.ts` (add export)

**Step 1: Write the Cloud Function**

Create `functions/src/callables/cleanup-demo-house.ts`:

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

export const cleanupDemoHouse = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { houseId } = request.data;
  if (!houseId || typeof houseId !== "string") {
    throw new HttpsError("invalid-argument", "houseId is required");
  }

  const db = getFirestore();
  const uid = request.auth.uid;

  const houseDoc = await db.collection("houses").doc(houseId).get();
  if (!houseDoc.exists) {
    throw new HttpsError("not-found", "House not found");
  }

  const houseData = houseDoc.data()!;
  if (!houseData.isDemo) {
    throw new HttpsError("permission-denied", "Can only clean up demo houses");
  }
  if (!houseData.members.includes(uid)) {
    throw new HttpsError("permission-denied", "Not a member of this house");
  }

  // Delete all subcollections
  const subcollections = ["members", "issues", "deepCleans", "activityEvents"];
  for (const sub of subcollections) {
    const docs = await db.collection(`houses/${houseId}/${sub}`).listDocuments();
    const batch = db.batch();
    for (const doc of docs) {
      batch.delete(doc);
    }
    await batch.commit();
  }

  // Delete house doc
  await db.collection("houses").doc(houseId).delete();

  // Delete anonymous auth account
  try {
    await getAuth().deleteUser(uid);
  } catch {
    // User may already be deleted or not anonymous — ignore
  }

  return { success: true };
});
```

**Step 2: Add export to index.ts**

In `functions/src/index.ts`, add:

```typescript
export { cleanupDemoHouse } from "./callables/cleanup-demo-house";
```

**Step 3: Verify build**

Run: `cd functions && npm run build`
Expected: No errors.

**Step 4: Commit**

```bash
git add functions/src/callables/cleanup-demo-house.ts functions/src/index.ts
git commit -m "feat: add cleanupDemoHouse Cloud Function"
```

---

### Task 8: Add E2E test for demo flow

**Files:**
- Create: `integration_test/demo_flow_test.dart`

**Step 1: Write the E2E test**

Create `integration_test/demo_flow_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'e2e_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetEmulators();
  });

  testWidgets('Explore with demo data → seeds house → exit cleans up',
      (tester) async {
    await initFirebaseForTest();
    await tester.pumpWidget(const MaColocTestApp());
    await tester.pumpAndSettle();

    // Tap "Explore with demo data"
    await tester.tap(find.text('Explore with demo data'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Should land on home screen with demo data
    expect(find.text('Appart Rue Exemple'), findsOneWidget);

    // Navigate to settings
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Tap "Exit Demo"
    await tester.tap(find.text('Exit Demo'));
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.text('Exit Demo').last);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should be back on welcome screen
    expect(find.text('Explore with demo data'), findsOneWidget);
  });
}
```

**Step 2: Verify test compiles**

Run: `flutter analyze integration_test/demo_flow_test.dart`
Expected: No errors (test won't run without emulators + deployed functions).

**Step 3: Commit**

```bash
git add integration_test/demo_flow_test.dart
git commit -m "test: add E2E test for demo data flow"
```

---

### Task 9: Deploy and verify

**Step 1: Deploy Cloud Functions**

Run: `cd functions && firebase deploy --only functions:seedDemoHouse,functions:cleanupDemoHouse`
Expected: Both functions deploy successfully.

**Step 2: Run full test suite**

Run: `flutter test`
Expected: All existing tests pass (new `isDemo` field has a default value so no breakage).

**Step 3: Manual verification**

Run the app on a simulator, tap "Explore with demo data", verify:
- Home screen shows "Appart Rue Exemple" with issues
- Leaderboard shows Alex, Sam, Jordan, and You
- Deep clean shows volunteering state
- Settings shows "Exit Demo" button
- Exit demo returns to Welcome screen

**Step 4: Final commit and tag**

```bash
git add -A
git commit -m "feat: complete demo data flow for TestFlight review"
git tag v0.3.0
git push origin master --tags
```
