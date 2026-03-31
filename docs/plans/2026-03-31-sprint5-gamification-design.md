# Sprint 5: Gamification — Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add points engine, daily streaks, predefined badges, and a live leaderboard — wiring the existing mock UI screens to real Firestore data.

**Architecture:** Piggyback gamification logic on existing scheduled Cloud Functions (`autoCloseIssues`, `completeRoom`) plus one new scheduled function (`updateStreaks`). Client-side leaderboard computed from existing member/issue streams. No Firestore triggers.

**Tech Stack:** Flutter + Riverpod + Firestore + Cloud Functions v2 (onSchedule, onCall) + Jest

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Points timing | On issue close | Safest — dispute window has expired, no rollback needed |
| Streaks | Daily activity | Matches UI ("X day streak"), intuitive, checked by scheduled function |
| Badges | Server-evaluated, predefined list | Simple, predictable, extensible later |
| Leaderboard periods | Calendar-based (ISO week / month) | Simpler queries, aligns with deep clean monthly cycle |
| Architecture | Piggyback on scheduled functions | Fewer functions, atomic batch writes, household scale doesn't need event-driven |

---

## 1. Points & Stats Engine

**Trigger:** `autoCloseIssues` (daily 2am) — when it batch-updates issues to `closed`, it also:

1. For each closed issue, increments the resolver's `MemberStats`:
   - `totalPoints += issue.points`
   - `issuesResolved += 1`
2. For each closed issue, increments the creator's `MemberStats`:
   - `issuesCreated += 1` (creator gets no points, just a stat counter)
3. All stat updates use `FieldValue.increment()` in the same batch as the issue close — atomic, no partial state.

**Deep clean bonus:** When `completeRoom` callable detects all rooms done, award bonus points to each participant. Flat bonus: 5 points per room completed. Added to the existing `completeRoom` transaction.

**No new Cloud Functions needed** for points — just extending `autoCloseIssues` and `completeRoom`.

---

## 2. Streaks

**New scheduled function:** `updateStreaks` — `onSchedule("every day 03:00")`

Runs after `autoCloseIssues` (2am) to ensure closed issues are available.

**Logic:**
1. For each house, query all members
2. For each member, check if they have at least one issue closed today (where `closedAt` falls within today in the house's timezone, and `resolvedBy == member.uid`)
3. If yes: `currentStreak += 1`, `longestStreak = max(longestStreak, currentStreak)`, `lastStreakDate = today`
4. If no: `currentStreak = 0`

**Edge case:** Uses `lastStreakDate` (new field) to avoid double-counting if the function runs twice. If `lastStreakDate == today`, skip.

**Timezone:** Uses house's configured timezone (same Luxon pattern as `createDeepClean`).

---

## 3. Badges

**Predefined badge catalog** — hardcoded in `functions/src/badges.ts`, mirrored as a Dart constant map for client UI.

| Badge ID | Name | Icon | Condition |
|----------|------|------|-----------|
| `first_issue` | First Issue | star | `issuesResolved >= 1` |
| `ten_resolved` | Problem Solver | wrench | `issuesResolved >= 10` |
| `fifty_resolved` | Veteran | shield | `issuesResolved >= 50` |
| `streak_7` | On Fire | fire | `longestStreak >= 7` |
| `streak_30` | Unstoppable | rocket | `longestStreak >= 30` |
| `deep_clean_1` | Clean Freak | sparkles | completed >= 1 deep clean room |
| `deep_clean_10` | Cleaning Machine | broom | completed >= 10 deep clean rooms |
| `points_100` | Century | trophy | `totalPoints >= 100` |

**Evaluation:** Checked in `autoCloseIssues` (after points update), `updateStreaks` (after streak update), and `completeRoom` (after deep clean). Each calls a shared `evaluateBadges(memberStats)` helper that returns newly earned badge IDs. New badges appended via `FieldValue.arrayUnion()`.

**Client side:** Badge catalog is a `Map<String, BadgeDefinition>` constant with `name`, `icon`, `description`, `isUnlocked(stats)`. Profile and leaderboard read `member.stats.badges` and look up display info from the catalog.

---

## 4. Leaderboard

**No server-side leaderboard collection.** Computed client-side from existing providers.

**Client logic (new `leaderboardProvider`):**
1. Reads `membersStreamProvider` — all members with `MemberStats`
2. Reads `issuesStreamProvider` — filters by `closedAt` within selected period
3. Computes `periodPoints` per member: sum `issue.points` where `resolvedBy == uid` and `closedAt` within period
4. Sorts by `periodPoints` descending
5. "All Time" implicit: sort by `totalPoints` from `MemberStats`

**Tabs:** Weekly | Monthly (already in UI). Both calendar-based: ISO week (Mon-Sun) / calendar month.

**Why client-side:** Max ~10 members/house. Two queries already cached by Riverpod.

---

## 5. Model Updates

### MemberStats (MODIFY)

New fields:
- `deepCleanRoomsCompleted: int` (default 0) — incremented in `completeRoom`
- `lastStreakDate: String?` (nullable) — YYYY-MM-DD, guards against double-counting

### No new models

Badge catalog is a constant map, not a Firestore document.

---

## 6. Screen Wiring

### leaderboard_screen.dart (MODIFY)

- Replace `MockData.users` with `leaderboardProvider`
- Weekly/Monthly toggle filters issues by `closedAt` within calendar period
- Streak badge reads real `currentStreak`
- Podium + rankings from computed sorted list

### profile_screen.dart (MODIFY)

- Replace hardcoded "42" / "12" with `member.stats.issuesResolved` / `member.stats.issuesCreated`
- Replace hardcoded badge list with `member.stats.badges` looked up against badge catalog constant
- Locked badges = catalog entries not in `member.stats.badges`

### No changes to: home_screen, settings_screen, deep_clean_screen, issue screens

---

## 7. Firestore Rules Updates

- No rule changes needed. `MemberStats` is already not client-writable (only Cloud Functions update it).

---

## 8. Testing Strategy

### Backend (Jest)

- Points award: close issue in `autoCloseIssues` → verify `totalPoints` and `issuesResolved` incremented
- Creator stat: close issue → verify creator's `issuesCreated` incremented
- Streak increment: member has issue closed today → `currentStreak` increments
- Streak reset: member has no issue closed today → `currentStreak` = 0
- Streak double-run guard: `lastStreakDate == today` → skip
- Badge evaluation: test each threshold (first_issue, ten_resolved, streak_7, etc.)
- Deep clean bonus: `completeRoom` all-done → verify points + `deepCleanRoomsCompleted`

### Client (Dart)

- `leaderboardProvider`: sorting, period filtering (weekly/monthly)
- Badge catalog: `isUnlocked(stats)` for each badge definition
- `MemberStats` serialization with new fields (`deepCleanRoomsCompleted`, `lastStreakDate`)
- Existing 43 Flutter + 9 Jest tests must not regress

---

## 9. Files Changed

| File | Action |
|------|--------|
| `functions/src/scheduled/auto-close-issues.ts` | **Modify** — award points + stats + badges on close |
| `functions/src/scheduled/update-streaks.ts` | **Create** — daily streak calculation |
| `functions/src/badges.ts` | **Create** — badge catalog + evaluateBadges helper |
| `functions/src/callables/complete-room.ts` | **Modify** — deep clean bonus points + badge check |
| `functions/src/index.ts` | **Modify** — export updateStreaks |
| `lib/src/models/member.dart` | **Modify** — add deepCleanRoomsCompleted, lastStreakDate to MemberStats |
| `lib/src/models/badge.dart` | **Create** — BadgeDefinition class + badge catalog constant |
| `lib/src/providers/leaderboard_provider.dart` | **Create** — computed leaderboard from members + issues streams |
| `lib/src/features/leaderboard/leaderboard_screen.dart` | **Modify** — wire to leaderboardProvider |
| `lib/src/features/profile/profile_screen.dart` | **Modify** — wire to real member stats + badges |
| `functions/src/__tests__/gamification.test.ts` | **Create** — backend unit tests |
| `test/providers/leaderboard_provider_test.dart` | **Create** — client unit tests |
| `test/models/badge_test.dart` | **Create** — badge catalog tests |

---

## Out of Scope (Future Sprints)

| Feature | Reason | When |
|---------|--------|------|
| Configurable badges per house | Adds admin UI + Firestore subcollection | Sprint 6+ |
| Points multipliers / bonus events | Unnecessary complexity for MVP | Sprint 6+ |
| Activity feed ("X earned badge Y") | Needs event log collection | Sprint 6 |
| Notifications for new badges | Needs push notification infra | Sprint 6 |
| Leaderboard history / past periods | Nice-to-have, not core | Sprint 6+ |
