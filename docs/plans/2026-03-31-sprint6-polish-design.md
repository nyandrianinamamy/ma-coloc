# Sprint 6: Polish — Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire the settings screen to real data with full admin mutations, add a hybrid activity feed to the home screen, set up FCM push notifications for 2 essential triggers, and add a deep clean volunteer nudge.

**Architecture:** Extend existing Cloud Functions with activity logging and FCM sends. Two new callables for house/member management. Client-side activity feed merges issue-derived events with a lightweight activity subcollection. No new Firestore triggers.

**Tech Stack:** Flutter + Riverpod + Firestore + Cloud Functions v2 (onSchedule, onCall) + Firebase Cloud Messaging + Jest

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Scope | All four features | Settings, activity feed, notifications, volunteer flow |
| Activity feed storage | Hybrid | Issue events derived from issues collection; badge/streak events in new `activity` subcollection |
| Push notifications | FCM scoped to essentials | 2 triggers: badge earned, deep clean reminder. No Firestore triggers needed. |
| Settings mutations | Full admin | Real data, member kick + role change, house name edit |
| Volunteer flow | Minor polish | Home screen nudge for unclaimed rooms, no new claim system |
| Issue assignment notifications | Deferred | Would require Firestore trigger or extra callable — future sprint |

---

## 1. Settings Screen Wiring

**Goal:** Replace all mock data with real Firestore data and functional mutations.

### House Info
- Read house name + member count from `currentHouseProvider` / `membersStreamProvider`
- Admin sees "Edit" button → inline text field → new `updateHouse` callable
- Non-admins see read-only house name

### Invite Code
- Read from `house.inviteCode`
- Copy button → `Clipboard.setData()`
- Share button → `Share.share()` (uses `share_plus` package)

### Members List
- Real member list from `membersStreamProvider`, show role badges (ADMIN / MEMBER)
- Admin actions per member (long-press or trailing icon):
  - **Remove member** → confirmation dialog → existing `removeMember` callable
  - **Promote/demote** → new `updateMemberRole` callable

### Leave House
- Confirmation dialog with house name
- Calls existing `leaveHouse` callable
- On success → redirect to onboarding flow

### Notifications Toggle
- Stored per-member in Firestore: `notificationsEnabled: bool` (default true)
- Direct Firestore write from client (member updates own doc)
- Cloud Functions check this field before sending FCM

### New Cloud Functions

**`updateHouse`** (callable):
- Input: `{ name: string }`
- Guards: caller must be admin of the house
- Updates `houses/{houseId}` document

**`updateMemberRole`** (callable):
- Input: `{ targetUid: string, newRole: "admin" | "member" }`
- Guards: caller must be admin, can't demote self, can't demote if it would leave zero admins
- Updates `houses/{houseId}/members/{targetUid}` role field

---

## 2. Activity Feed & Momentum Card

**Goal:** Replace mock activity feed with real events, compute momentum text from actual data.

### Hybrid Storage

**Issue-derived events** (no new writes):
- Issue created → from `issue.createdAt` + `issue.createdBy`
- Issue resolved → from `issue.resolvedAt` + `issue.resolvedBy` (when status is `resolved` or `closed`)

**New `activity` subcollection** (`houses/{houseId}/activity`):
- Badge earned → written when `evaluateNewBadges` returns new badges
- Streak milestone (7, 30) → written by `updateStreaks`
- Deep clean all-done → written by `completeRoom`

**Activity document schema:**
```
{
  type: "badge_earned" | "streak_milestone" | "deep_clean_done",
  uid: string,
  displayName: string,
  detail: string,        // badge ID, streak count, etc.
  createdAt: Timestamp
}
```

### Client-Side Merge

New `activityFeedProvider`:
1. Queries recent issues (limit 20, ordered by `createdAt` desc)
2. Queries recent activity docs (limit 20, ordered by `createdAt` desc)
3. Transforms both into unified `ActivityItem` list
4. Merges + sorts by timestamp desc
5. Returns combined feed (capped at 30 items)

### Momentum Card

- Computed from closed issues this week (reuse `closedIssuesStreamProvider` with weekly filter)
- Real count replaces hardcoded "12"
- Threshold text variants:
  - 0 → "No issues resolved yet — get started!"
  - 1-4 → "Your house resolved {N} issues this week — keep it up!"
  - 5+ → "House on fire! Your house resolved {N} issues this week"

### Firestore Index
- `activity(createdAt DESC)` composite index for subcollection query

---

## 3. Push Notifications (FCM)

**Goal:** 2 essential push notification triggers via Firebase Cloud Messaging.

### Client Setup
- Add `firebase_messaging` package
- Request permission after onboarding completes (not on first launch)
- Store FCM token on member doc: `fcmToken: String?`
- Update token on app startup and on `FirebaseMessaging.instance.onTokenRefresh`
- Handle foreground messages with `FirebaseMessaging.onMessage` → show local notification or snackbar

### Notification Triggers

| Trigger | Function | Condition | Message |
|---------|----------|-----------|---------|
| Badge earned | `autoCloseIssues`, `updateStreaks`, `completeRoom` | `evaluateNewBadges` returns new badges | title: "New Badge!", body: "You earned {badgeName}" |
| Deep clean reminder | `createDeepClean` | New cycle created | title: "Deep Clean Time!", body: "New deep clean cycle — claim your rooms!" |

### Send Logic
- Shared `sendNotification(houseId, targetUid, title, body)` helper in `functions/src/notifications.ts`
- Reads member doc → checks `notificationsEnabled` → reads `fcmToken` → sends via `admin.messaging().send()`
- For deep clean reminder: iterates all members with `notificationsEnabled: true`
- Gracefully handles missing/expired tokens (catch and log, don't fail the batch)

---

## 4. Volunteer Flow (Home Screen Nudge)

**Goal:** Drive deep clean engagement from the home screen.

- When an active deep clean cycle exists with unclaimed rooms, show a banner/card on the home screen:
  - Text: "{N} rooms unclaimed — volunteer!"
  - Tap → navigates to `/clean` (deep clean screen)
- Data source: reuse `deepCleanProvider` — count rooms where `claimedBy == null`
- Only shown when `unclaimedCount > 0`
- Replaces or sits above the momentum card when active

No new Cloud Functions or Firestore changes needed.

---

## 5. Model Updates

### Member doc (MODIFY)
New fields:
- `fcmToken: String?` (nullable) — FCM device token
- `notificationsEnabled: bool` (default true) — notification preference

### New `ActivityEvent` model (CREATE)
Dart freezed class + TypeScript interface:
- `type: String` — event type enum
- `uid: String` — user who triggered the event
- `displayName: String` — display name at time of event
- `detail: String` — badge ID, streak count, etc.
- `createdAt: Timestamp`

### No changes to: House model, Issue model, Badge model

---

## 6. Screen Changes

### settings_screen.dart (MODIFY)
- Convert to `ConsumerWidget`
- Wire all sections to real providers
- Add admin action sheets (remove member, change role)
- Add inline house name editing for admins
- Wire notifications toggle to Firestore
- Wire leave house to callable + redirect

### home_screen.dart (MODIFY)
- Replace mock activity feed with `activityFeedProvider`
- Compute momentum card text from real closed issue count
- Add volunteer nudge card when unclaimed deep clean rooms exist

### No changes to: leaderboard, profile, issues, deep clean, onboarding screens

---

## 7. Firestore Rules Updates

- Allow members to update their own `notificationsEnabled` and `fcmToken` fields
- `activity` subcollection: read-only for clients (Cloud Functions write)
- No other rule changes needed

---

## 8. Testing Strategy

### Backend (Jest)
- `updateHouse`: admin guard (non-admin rejected), name update succeeds
- `updateMemberRole`: admin guard, self-demote rejected, last-admin guard, successful role change
- Activity doc writes: verify `autoCloseIssues` writes badge activity, `updateStreaks` writes streak milestone, `completeRoom` writes all-done activity
- FCM send: mock `admin.messaging().send()`, verify called with correct token/payload, verify skipped when `notificationsEnabled: false`
- Notification helper: handles missing token gracefully

### Client (Dart)
- `ActivityEvent` model serialization (fromFirestore / toJson round-trip)
- `activityFeedProvider`: merge + sort logic with mixed issue events and activity docs
- Momentum card: threshold text for 0, 1-4, 5+ resolved issues
- Settings provider: verify admin-only actions gated correctly in UI
- Existing 53 Flutter + 21 Jest tests must not regress

---

## 9. Files Changed

| File | Action |
|------|--------|
| `functions/src/callables/update-house.ts` | **Create** — admin-only house name update |
| `functions/src/callables/update-member-role.ts` | **Create** — admin-only role change with guards |
| `functions/src/notifications.ts` | **Create** — shared FCM send helper |
| `functions/src/scheduled/auto-close-issues.ts` | **Modify** — write activity docs for badges, send FCM |
| `functions/src/scheduled/update-streaks.ts` | **Modify** — write activity docs for badges/streak milestones, send FCM |
| `functions/src/callables/complete-room.ts` | **Modify** — write activity docs, send FCM |
| `functions/src/callables/create-deep-clean.ts` | **Modify** — send FCM deep clean reminder |
| `functions/src/index.ts` | **Modify** — export new callables |
| `lib/src/models/member.dart` | **Modify** — add fcmToken, notificationsEnabled to MemberStats |
| `lib/src/models/activity_event.dart` | **Create** — ActivityEvent freezed model |
| `lib/src/providers/activity_provider.dart` | **Create** — activityFeedProvider (merge issue events + activity subcollection) |
| `lib/src/providers/settings_provider.dart` | **Create** — settings actions (updateHouse, updateMemberRole, leaveHouse wrappers) |
| `lib/src/providers/notification_provider.dart` | **Create** — FCM token management + permission request |
| `lib/src/features/settings/settings_screen.dart` | **Modify** — wire to real data + mutations |
| `lib/src/features/home/home_screen.dart` | **Modify** — real activity feed, momentum card, volunteer nudge |
| `firestore.indexes.json` | **Modify** — add activity subcollection index |
| `firestore.rules` | **Modify** — activity read rules, member self-update fields |
| `functions/src/__tests__/polish.test.ts` | **Create** — backend tests for new callables + activity writes + FCM |
| `test/models/activity_event_test.dart` | **Create** — model serialization tests |
| `test/providers/activity_provider_test.dart` | **Create** — feed merge/sort tests |
| `pubspec.yaml` | **Modify** — add firebase_messaging, share_plus |

---

## Out of Scope (Future Sprints)

| Feature | Reason | When |
|---------|--------|------|
| Issue assignment notifications | Needs Firestore trigger or extra callable pattern | Sprint 7+ |
| Activity log pruning (30d cleanup) | Nice-to-have, not urgent | Sprint 7+ |
| Configurable notification preferences per type | Over-engineering for MVP | Sprint 7+ |
| Full volunteer preference system | Current claim flow sufficient | Sprint 7+ |
| In-app notification center / badge count | Can derive from activity feed later | Sprint 7+ |
