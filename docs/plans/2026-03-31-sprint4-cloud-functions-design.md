# Sprint 4: Cloud Functions + Client Wiring — Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add scheduled Cloud Functions (auto-close issues, reset presence, create monthly deep clean) and wire the home screen (presence toggle, who's around) and deep clean screen to Firestore. Full end-to-end features.

**Architecture:** Scheduled Cloud Functions for background automation. New callables for deep clean room operations. Riverpod StreamProviders for real-time UI. Client-side Firestore writes for presence toggle (rules already permit self-update).

**Tech Stack:** Flutter + Riverpod + Firestore + Cloud Functions v2 (onSchedule, onCall) + firebase-functions-test

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Scope | Backend + client wiring | Make features usable end-to-end, not just backend stubs |
| Deep clean lifecycle | Self-assign only | Volunteer/auto-assign deferred (YAGNI) |
| Presence reset | Time-based daily reset | Scheduled function resets members stale > 24h |
| Auto-close frequency | Daily at 2am | Sufficient precision for a household app |

---

## 1. Scheduled Cloud Functions

New directory: `functions/src/scheduled/`

### auto-close-issues.ts

`onSchedule("every day 02:00")`

- Queries all houses
- For each house: queries issues where `status == resolved` and `autoCloseAt < now`
- Batch-updates matching issues to `status: closed`, `closedAt: now`
- `autoCloseAt` is set client-side when resolving, computed as `resolvedAt + disputeWindowHours`

### reset-presence.ts

`onSchedule("every day 00:00")`

- Queries all houses
- For each house: queries members where `presenceUpdatedAt` < 24h ago
- Batch-updates stale members to `presence: away`, `presenceUpdatedAt: now`

### create-deep-clean.ts

`onSchedule("every day 09:00")`

- For each house: checks if today matches `settings.deepCleanDay` AND current month has no deep clean doc yet
- If match: creates `deepCleans/{YYYY-MM}` doc with status `inProgress`, rooms from house config, all assignments empty
- Idempotent: checks `lastDeepCleanMonth` to avoid duplicate creation

---

## 2. New Callables for Deep Clean

New files in `functions/src/callables/`:

### claimRoom.ts

`onCall`

- Input: `{ houseId, cleanId, roomName }`
- Validates: member of house, room exists in deep clean doc, room not already assigned
- Transaction: sets `assignments[roomName] = { uid, assignedAt, completed: false }`

### completeRoom.ts

`onCall`

- Input: `{ houseId, cleanId, roomName }`
- Validates: member of house, room assigned to caller
- Transaction: sets `assignments[roomName].completed = true`, `completedAt: now`
- If all rooms completed: updates deep clean status to `completed`

**Why callables?** Firestore rules block all client writes to `deepCleans`. Matches the established pattern (house mutations go through callables). Keeps assignment logic atomic via transactions.

---

## 3. Client-Side Providers

### member_provider.dart (NEW)

- `membersStreamProvider(houseId)` — StreamProvider.family streaming `members` subcollection, returns `List<Member>`
- `presenceActionsProvider` — Notifier with `togglePresence(houseId)` that writes `presence` + `presenceUpdatedAt` directly to Firestore (rules already allow self-update)

### deep_clean_provider.dart (NEW)

- `currentDeepCleanProvider(houseId)` — StreamProvider.family streaming the current month's deep clean doc (`deepCleans/{YYYY-MM}`)
- `deepCleanActionsProvider` — Notifier with `claimRoom(houseId, cleanId, roomName)` and `completeRoom(houseId, cleanId, roomName)` that call the new callables

### issue_provider.dart (MODIFY)

- Update `resolve()` to set `autoCloseAt = resolvedAt + disputeWindowHours` when resolving
- Reads house settings for `disputeWindowHours` (default 48h)

---

## 4. Screen Wiring

### home_screen.dart

- Replace local `_isHome` state with `ref.watch(membersStreamProvider(houseId))`
- `_PresenceToggle` calls `presenceActionsProvider.togglePresence()`
- `_WhosAround` reads from members stream instead of `MockData.users`
- Placeholder mode fallback: keep mock data when `isPlaceholder`

### deep_clean_screen.dart

- Replace local `_rooms` state with `ref.watch(currentDeepCleanProvider(houseId))`
- `_claimRoom` calls `deepCleanActionsProvider.claimRoom()`
- `_completeRoom` calls `deepCleanActionsProvider.completeRoom()`
- Progress bar computed from completed assignments / total rooms
- Empty state when no deep clean exists for current month
- Placeholder mode fallback: keep mock data

### issue_detail_screen.dart

- Show `closed` status in timeline/status badge
- No action buttons when status is `closed`

---

## 5. Firestore Rules Updates

- **`issues` collection** — Add `autoCloseAt` to the allowed fields in the resolve update path
- **`deepCleans`** — No changes (callable-only writes already enforced)
- **`members`** — No changes (self-update of `presence` + `presenceUpdatedAt` already allowed)

---

## 6. Testing Strategy

### Backend (TypeScript)

- Unit tests for each scheduled function using `firebase-functions-test`
- Auto-close: resolved issue with past `autoCloseAt` → verify status becomes `closed`
- Presence reset: stale member → verify reset to `away`
- Deep clean creation: matching `deepCleanDay` → verify doc created with correct rooms
- Callables: claimRoom (success + already-assigned rejection), completeRoom (success + wrong-user rejection + all-complete status update)

### Client (Dart)

- Unit tests for new providers: `member_provider_test.dart`, `deep_clean_provider_test.dart`
- Test `autoCloseAt` computation in modified `resolve()`
- Existing 35 tests must not regress

### Integration

- Extend existing smoke test (app boots without crashing)
- No new integration test complexity this sprint

### CI

- Add `npm test` to existing Cloud Functions CI step
- No new CI jobs needed

---

## 7. Files Changed

| File | Action |
|------|--------|
| `functions/src/scheduled/auto-close-issues.ts` | **Create** — daily auto-close |
| `functions/src/scheduled/reset-presence.ts` | **Create** — daily presence reset |
| `functions/src/scheduled/create-deep-clean.ts` | **Create** — monthly deep clean trigger |
| `functions/src/callables/claim-room.ts` | **Create** — room self-assign |
| `functions/src/callables/complete-room.ts` | **Create** — room completion |
| `functions/src/index.ts` | **Modify** — export new functions |
| `lib/src/providers/member_provider.dart` | **Create** — members stream + presence toggle |
| `lib/src/providers/deep_clean_provider.dart` | **Create** — deep clean stream + actions |
| `lib/src/providers/issue_provider.dart` | **Modify** — autoCloseAt in resolve |
| `lib/src/features/home/home_screen.dart` | **Modify** — wire presence + who's around |
| `lib/src/features/deep_clean/deep_clean_screen.dart` | **Modify** — wire deep clean data |
| `lib/src/features/issues/issue_detail_screen.dart` | **Modify** — closed status support |
| `firestore.rules` | **Modify** — autoCloseAt in resolve path |
| `functions/src/__tests__/` | **Create** — backend unit tests |
| `test/providers/member_provider_test.dart` | **Create** — client unit tests |
| `test/providers/deep_clean_provider_test.dart` | **Create** — client unit tests |

---

## Out of Scope (Future Sprints)

| Feature | Reason | When |
|---------|--------|------|
| Volunteer window + auto-assign for deep clean | Adds scheduling + random assignment complexity | Sprint 5+ |
| Deep clean settings UI in Settings screen | `deepCleanDay` config, manage rooms list | Sprint 5+ |
| Activity feed wiring (home screen) | Needs event log collection | Sprint 5+ |
