# Sprint 3: Issue System (Live Data) — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace mock data with real Firestore reads/writes across all issue screens. Full lifecycle: create (with photo upload) → claim → resolve → dispute → react.

**Architecture:** Client-side Firestore writes guarded by existing security rules (`firestore.rules:46-72`). Riverpod StreamProviders for real-time UI. Firebase Storage for photo uploads. E2E tests via `integration_test` against Firebase emulators.

**Tech Stack:** Flutter 3.x, Riverpod, Cloud Firestore, Firebase Storage, image_picker, GoRouter, integration_test

**Design doc:** `docs/plans/2026-03-31-sprint3-issue-system-design.md`

---

## Context

**Existing freezed model** (`lib/src/models/issue.dart`):
- `Issue` with fields: id, type (IssueType enum), title?, description?, photoUrl?, createdBy, anonymous, createdAt, assignedTo?, assignedAt?, status (IssueStatus enum: open/inProgress/resolved/disputed/closed), resolvedBy?, resolvedAt?, resolutionPhotoUrl?, resolutionNote?, disputedBy?, disputeAgainst?, disputeReason?, reactions (Map<String,String>), autoCloseAt?, tags, points
- `Issue.fromFirestore(DocumentSnapshot)` already exists
- `Issue.pointsForType(IssueType)` → 5/3/10/5

**Existing provider patterns** (`lib/src/providers/house_provider.dart`):
- `firestoreProvider` — `Provider<FirebaseFirestore>` singleton
- `firebaseFunctionsProvider` — `Provider<FirebaseFunctions>` singleton
- `currentHouseIdProvider` — `FutureProvider<String?>` (house membership query)
- `currentHouseProvider` — `StreamProvider<House?>` (streams house doc)
- `HouseActions` — `NotifierProvider` for callable mutations

**Existing screens** read from `MockData.issues` (mock DTOs with string status like `'in-progress'`). The real model uses `IssueStatus.inProgress` enum.

**Firestore rules** (`firestore.rules:46-72`) already guard: create (createdBy==uid, status==open), claim (assignedTo fields), resolve (resolvedBy fields), dispute (disputedBy!=resolvedBy), react (own uid key only).

**Firebase Storage** emulator configured at port 9199. `firebase_storage: ^12.4.4` already in pubspec.

**Emulators:** Auth :9099, Firestore :8080, Functions :5001, Storage :9199.

---

### Task 1: Add image_picker dependency

**Files:**
- Modify: `pubspec.yaml:50-53`
- Modify: `lib/main.dart`

**Step 1: Add image_picker to pubspec.yaml**

In `pubspec.yaml`, add after the `timeago` line under `# UI`:

```yaml
  # UI
  google_fonts: ^6.2.1
  cached_network_image: ^3.4.1
  timeago: ^3.7.0
  image_picker: ^1.1.2
```

**Step 2: Add Firebase Storage emulator connection in main.dart**

In `lib/main.dart`, add the storage import and emulator connection. After line 6 (`import 'package:cloud_functions/cloud_functions.dart';`), the emulator block already connects Auth, Firestore, Functions. Add Storage:

```dart
import 'package:firebase_storage/firebase_storage.dart';
```

Inside the `if (kDebugMode || _forceEmulators)` block (line 27-31), add after the Functions emulator line:

```dart
      await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
```

**Step 3: Install dependencies**

Run: `flutter pub get`
Expected: resolves successfully

**Step 4: Verify analyze passes**

Run: `flutter analyze --no-fatal-infos`
Expected: no new errors

**Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "chore: add image_picker dependency and Storage emulator config"
```

---

### Task 2: Create issue providers

**Files:**
- Create: `lib/src/providers/issue_provider.dart`
- Test: `test/providers/issue_provider_test.dart`

**Step 1: Write unit tests for issue providers**

Create `test/providers/issue_provider_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macoloc/src/models/issue.dart';
import 'package:macoloc/src/providers/issue_provider.dart';

void main() {
  group('IssueTab', () {
    test('enum has correct values', () {
      expect(IssueTab.values.length, 3);
      expect(IssueTab.all.name, 'all');
      expect(IssueTab.mine.name, 'mine');
      expect(IssueTab.open.name, 'open');
    });
  });

  group('IssueQueryParams', () {
    test('equality works for same params', () {
      final a = IssueQueryParams(houseId: 'h1', tab: IssueTab.all);
      final b = IssueQueryParams(houseId: 'h1', tab: IssueTab.all);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different tab', () {
      final a = IssueQueryParams(houseId: 'h1', tab: IssueTab.all);
      final b = IssueQueryParams(houseId: 'h1', tab: IssueTab.open);
      expect(a, isNot(equals(b)));
    });
  });

  group('filterByType', () {
    final issues = [
      _makeIssue(id: '1', type: IssueType.chore),
      _makeIssue(id: '2', type: IssueType.grocery),
      _makeIssue(id: '3', type: IssueType.repair),
      _makeIssue(id: '4', type: IssueType.chore),
    ];

    test('null filter returns all', () {
      expect(filterByType(issues, null), issues);
    });

    test('filters by type', () {
      final result = filterByType(issues, IssueType.chore);
      expect(result.length, 2);
      expect(result.every((i) => i.type == IssueType.chore), isTrue);
    });

    test('returns empty for no matches', () {
      expect(filterByType(issues, IssueType.other), isEmpty);
    });
  });

  group('filterBySearch', () {
    final issues = [
      _makeIssue(id: '1', title: 'Dish mountain'),
      _makeIssue(id: '2', title: 'Oat milk'),
      _makeIssue(id: '3', title: null),
    ];

    test('empty query returns all', () {
      expect(filterBySearch(issues, ''), issues);
    });

    test('case-insensitive search', () {
      final result = filterBySearch(issues, 'dish');
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('null title excluded from search results', () {
      final result = filterBySearch(issues, 'x');
      expect(result, isEmpty);
    });
  });
}

Issue _makeIssue({
  required String id,
  IssueType type = IssueType.chore,
  String? title,
}) {
  return Issue(
    id: id,
    type: type,
    title: title,
    createdBy: 'uid1',
    createdAt: Timestamp.now(),
    points: Issue.pointsForType(type),
  );
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/providers/issue_provider_test.dart`
Expected: FAIL — `IssueTab`, `IssueQueryParams`, `filterByType`, `filterBySearch` not defined

**Step 3: Write the issue provider**

Create `lib/src/providers/issue_provider.dart`:

```dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/issue.dart';
import 'auth_provider.dart';
import 'house_provider.dart';

// ---------------------------------------------------------------------------
// Query helpers
// ---------------------------------------------------------------------------

enum IssueTab { all, mine, open }

class IssueQueryParams {
  const IssueQueryParams({required this.houseId, required this.tab});

  final String houseId;
  final IssueTab tab;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueQueryParams &&
          other.houseId == houseId &&
          other.tab == tab;

  @override
  int get hashCode => Object.hash(houseId, tab);
}

/// Client-side type filter (applied after Firestore query).
List<Issue> filterByType(List<Issue> issues, IssueType? type) {
  if (type == null) return issues;
  return issues.where((i) => i.type == type).toList();
}

/// Client-side search filter (applied after Firestore query).
List<Issue> filterBySearch(List<Issue> issues, String query) {
  if (query.isEmpty) return issues;
  final q = query.toLowerCase();
  return issues.where((i) => i.title?.toLowerCase().contains(q) ?? false).toList();
}

// ---------------------------------------------------------------------------
// Stream providers
// ---------------------------------------------------------------------------

/// Streams issues for a given house + tab (All / Mine / Open).
/// Type filtering and search are applied client-side.
final issuesStreamProvider =
    StreamProvider.family<List<Issue>, IssueQueryParams>((ref, params) {
  final db = ref.watch(firestoreProvider);
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;

  Query<Map<String, dynamic>> query =
      db.collection('houses/${params.houseId}/issues');

  switch (params.tab) {
    case IssueTab.all:
      query = query.orderBy('createdAt', descending: true).limit(50);
      break;
    case IssueTab.mine:
      if (uid == null) return Stream.value([]);
      query = query
          .where('assignedTo', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50);
      break;
    case IssueTab.open:
      query = query
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(50);
      break;
  }

  return query.snapshots().map((snap) =>
      snap.docs.map((doc) => Issue.fromFirestore(doc)).toList());
});

/// Streams a single issue document for the detail screen.
final issueDetailProvider =
    StreamProvider.family<Issue?, (String houseId, String issueId)>((ref, params) {
  final (houseId, issueId) = params;
  final db = ref.watch(firestoreProvider);

  return db
      .collection('houses/$houseId/issues')
      .doc(issueId)
      .snapshots()
      .map((doc) => doc.exists ? Issue.fromFirestore(doc) : null);
});

// ---------------------------------------------------------------------------
// Firebase Storage provider
// ---------------------------------------------------------------------------

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// ---------------------------------------------------------------------------
// Issue actions
// ---------------------------------------------------------------------------

final issueActionsProvider =
    NotifierProvider<IssueActions, AsyncValue<void>>(IssueActions.new);

class IssueActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  FirebaseFirestore get _db => ref.read(firestoreProvider);
  FirebaseStorage get _storage => ref.read(firebaseStorageProvider);
  String? get _uid => ref.read(authStateProvider).valueOrNull?.uid;

  CollectionReference<Map<String, dynamic>> _issuesCol(String houseId) =>
      _db.collection('houses/$houseId/issues');

  /// Upload a photo to Storage, return the download URL.
  Future<String?> _uploadPhoto({
    required String houseId,
    required String issueId,
    required XFile photo,
    String filename = 'photo.jpg',
  }) async {
    final storageRef = _storage
        .ref('houses/$houseId/issues/$issueId/$filename');
    await storageRef.putFile(File(photo.path));
    return storageRef.getDownloadURL();
  }

  /// Create a new issue with optional photo.
  Future<String> create({
    required String houseId,
    required IssueType type,
    String? title,
    String? description,
    bool anonymous = false,
    XFile? photo,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();

    try {
      // Generate ID upfront so we can use it for Storage path
      final docRef = _issuesCol(houseId).doc();
      final issueId = docRef.id;

      // Upload photo if provided
      String? photoUrl;
      if (photo != null) {
        photoUrl = await _uploadPhoto(
          houseId: houseId,
          issueId: issueId,
          photo: photo,
        );
      }

      // Write issue doc
      final issue = Issue(
        id: issueId,
        type: type,
        title: title,
        description: description,
        photoUrl: photoUrl,
        createdBy: uid,
        anonymous: anonymous,
        createdAt: Timestamp.now(),
        points: Issue.pointsForType(type),
      );

      await docRef.set(issue.toJson());
      state = const AsyncData(null);
      return issueId;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Claim an open issue (assign to self).
  Future<void> claim({
    required String houseId,
    required String issueId,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _issuesCol(houseId).doc(issueId).update({
        'assignedTo': uid,
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'in_progress',
      });
    });
  }

  /// Resolve an issue with optional note and resolution photo.
  Future<void> resolve({
    required String houseId,
    required String issueId,
    String? note,
    XFile? resolutionPhoto,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      String? resolutionPhotoUrl;
      if (resolutionPhoto != null) {
        resolutionPhotoUrl = await _uploadPhoto(
          houseId: houseId,
          issueId: issueId,
          photo: resolutionPhoto,
          filename: 'resolution_photo.jpg',
        );
      }

      await _issuesCol(houseId).doc(issueId).update({
        'resolvedBy': uid,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolutionNote': note,
        'resolutionPhotoUrl': resolutionPhotoUrl,
        'status': 'resolved',
      });
    });
  }

  /// Dispute a resolved issue.
  Future<void> dispute({
    required String houseId,
    required String issueId,
    required String reason,
    required String resolvedByUid,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _issuesCol(houseId).doc(issueId).update({
        'disputedBy': uid,
        'disputeAgainst': resolvedByUid,
        'disputeReason': reason,
        'status': 'disputed',
      });
    });
  }

  /// Toggle a reaction emoji. If the current user already has this emoji,
  /// remove it. Otherwise, set it.
  Future<void> react({
    required String houseId,
    required String issueId,
    required String emoji,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not authenticated');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final docRef = _issuesCol(houseId).doc(issueId);
      final snap = await docRef.get();
      if (!snap.exists) throw StateError('Issue not found');

      final issue = Issue.fromFirestore(snap);
      final currentEmoji = issue.reactions[uid];

      if (currentEmoji == emoji) {
        // Remove reaction
        await docRef.update({'reactions.$uid': FieldValue.delete()});
      } else {
        // Set reaction
        await docRef.update({'reactions.$uid': emoji});
      }
    });
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/providers/issue_provider_test.dart`
Expected: All 8 tests PASS

**Step 5: Run all tests to verify no regressions**

Run: `flutter test`
Expected: 34 tests (26 existing + 8 new), all PASS

**Step 6: Commit**

```bash
git add lib/src/providers/issue_provider.dart test/providers/issue_provider_test.dart
git commit -m "feat: add issue providers — streams, actions, filter helpers"
```

---

### Task 3: Wire IssuesListScreen to Firestore

**Files:**
- Modify: `lib/src/features/issues/issues_list_screen.dart`
- Modify: `lib/src/features/issues/widgets/issue_card.dart`

**Step 1: Convert IssuesListScreen from StatefulWidget to ConsumerStatefulWidget**

Rewrite `lib/src/features/issues/issues_list_screen.dart`. Key changes:

1. Import `flutter_riverpod`, `issue_provider.dart`, `issue.dart`, `house_provider.dart`, `auth_provider.dart`
2. Remove `mock_data.dart` import
3. Convert `StatefulWidget` → `ConsumerStatefulWidget`, `State` → `ConsumerState`
4. Replace `_filteredIssues` getter with a provider watch + client-side filtering
5. Wrap list in `AsyncValue.when()` for loading/error/data states
6. Pass `Issue` (not `MockIssue`) to `IssueCard`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/issue.dart';
import '../../providers/house_provider.dart';
import '../../providers/issue_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/issue_card.dart';

class IssuesListScreen extends ConsumerStatefulWidget {
  const IssuesListScreen({super.key});

  @override
  ConsumerState<IssuesListScreen> createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends ConsumerState<IssuesListScreen> {
  int _activeTab = 0; // 0=All, 1=Mine, 2=Open
  IssueType? _activeTypeFilter; // null = All types
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _tabLabels = ['All', 'Mine', 'Open'];
  static const List<String> _filterLabels = ['All', 'Chore', 'Grocery', 'Repair', 'Other'];
  static const List<IssueType?> _filterTypes = [null, IssueType.chore, IssueType.grocery, IssueType.repair, IssueType.other];

  IssueTab get _issueTab => IssueTab.values[_activeTab];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final houseId = ref.watch(currentHouseIdProvider).valueOrNull;

    // No house yet (shouldn't happen in normal flow)
    if (houseId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final issuesAsync = ref.watch(
      issuesStreamProvider(IssueQueryParams(houseId: houseId, tab: _issueTab)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Sticky header
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            shadowColor: const Color(0x0A000000),
            elevation: 1,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: AppColors.surface),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(160),
              child: _StickyHeader(
                searchController: _searchController,
                activeTab: _activeTab,
                activeFilter: _filterLabels[_filterTypes.indexOf(_activeTypeFilter)],
                onTabChanged: (i) => setState(() => _activeTab = i),
                onFilterChanged: (f) => setState(() {
                  final idx = _filterLabels.indexOf(f);
                  _activeTypeFilter = _filterTypes[idx];
                }),
                tabs: _tabLabels,
                filters: _filterLabels,
              ),
            ),
          ),

          // Issue list with async states
          ...issuesAsync.when(
            loading: () => [
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (err, _) => [
              SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
            ],
            data: (issues) {
              // Apply client-side filters
              var filtered = filterByType(issues, _activeTypeFilter);
              filtered = filterBySearch(filtered, _searchQuery);

              if (filtered.isEmpty) {
                return [const SliverFillRemaining(child: _EmptyState())];
              }

              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IssueCard(
                          issue: filtered[index],
                          houseId: houseId,
                        ),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}
```

Keep the existing `_StickyHeader` and `_EmptyState` classes unchanged — they only use strings and callbacks, no mock data.

**Step 2: Rewrite IssueCard to accept `Issue` instead of `MockIssue`**

Rewrite `lib/src/features/issues/widgets/issue_card.dart`:

Key changes:
1. Accept `Issue` + `String houseId` instead of `MockIssue`
2. Use `IssueType` enum for type colors/icons instead of string comparison
3. Use `IssueStatus` enum for status config instead of string comparison
4. Claim button calls `ref.read(issueActionsProvider.notifier).claim()`
5. Convert to `ConsumerWidget`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/issue.dart';
import '../../../providers/issue_provider.dart';
import '../../../theme/app_theme.dart';

class IssueCard extends ConsumerWidget {
  const IssueCard({super.key, required this.issue, required this.houseId});

  final Issue issue;
  final String houseId;

  Color _typeColor() {
    switch (issue.type) {
      case IssueType.chore:
        return AppColors.orange;
      case IssueType.grocery:
        return AppColors.emerald;
      case IssueType.repair:
        return AppColors.blue;
      case IssueType.other:
        return AppColors.indigo;
    }
  }

  ({Color bg, Color border, Color text, Color icon, IconData iconData, String label}) _statusConfig() {
    switch (issue.status) {
      case IssueStatus.open:
        return (
          bg: AppColors.orange50,
          border: AppColors.orange300,
          text: AppColors.orange,
          icon: AppColors.orange,
          iconData: Icons.radio_button_unchecked,
          label: 'OPEN',
        );
      case IssueStatus.inProgress:
        return (
          bg: AppColors.blue50,
          border: AppColors.blue100,
          text: AppColors.blue600,
          icon: AppColors.blue600,
          iconData: Icons.autorenew,
          label: 'IN PROGRESS',
        );
      case IssueStatus.resolved:
        return (
          bg: AppColors.emerald50,
          border: AppColors.emerald100,
          text: AppColors.emerald,
          icon: AppColors.emerald,
          iconData: Icons.check_circle_outline,
          label: 'RESOLVED',
        );
      case IssueStatus.disputed:
        return (
          bg: AppColors.rose50,
          border: AppColors.rose100,
          text: AppColors.rose,
          icon: AppColors.rose,
          iconData: Icons.chat_bubble_outline,
          label: 'DISPUTED',
        );
      case IssueStatus.closed:
        return (
          bg: AppColors.slate100,
          border: AppColors.slate200,
          text: AppColors.slate500,
          icon: AppColors.slate400,
          iconData: Icons.check_circle,
          label: 'CLOSED',
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = _statusConfig();
    final typeColor = _typeColor();
    final timeStr = timeago.format(issue.createdAt.toDate());

    return GestureDetector(
      onTap: () => context.push('/issues/${issue.id}'),
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left 1/3: Photo thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
              child: SizedBox(
                width: 106,
                height: 128,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    issue.photoUrl != null
                        ? Image.network(
                            issue.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _TypePlaceholder(color: typeColor, type: issue.type),
                          )
                        : _TypePlaceholder(color: typeColor, type: issue.type),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          issue.type.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right 2/3: Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusBadge(config: status),
                    Text(
                      issue.title ?? issue.type.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate800,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        issue.assignedTo != null
                            ? const _AssignedBadge()
                            : _ClaimButton(
                                onTap: () {
                                  ref.read(issueActionsProvider.notifier).claim(
                                    houseId: houseId,
                                    issueId: issue.id,
                                  );
                                },
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypePlaceholder extends StatelessWidget {
  const _TypePlaceholder({required this.color, required this.type});

  final Color color;
  final IssueType type;

  IconData get _icon {
    switch (type) {
      case IssueType.chore:
        return Icons.cleaning_services_outlined;
      case IssueType.grocery:
        return Icons.shopping_cart_outlined;
      case IssueType.repair:
        return Icons.build_outlined;
      case IssueType.other:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: Icon(_icon, color: color.withValues(alpha: 0.6), size: 36),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.config});

  final ({Color bg, Color border, Color text, Color icon, IconData iconData, String label}) config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.iconData, size: 10, color: config.icon),
          const SizedBox(width: 3),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: config.text,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedBadge extends StatelessWidget {
  const _AssignedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.emerald50,
        border: Border.all(color: AppColors.emerald100, width: 1.5),
      ),
      child: const Icon(Icons.person, size: 14, color: AppColors.emerald),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.emerald,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Claim',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
```

**Step 3: Verify analyze passes**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

**Step 4: Run all tests**

Run: `flutter test`
Expected: All tests pass (some existing tests may need mock data fix if they import IssueCard — check)

**Step 5: Commit**

```bash
git add lib/src/features/issues/issues_list_screen.dart lib/src/features/issues/widgets/issue_card.dart
git commit -m "feat: wire IssuesListScreen and IssueCard to Firestore streams"
```

---

### Task 4: Wire CreateIssueScreen to Firestore + image_picker

**Files:**
- Modify: `lib/src/features/issues/create_issue_screen.dart`

**Step 1: Rewrite CreateIssueScreen**

Key changes:
1. Convert to `ConsumerStatefulWidget`
2. Add `XFile? _photo` state for picked image
3. Camera button → `ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 85)`
4. Gallery button → same with `ImageSource.gallery`
5. `_post()` calls `issueActionsProvider.create()` with the form data + photo
6. Show loading overlay during submission
7. Remove `MockData.currentUser` references
8. Show actual photo preview when `_photo != null`

In the `_CameraView`, wire the gallery button:
```dart
onTap: () async {
  final picker = ImagePicker();
  final photo = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    imageQuality: 85,
  );
  if (photo != null) onPhotoPicked(photo);
},
```

Wire the capture button similarly with `ImageSource.camera`.

In `_CreateIssueScreenState`:
```dart
XFile? _photo;
bool _isSubmitting = false;

void _onPhotoPicked(XFile photo) {
  setState(() {
    _photo = photo;
    _showDetails = true;
  });
}

Future<void> _post() async {
  final houseId = ref.read(currentHouseIdProvider).valueOrNull;
  if (houseId == null) return;

  setState(() => _isSubmitting = true);

  try {
    await ref.read(issueActionsProvider.notifier).create(
      houseId: houseId,
      type: IssueType.values.firstWhere(
        (t) => t.name == _selectedType.toLowerCase(),
        orElse: () => IssueType.chore,
      ),
      title: _titleController.text.isNotEmpty ? _titleController.text : null,
      anonymous: _isAnonymous,
      photo: _photo,
    );
    if (mounted) context.pop();
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}
```

In `_PhotoPreview`, show the actual image when available:
```dart
// Replace gradient placeholder with:
_photo != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.file(
          File(_photo!.path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      )
    : Container(/* existing gradient placeholder */),
```

**Step 2: Verify analyze passes**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

**Step 3: Run all tests**

Run: `flutter test`
Expected: All pass

**Step 4: Commit**

```bash
git add lib/src/features/issues/create_issue_screen.dart
git commit -m "feat: wire CreateIssueScreen to Firestore + image_picker"
```

---

### Task 5: Wire IssueDetailScreen to Firestore + actions

**Files:**
- Modify: `lib/src/features/issues/issue_detail_screen.dart`

**Step 1: Rewrite IssueDetailScreen**

Key changes:
1. Convert to `ConsumerWidget`
2. Accept `String issueId` (already does) — also need `houseId` from provider
3. Replace `MockData.issues.firstWhere()` with `ref.watch(issueDetailProvider((houseId, issueId)))`
4. Use `IssueType`/`IssueStatus` enums instead of strings
5. Replace `MockUser` references with uid strings (we don't have a members provider yet — show uid or "Anonymous" for now)
6. Wire action buttons:
   - Claim → `issueActionsProvider.claim()`
   - Resolve → show bottom sheet → `issueActionsProvider.resolve()`
   - Dispute → show dialog with reason field → `issueActionsProvider.dispute()`
   - React (Props button) → `issueActionsProvider.react(emoji: '👏')`
7. Wrap in `AsyncValue.when()` for loading/error/data states

For the `_BottomActionBar`, pass callbacks and use `IssueStatus` enum:

```dart
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.issue,
    required this.currentUid,
    required this.onClaim,
    required this.onResolve,
    required this.onDispute,
    required this.onReact,
  });

  final Issue issue;
  final String? currentUid;
  final VoidCallback onClaim;
  final VoidCallback onResolve;
  final VoidCallback onDispute;
  final VoidCallback onReact;

  @override
  Widget build(BuildContext context) {
    // ... use issue.status enum switch
    switch (issue.status) {
      case IssueStatus.open:
        return _ActionButton(label: 'Claim Issue', ..., onTap: onClaim);
      case IssueStatus.inProgress:
        if (issue.assignedTo == currentUid) {
          return _ActionButton(label: 'Mark Resolved', ..., onTap: onResolve);
        }
        return const Center(child: Text('Assigned to someone else'));
      case IssueStatus.resolved:
        if (issue.resolvedBy != currentUid) {
          return Row(children: [
            _ActionButton(label: 'Dispute', ..., onTap: onDispute),
            _ActionButton(label: 'Props', ..., onTap: onReact),
          ]);
        }
        return _ActionButton(label: 'Props', ..., onTap: onReact);
      case IssueStatus.disputed:
      case IssueStatus.closed:
        return const Center(child: Text('No actions available'));
    }
  }
}
```

For the resolve bottom sheet:
```dart
void _showResolveSheet(BuildContext context, WidgetRef ref, String houseId, String issueId) {
  final noteController = TextEditingController();
  showModalBottomSheet(
    context: context,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Resolution Note (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(controller: noteController, maxLines: 3, decoration: InputDecoration(hintText: 'How did you fix it?')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(issueActionsProvider.notifier).resolve(
                houseId: houseId,
                issueId: issueId,
                note: noteController.text.isNotEmpty ? noteController.text : null,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Resolution'),
          ),
        ],
      ),
    ),
  );
}
```

For the dispute dialog:
```dart
void _showDisputeDialog(BuildContext context, WidgetRef ref, String houseId, Issue issue) {
  final reasonController = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Dispute Resolution'),
      content: TextField(controller: reasonController, maxLines: 2, decoration: InputDecoration(hintText: 'Why are you disputing?')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (reasonController.text.isNotEmpty) {
              ref.read(issueActionsProvider.notifier).dispute(
                houseId: houseId,
                issueId: issue.id,
                reason: reasonController.text,
                resolvedByUid: issue.resolvedBy!,
              );
              Navigator.pop(ctx);
            }
          },
          child: const Text('Dispute'),
        ),
      ],
    ),
  );
}
```

**Step 2: Verify analyze passes**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

**Step 3: Run all tests**

Run: `flutter test`
Expected: All pass

**Step 4: Commit**

```bash
git add lib/src/features/issues/issue_detail_screen.dart
git commit -m "feat: wire IssueDetailScreen to Firestore with claim/resolve/dispute/react actions"
```

---

### Task 6: Update router to pass houseId to detail screen

**Files:**
- Modify: `lib/router.dart`

**Step 1: Check if IssueDetailScreen needs houseId**

The detail screen will use `ref.watch(currentHouseIdProvider)` internally (same pattern as IssuesListScreen), so no router change is strictly needed. But verify the route still compiles with the new `ConsumerWidget` signature.

Run: `flutter analyze --no-fatal-infos`

If clean, no changes needed to router. Skip to commit.

**Step 2: Commit (if any changes)**

```bash
git add lib/router.dart
git commit -m "chore: verify router compatibility with new issue screens"
```

---

### Task 7: Write E2E integration tests

**Files:**
- Create: `integration_test/issue_flow_test.dart`

**Step 1: Create integration test directory and test file**

Create `integration_test/issue_flow_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macoloc/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Issue lifecycle E2E', () {
    testWidgets('create issue flow — type selection and post', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaColocApp()),
      );
      await tester.pumpAndSettle();

      // Should land on /home (dev bypass with placeholder Firebase)
      expect(find.text('Home'), findsOneWidget);

      // Navigate to create issue via FAB
      // The FAB is the orange button in the bottom nav
      final fab = find.byIcon(Icons.add);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Should see "NEW ISSUE" camera view
      expect(find.text('NEW ISSUE'), findsOneWidget);

      // Tap capture to go to details form (placeholder camera)
      // The capture button is the large center circle
      // In dev/test mode without camera, just tap to go to details
      final captureArea = find.byWidgetPredicate(
        (w) => w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      // Tap the screen center to trigger capture
      await tester.tapAt(const Offset(200, 400));
      await tester.pumpAndSettle();

      // Should see details form
      expect(find.text('Details'), findsOneWidget);

      // Select type "Grocery"
      await tester.tap(find.text('Grocery'));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(
        find.byType(TextField).last,
        'Test issue from E2E',
      );
      await tester.pumpAndSettle();

      // Tap "Post to House"
      await tester.tap(find.text('Post to House'));
      await tester.pumpAndSettle();

      // Should navigate back (pop)
      // Verify we're back on a main screen
      expect(find.text('NEW ISSUE'), findsNothing);
    });
  });
}
```

**Note:** This is a starter E2E test. Full lifecycle tests (create → see in list → claim → resolve → dispute) require the Firebase emulators running. These tests verify the basic navigation and form flow works. More comprehensive tests should be added as the provider layer is validated.

**Step 2: Add integration_test to pubspec.yaml**

In `pubspec.yaml` under `dev_dependencies:`, add:

```yaml
  integration_test:
    sdk: flutter
```

**Step 3: Run pub get**

Run: `flutter pub get`

**Step 4: Verify the test compiles**

Run: `flutter test integration_test/issue_flow_test.dart -d chrome`

Note: This requires Chrome and may require emulators for full Firestore integration. For CI, we'll add this in the next task.

**Step 5: Commit**

```bash
git add integration_test/ pubspec.yaml pubspec.lock
git commit -m "test: add E2E integration test skeleton for issue lifecycle"
```

---

### Task 8: Update CI for integration tests

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: Add integration test job to CI**

Add a new job to `.github/workflows/ci.yml` after the `functions` job:

```yaml
  integration:
    name: Integration Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.41.4"
          channel: stable
          cache: true

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Install Flutter dependencies
        run: flutter pub get

      - name: Install Functions dependencies
        run: cd functions && npm ci

      - name: Build Functions
        run: cd functions && npm run build

      - name: Start Firebase emulators
        run: firebase emulators:start --only auth,firestore,storage,functions &
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

      - name: Wait for emulators
        run: |
          for i in $(seq 1 30); do
            curl -s http://localhost:4400/ > /dev/null 2>&1 && break
            sleep 2
          done

      - name: Run integration tests
        run: flutter test integration_test/ -d web-server --dart-define=CI=true
```

**Step 2: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add integration test job with Firebase emulators"
```

---

### Task 9: Clean up and verify

**Files:**
- Verify: all screens compile and run

**Step 1: Run full analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors (6 pre-existing warnings in generated files only)

**Step 2: Run all unit tests**

Run: `flutter test`
Expected: All tests pass (26 existing + 8 new provider tests = 34)

**Step 3: Manual verification with emulators**

In Terminal 1:
```bash
firebase emulators:start
```

In Terminal 2:
```bash
flutter run -d chrome
```

Verify:
- Issues list shows empty state (no issues in emulator yet)
- FAB opens create screen
- Camera/gallery buttons work (or show permission dialogs on web)
- Create issue with type + title → appears in list
- Tap issue card → detail screen loads
- Claim button works → status changes
- Resolve flow works → status changes
- All tabs (All/Mine/Open) filter correctly

**Step 4: Final commit**

If any small fixes were needed:

```bash
git add -A
git commit -m "fix: address lint and integration issues from Sprint 3 wiring"
```

---

## Summary

| Task | Description | New Tests |
|------|-------------|-----------|
| 1 | Add image_picker + Storage emulator config | — |
| 2 | Create issue providers (streams + actions + filter helpers) | 8 unit tests |
| 3 | Wire IssuesListScreen + IssueCard to Firestore | — |
| 4 | Wire CreateIssueScreen to Firestore + image_picker | — |
| 5 | Wire IssueDetailScreen with all lifecycle actions | — |
| 6 | Verify router compatibility | — |
| 7 | E2E integration test skeleton | 1 integration test |
| 8 | Update CI for integration tests | — |
| 9 | Clean up and manual verification | — |

**Total new tests:** 8 unit + 1 E2E = 9
**Existing tests:** 26 (must not regress)
