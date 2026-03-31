# Sprint 3: Issue System (Live Data) — Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace mock data with real Firestore reads/writes across all issue screens. Full lifecycle: create (with photo upload) → claim → resolve → dispute → react.

**Architecture:** Client-side Firestore writes guarded by existing security rules. Riverpod StreamProviders for real-time UI updates. Firebase Storage for photo uploads. No new Cloud Functions this sprint.

**Tech Stack:** Flutter + Riverpod + Firestore + Firebase Storage + image_picker + integration_test

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Issue creation | Client-side Firestore write | Security rules already enforce `createdBy == auth.uid` and `status == open` |
| List querying | Base query per tab + client-side type filter | 3 simple queries, no composite indexes, type filter on small dataset is negligible |
| Lifecycle scope | Full: create, claim, resolve, dispute, react | Rules handle all operations; UI already expects all states |
| Auto-close | Deferred to Sprint 4 | Needs scheduled Cloud Function |
| Mock data | Retired from issue screens | Emulators required for dev; mock stays for home screen activity feed |
| Testing | E2E with `integration_test` against emulators | Real Firestore reads/writes, no mocks, built-in Flutter package |

---

## 1. Provider Architecture

New file: `lib/src/providers/issue_provider.dart`

### issuesStreamProvider(tab, houseId)

`StreamProvider.family` returning `List<Issue>` from Firestore.

- **All** tab: `issues` collection ordered by `createdAt desc`, limit 50
- **Mine** tab: `.where('assignedTo', isEqualTo: uid)`
- **Open** tab: `.where('status', isEqualTo: 'open')`

Type filtering and search applied client-side in the UI layer.

### issueDetailProvider(houseId, issueId)

`StreamProvider.family` for a single issue doc. Real-time updates on the detail screen.

### issueActionsProvider

`NotifierProvider` with methods:

- `create(houseId, type, title, description, anonymous, photoFile?)` — writes doc + uploads photo
- `claim(houseId, issueId)` — sets `assignedTo`, `assignedAt`, `status: in_progress`
- `resolve(houseId, issueId, note?, photoFile?)` — sets resolution fields + `status: resolved`
- `dispute(houseId, issueId, reason)` — sets dispute fields + `status: disputed`
- `react(houseId, issueId, emoji)` — toggles reaction in `reactions` map

---

## 2. Photo Upload Flow

**Storage path:** `houses/{houseId}/issues/{issueId}/photo.jpg` (and `resolution_photo.jpg` for resolve)

**Flow in create():**

1. Generate issue ID upfront via `collection(...).doc().id`
2. If photo file provided:
   - Use `image_picker` with `maxWidth: 1024` and `imageQuality: 85` for compression
   - Upload to Storage at the path above
   - Get download URL
3. Write issue doc to Firestore with `photoUrl` set to download URL (or null)

**Error handling:** If upload fails, don't create the issue doc. If doc write fails after upload, leave the orphan file (negligible cost).

**New dependency:** `image_picker: ^1.1.2`

---

## 3. Screen Wiring

### IssuesListScreen

- Replace `MockData.issues` with `ref.watch(issuesStreamProvider(tab, houseId))`
- `AsyncValue` handling: loading spinner, error state, data state
- Tab switches change provider parameter → new stream
- Type filter chips + search remain client-side on the data list
- IssueCard "Claim" button calls `issueActionsProvider.claim()`

### CreateIssueScreen

- Camera button → `ImagePicker.pickImage(source: camera, maxWidth: 1024, imageQuality: 85)`
- Gallery button → `source: gallery` with same params
- Form submission calls `issueActionsProvider.create()` with picked file
- Loading overlay during create
- On success: `context.pop()`

### IssueDetailScreen

- Replace `MockData.issues.firstWhere()` with `ref.watch(issueDetailProvider(houseId, issueId))`
- Action bar buttons wired to `issueActionsProvider`:
  - **Claim** — visible when `assignedTo == null`
  - **Resolve** — visible when assigned to current user
  - **Dispute** — visible when resolved by someone else
  - **React** — toggle on tap
- Resolve action: bottom sheet for optional note + resolution photo

### HomeScreen

Activity feed stays mock. Wiring it requires an activity/event log collection (Sprint 4+ scope).

---

## 4. Testing Strategy

### E2E tests (`integration_test/`)

Using Flutter's built-in `integration_test` package against running Firebase emulators.

**Test scenarios:**

- **Issue creation flow:** Open create screen → pick type → enter title → submit → verify appears in issues list
- **Claim flow:** Create issue → tap Claim on card → verify status changes to in_progress, assignee set
- **Resolve flow:** Claim issue → open detail → tap Resolve → enter note → verify status changes to resolved
- **Dispute flow:** Resolve issue (as user A) → dispute (as user B) → verify status changes to disputed
- **Reaction toggle:** Open detail → tap reaction → verify added; tap again → verify removed
- **Tab filtering:** Create issues with different statuses → verify All/Mine/Open tabs show correct subsets
- **Type filtering:** Create issues with different types → verify filter chips work

### Existing tests

26 unit tests must not regress. `mock_data.dart` stays (used by home screen).

### CI

Emulators must be running for E2E tests. Update `ci.yml` to start emulators before running integration tests.

---

## 5. New Dependencies

| Package | Purpose |
|---------|---------|
| `image_picker: ^1.1.2` | Camera + gallery photo selection with built-in compression |
| `integration_test` (Flutter SDK) | E2E test framework |

---

## 6. Files Changed

| File | Action |
|------|--------|
| `lib/src/providers/issue_provider.dart` | **Create** — streams + actions |
| `lib/src/features/issues/issues_list_screen.dart` | **Modify** — Firestore stream, AsyncValue, claim action |
| `lib/src/features/issues/create_issue_screen.dart` | **Modify** — image_picker, Firestore write, upload |
| `lib/src/features/issues/issue_detail_screen.dart` | **Modify** — Firestore stream, action buttons, resolve sheet |
| `lib/src/features/issues/widgets/issue_card.dart` | **Modify** — claim callback, real photo URL |
| `pubspec.yaml` | **Modify** — add image_picker |
| `integration_test/issue_flow_test.dart` | **Create** — E2E tests |
| `.github/workflows/ci.yml` | **Modify** — add emulator + integration test job |

---

## Out of Scope

- Auto-close (Sprint 4 — needs scheduled Cloud Function)
- Activity feed wiring (needs event log collection)
- Presence toggle wiring (needs member state management)
- Leaderboard wiring (needs points engine)
- Photo thumbnails (can add Storage trigger later)
- Offline support / caching
