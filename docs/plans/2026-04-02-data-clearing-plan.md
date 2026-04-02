# Data Clearing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add account deletion, house data reset, archived issue purging, and local cache clearing to MaColoc.

**Architecture:** Cloud Functions (TypeScript, admin SDK) for all Firestore/Storage/Auth operations. Client-side Dart for local cache only. New Data & Privacy screen accessible to admins from Settings.

**Tech Stack:** Firebase Cloud Functions v2, Firebase Admin SDK, Flutter/Riverpod, GoRouter

**Design doc:** `docs/plans/2026-04-02-data-clearing-design.md`

---

### Task 1: Cloud Function — `deleteAccount`

**Files:**
- Create: `functions/src/callables/delete-account.ts`
- Modify: `functions/src/index.ts` (add export)

**Step 1: Create `delete-account.ts`**

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";

export const deleteAccount = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const uid = request.auth.uid;
  const db = getFirestore();

  // Find the user's house
  const housesSnap = await db
    .collection("houses")
    .where("members", "array-contains", uid)
    .limit(1)
    .get();

  if (housesSnap.empty) {
    // No house — just delete the auth account
    await getAuth().deleteUser(uid);
    return { success: true };
  }

  const houseRef = housesSnap.docs[0].ref;
  const houseData = housesSnap.docs[0].data();

  // If last member, recursive delete entire house + auth
  if (houseData.members.length === 1) {
    await db.recursiveDelete(houseRef);
    await getAuth().deleteUser(uid);
    return { success: true };
  }

  // Check if caller is the only admin
  const membersSnap = await houseRef.collection("members").get();
  const callerDoc = membersSnap.docs.find((d) => d.id === uid);
  if (callerDoc?.data().role === "admin") {
    const otherAdmins = membersSnap.docs.filter(
      (d) => d.id !== uid && d.data().role === "admin"
    );
    if (otherAdmins.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "Transfer admin role to another member before deleting your account"
      );
    }
  }

  // Anonymize issue references in batches
  const issuesSnap = await houseRef.collection("issues").get();
  const issueBatches: FirebaseFirestore.WriteBatch[] = [];
  let batch = db.batch();
  let count = 0;

  for (const doc of issuesSnap.docs) {
    const data = doc.data();
    const updates: Record<string, any> = {};

    if (data.createdBy === uid) updates.createdBy = "deleted_user";
    if (data.assignedTo === uid) updates.assignedTo = null;
    if (data.resolvedBy === uid) updates.resolvedBy = "deleted_user";
    if (data.disputedBy === uid) updates.disputedBy = "deleted_user";
    if (data.disputeAgainst === uid) updates.disputeAgainst = "deleted_user";

    if (Object.keys(updates).length > 0) {
      batch.update(doc.ref, updates);
      count++;
      if (count >= 500) {
        issueBatches.push(batch);
        batch = db.batch();
        count = 0;
      }
    }
  }

  // Anonymize activity events
  const activitySnap = await houseRef.collection("activity").get();
  for (const doc of activitySnap.docs) {
    if (doc.data().uid === uid) {
      batch.update(doc.ref, {
        uid: "deleted_user",
        displayName: "Deleted User",
      });
      count++;
      if (count >= 500) {
        issueBatches.push(batch);
        batch = db.batch();
        count = 0;
      }
    }
  }

  // Remove from house members array + delete member doc
  batch.update(houseRef, { members: FieldValue.arrayRemove(uid) });
  batch.delete(houseRef.collection("members").doc(uid));
  issueBatches.push(batch);

  // Commit all batches
  await Promise.all(issueBatches.map((b) => b.commit()));

  // Delete auth account
  await getAuth().deleteUser(uid);

  return { success: true };
});
```

**Step 2: Add export to `functions/src/index.ts`**

Add this line:
```typescript
export { deleteAccount } from "./callables/delete-account";
```

**Step 3: Commit**

```
git add functions/src/callables/delete-account.ts functions/src/index.ts
git commit -m "feat(functions): add deleteAccount callable for account deletion"
```

---

### Task 2: Cloud Function — `resetHouseData`

**Files:**
- Create: `functions/src/callables/reset-house-data.ts`
- Modify: `functions/src/index.ts` (add export)

**Step 1: Create `reset-house-data.ts`**

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

const VALID_SCOPES = ["all", "issues", "activity", "leaderboard", "stats"] as const;
type Scope = typeof VALID_SCOPES[number];

async function deleteSubcollection(
  db: FirebaseFirestore.Firestore,
  collectionRef: FirebaseFirestore.CollectionReference
) {
  const snap = await collectionRef.get();
  const batches: FirebaseFirestore.WriteBatch[] = [];
  let batch = db.batch();
  let count = 0;

  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    count++;
    if (count >= 500) {
      batches.push(batch);
      batch = db.batch();
      count = 0;
    }
  }
  if (count > 0) batches.push(batch);
  await Promise.all(batches.map((b) => b.commit()));
}

async function deleteStoragePrefix(prefix: string) {
  const bucket = getStorage().bucket();
  await bucket.deleteFiles({ prefix, force: true });
}

async function resetAllMemberStats(
  db: FirebaseFirestore.Firestore,
  houseRef: FirebaseFirestore.DocumentReference
) {
  const membersSnap = await houseRef.collection("members").get();
  const batches: FirebaseFirestore.WriteBatch[] = [];
  let batch = db.batch();
  let count = 0;

  const zeroStats = {
    "stats.totalPoints": 0,
    "stats.issuesCreated": 0,
    "stats.issuesResolved": 0,
    "stats.currentStreak": 0,
    "stats.longestStreak": 0,
    "stats.badges": [],
    "stats.deepCleanRoomsCompleted": 0,
    "stats.lastStreakDate": null,
    "stats.lastRandomAssignMonth": null,
  };

  for (const doc of membersSnap.docs) {
    batch.update(doc.ref, zeroStats);
    count++;
    if (count >= 500) {
      batches.push(batch);
      batch = db.batch();
      count = 0;
    }
  }
  if (count > 0) batches.push(batch);
  await Promise.all(batches.map((b) => b.commit()));
}

export const resetHouseData = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { houseId, scope } = request.data;
  if (!houseId || typeof houseId !== "string") {
    throw new HttpsError("invalid-argument", "House ID is required");
  }
  if (!scope || !VALID_SCOPES.includes(scope)) {
    throw new HttpsError("invalid-argument", `Scope must be one of: ${VALID_SCOPES.join(", ")}`);
  }

  const db = getFirestore();
  const uid = request.auth.uid;
  const houseRef = db.collection("houses").doc(houseId);

  // Verify admin
  const memberDoc = await houseRef.collection("members").doc(uid).get();
  if (!memberDoc.exists || memberDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can reset house data");
  }

  const typedScope = scope as Scope;

  if (typedScope === "all" || typedScope === "issues") {
    await deleteSubcollection(db, houseRef.collection("issues"));
    await deleteStoragePrefix(`houses/${houseId}/issues/`);
    await deleteStoragePrefix(`houses/${houseId}/resolutions/`);
  }

  if (typedScope === "all" || typedScope === "activity") {
    await deleteSubcollection(db, houseRef.collection("activity"));
  }

  if (typedScope === "all" || typedScope === "leaderboard") {
    await deleteSubcollection(db, houseRef.collection("leaderboard"));
  }

  if (typedScope === "all") {
    await deleteSubcollection(db, houseRef.collection("deepCleans"));
  }

  if (typedScope === "all" || typedScope === "stats") {
    await resetAllMemberStats(db, houseRef);
  }

  return { success: true };
});
```

**Step 2: Add export to `functions/src/index.ts`**

```typescript
export { resetHouseData } from "./callables/reset-house-data";
```

**Step 3: Commit**

```
git add functions/src/callables/reset-house-data.ts functions/src/index.ts
git commit -m "feat(functions): add resetHouseData callable with scoped clearing"
```

---

### Task 3: Cloud Function — `purgeArchivedIssues`

**Files:**
- Create: `functions/src/callables/purge-archived-issues.ts`
- Modify: `functions/src/index.ts` (add export)

**Step 1: Create `purge-archived-issues.ts`**

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";

export const purgeArchivedIssues = onCall({ invoker: "public" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }

  const { houseId, olderThanDays } = request.data;
  if (!houseId || typeof houseId !== "string") {
    throw new HttpsError("invalid-argument", "House ID is required");
  }
  if (olderThanDays !== undefined && olderThanDays !== null) {
    if (typeof olderThanDays !== "number" || olderThanDays < 0) {
      throw new HttpsError("invalid-argument", "olderThanDays must be a positive number");
    }
  }

  const db = getFirestore();
  const uid = request.auth.uid;
  const houseRef = db.collection("houses").doc(houseId);

  // Verify admin
  const memberDoc = await houseRef.collection("members").doc(uid).get();
  if (!memberDoc.exists || memberDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can purge archived issues");
  }

  // Query archived issues
  let query = houseRef
    .collection("issues")
    .where("archived", "==", true) as FirebaseFirestore.Query;

  if (olderThanDays != null) {
    const cutoff = Timestamp.fromDate(
      new Date(Date.now() - olderThanDays * 24 * 60 * 60 * 1000)
    );
    query = query.where("createdAt", "<", cutoff);
  }

  const snap = await query.get();
  if (snap.empty) {
    return { success: true, deletedCount: 0 };
  }

  // Delete Storage photos + issue docs in batches
  const bucket = getStorage().bucket();
  const batches: FirebaseFirestore.WriteBatch[] = [];
  let batch = db.batch();
  let count = 0;

  for (const doc of snap.docs) {
    // Delete associated photos (fire-and-forget, don't fail on missing)
    const issueId = doc.id;
    bucket.deleteFiles({ prefix: `houses/${houseId}/issues/${issueId}/`, force: true }).catch(() => {});
    bucket.deleteFiles({ prefix: `houses/${houseId}/resolutions/${issueId}/`, force: true }).catch(() => {});

    batch.delete(doc.ref);
    count++;
    if (count >= 500) {
      batches.push(batch);
      batch = db.batch();
      count = 0;
    }
  }
  if (count > 0) batches.push(batch);

  await Promise.all(batches.map((b) => b.commit()));

  return { success: true, deletedCount: snap.size };
});
```

**Step 2: Add export to `functions/src/index.ts`**

```typescript
export { purgeArchivedIssues } from "./callables/purge-archived-issues";
```

**Step 3: Compile and verify no TypeScript errors**

```bash
cd functions && npm run build
```

**Step 4: Commit**

```
git add functions/src/callables/purge-archived-issues.ts functions/src/index.ts
git commit -m "feat(functions): add purgeArchivedIssues callable with age filter"
```

---

### Task 4: Flutter provider — `dataManagementProvider`

**Files:**
- Create: `lib/src/providers/data_management_provider.dart`

**Step 1: Create the provider**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'house_provider.dart';

final dataManagementProvider =
    NotifierProvider<DataManagementNotifier, AsyncValue<void>>(
        DataManagementNotifier.new);

class DataManagementNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> deleteAccount(String houseId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final functions = ref.read(firebaseFunctionsProvider);
      await functions.httpsCallable('deleteAccount').call({});
      await ref.read(firebaseAuthProvider).signOut();
    });
  }

  Future<void> resetHouseData({
    required String houseId,
    required String scope,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final functions = ref.read(firebaseFunctionsProvider);
      await functions.httpsCallable('resetHouseData').call({
        'houseId': houseId,
        'scope': scope,
      });
      ref.invalidate(currentHouseIdProvider);
    });
  }

  Future<int> purgeArchivedIssues({
    required String houseId,
    int? olderThanDays,
  }) async {
    state = const AsyncLoading();
    int deletedCount = 0;
    state = await AsyncValue.guard(() async {
      final functions = ref.read(firebaseFunctionsProvider);
      final result =
          await functions.httpsCallable('purgeArchivedIssues').call<Map<String, dynamic>>({
        'houseId': houseId,
        if (olderThanDays != null) 'olderThanDays': olderThanDays,
      });
      deletedCount = (result.data['deletedCount'] as num?)?.toInt() ?? 0;
    });
    return deletedCount;
  }

  Future<void> clearLocalCache() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      // Note: clearPersistence() requires no active listeners.
      // In practice this works because the user is on the settings screen.
      await FirebaseFirestore.instance.terminate();
      await FirebaseFirestore.instance.clearPersistence();
    });
  }
}
```

**Step 2: Commit**

```
git add lib/src/providers/data_management_provider.dart
git commit -m "feat: add dataManagementProvider wrapping data clearing Cloud Functions"
```

---

### Task 5: Confirmation dialog widget

**Files:**
- Create: `lib/src/features/settings/widgets/typed_confirm_dialog.dart`

**Step 1: Create reusable typed-confirmation dialog**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

/// Shows a dialog requiring the user to type [confirmText] to proceed.
/// Returns `true` if confirmed, `false` or `null` if cancelled.
Future<bool?> showTypedConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmText,
  String actionLabel = 'Confirm',
  Color actionColor = AppColors.rose,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _TypedConfirmDialog(
      title: title,
      description: description,
      confirmText: confirmText,
      actionLabel: actionLabel,
      actionColor: actionColor,
    ),
  );
}

class _TypedConfirmDialog extends StatefulWidget {
  const _TypedConfirmDialog({
    required this.title,
    required this.description,
    required this.confirmText,
    required this.actionLabel,
    required this.actionColor,
  });

  final String title;
  final String description;
  final String confirmText;
  final String actionLabel;
  final Color actionColor;

  @override
  State<_TypedConfirmDialog> createState() => _TypedConfirmDialogState();
}

class _TypedConfirmDialogState extends State<_TypedConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches =
          _controller.text.trim().toUpperCase() == widget.confirmText.toUpperCase();
      if (matches != _matches) setState(() => _matches = matches);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 16),
          Text(
            'Type "${widget.confirmText}" to confirm:',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.confirmText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            widget.actionLabel,
            style: TextStyle(
              color: _matches ? widget.actionColor : AppColors.slate300,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
```

**Step 2: Commit**

```
git add lib/src/features/settings/widgets/typed_confirm_dialog.dart
git commit -m "feat: add typed confirmation dialog widget for destructive actions"
```

---

### Task 6: Data & Privacy screen

**Files:**
- Create: `lib/src/features/settings/data_privacy_screen.dart`

**Step 1: Create the screen**

This is the largest file. It has four sections matching the design doc: Account Management, House Data, Archived Issues, Local. Each section is a card with action buttons. Destructive actions call `showTypedConfirmDialog`, then invoke `dataManagementProvider`.

Key patterns:
- `ConsumerWidget` with `ref.watch(dataManagementProvider)` for loading state
- `ref.listen(dataManagementProvider, ...)` for error/success snackbars
- Each action button is a `_ActionTile` widget (icon, title, subtitle, onTap)
- The "Purge Archived" section has a dropdown for age filter (All / 30 / 60 / 90 days)
- Loading overlay shown when `dataManagementProvider` is in `AsyncLoading` state
- After `deleteAccount` succeeds, call `context.go('/sign-in')` (router redirect handles the rest)
- After other actions, show success snackbar

Structure:
```
DataPrivacyScreen (ConsumerStatefulWidget)
  ├─ AppBar with back button + "Data & Privacy" title
  ├─ _AccountSection     → Delete My Account
  ├─ _HouseDataSection   → Reset All / Clear Issues / Clear Activity / Reset Leaderboard / Reset Stats
  ├─ _ArchivedSection    → Purge Archived Issues (with age filter dropdown)
  └─ _LocalSection       → Clear App Cache
```

Each `_ActionTile` is a `ListTile`-style row in a white card with icon, title, subtitle, and chevron.

**Step 2: Commit**

```
git add lib/src/features/settings/data_privacy_screen.dart
git commit -m "feat: add Data & Privacy screen with all clearing actions"
```

---

### Task 7: Wire up routing and settings entry point

**Files:**
- Modify: `lib/router.dart` — add `/data-privacy` route
- Modify: `lib/src/features/settings/settings_screen.dart` — add admin-only link to Data & Privacy

**Step 1: Add route in `router.dart`**

Import the new screen and add a `GoRoute` alongside the other `parentNavigatorKey: _rootNavigatorKey` routes:

```dart
import 'src/features/settings/data_privacy_screen.dart';

// Add after the /settings route:
GoRoute(
  parentNavigatorKey: _rootNavigatorKey,
  path: '/data-privacy',
  builder: (context, state) => const DataPrivacyScreen(),
),
```

**Step 2: Add entry point in settings screen**

In `_LiveSettingsScreenState`, before the `_DangerZone` widget (around line 363), add a conditional "Data & Privacy" link visible only to admins:

```dart
if (widget.isAdmin) ...[
  GestureDetector(
    onTap: () => context.push('/data-privacy'),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: const [
          Icon(Icons.shield_outlined, size: 20, color: AppColors.slate700),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Data & Privacy',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: AppColors.slate400),
        ],
      ),
    ),
  ),
  const SizedBox(height: 28),
],
```

**Step 3: Commit**

```
git add lib/router.dart lib/src/features/settings/settings_screen.dart
git commit -m "feat: wire Data & Privacy screen to router and settings (admin-only)"
```

---

### Task 8: Tests

**Files:**
- Create: `test/providers/data_management_provider_test.dart`
- Create: `functions/src/__tests__/delete-account.test.ts` (if test framework exists)

**Step 1: Write Dart provider unit test**

Test that `clearLocalCache` completes without error (the only action testable without Firebase emulator). For the Cloud Function wrappers, test that they call the correct function name with correct parameters using a mock `FirebaseFunctions`.

**Step 2: Run tests**

```bash
flutter test
```

Expected: All tests pass (existing + new).

**Step 3: Commit**

```
git add test/
git commit -m "test: add data management provider tests"
```

---

### Task 9: Analyze and final commit

**Step 1: Run analysis**

```bash
cd functions && npm run build
dart analyze lib/
flutter test
```

All must pass with no errors.

**Step 2: Push and create PR**

```bash
git push -u origin feature/data-clearing
gh pr create --title "feat: data clearing — account deletion, house reset, archive purge" --body "..."
```
