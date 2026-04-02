# Data Clearing Feature — Design Document

**Date:** 2026-04-02
**Branch:** `feature/data-clearing`

## Overview

Add comprehensive data clearing capabilities to MaColoc: account deletion, house data reset, archived issue purging, and local cache clearing. All destructive operations go through Cloud Functions (admin SDK) except local cache clearing which is client-side.

## Architecture: Hybrid (Client + Cloud Functions)

- **Cloud Functions** handle all Firestore, Storage, and Auth deletions (reliable, atomic, proper permissions)
- **Client-side** handles local cache clearing only

## UI: Data & Privacy Screen

New screen at `/data-privacy`, accessible from Settings. **Admin-only** — non-admins do not see the entry point.

### Sections

**1. Account Management**
- "Delete My Account" button
- Confirmation dialog requiring user to type "DELETE" to confirm
- Anonymizes user references, removes member doc, deletes Firebase Auth account, signs out

**2. House Data**
- "Reset All Data" (nuclear) — clears issues, activity, leaderboard, deep cleans, resets all member stats
- Individual clear buttons:
  - "Clear Issues" — deletes all issues + associated Storage photos
  - "Clear Activity Log" — deletes activity subcollection
  - "Reset Leaderboard" — deletes leaderboard subcollection
  - "Reset Member Stats" — zeroes all members' stats fields
- Each action requires typed confirmation (e.g., type "RESET")

**3. Archived Issues**
- "Purge Archived Issues" — manual trigger only (no auto-purge)
- Optional age filter: all / older than 30 / 60 / 90 days
- Deletes matching issues + their Storage photos

**4. Local**
- "Clear App Cache" — clears image cache + Firestore persistence cache
- No confirmation dialog needed (non-destructive, recoverable)

## Cloud Functions

### `deleteAccount` (callable)

1. Verify caller is authenticated
2. If caller is the only admin and other members exist → reject with error: "Transfer admin role before deleting"
3. If caller is the last member → trigger existing recursive house delete
4. Otherwise:
   - Query all issues in the house; batch-update fields where UID matches caller:
     - `createdBy` → `"deleted_user"`
     - `assignedTo` → `null`
     - `resolvedBy` → `"deleted_user"`
     - `disputedBy` → `"deleted_user"`
     - `disputeAgainst` → `"deleted_user"`
   - Update activity events: set `uid` → `"deleted_user"`, `displayName` → `"Deleted User"`
   - Remove UID from `house.members[]` array
   - Delete `houses/{houseId}/members/{uid}` doc
   - Delete Firebase Auth account via admin SDK (`admin.auth().deleteUser(uid)`)

### `resetHouseData` (callable, admin-only)

Accepts `scope` parameter: `"all"` | `"issues"` | `"activity"` | `"leaderboard"` | `"stats"`

- **`"all"`**: Deletes subcollections (issues, activity, leaderboard, deepCleans), deletes Storage at `houses/{houseId}/issues/` and `houses/{houseId}/resolutions/`, resets every member's `stats` to zeroes
- **`"issues"`**: Deletes issues subcollection + Storage photos
- **`"activity"`**: Deletes activity subcollection
- **`"leaderboard"`**: Deletes leaderboard subcollection
- **`"stats"`**: Resets all member stats fields to zero (totalPoints, issuesCreated, issuesResolved, currentStreak, longestStreak, badges, deepCleanRoomsCompleted → defaults)

All scopes verify admin role server-side.

### `purgeArchivedIssues` (callable, admin-only)

Accepts optional `olderThanDays` parameter (null = all archived).

1. Query issues where `archived == true` (and optionally `createdAt` older than threshold)
2. For each matching issue, delete Storage photos at `houses/{houseId}/issues/{issueId}/` and `houses/{houseId}/resolutions/{issueId}/`
3. Batch delete the issue documents (500 per batch)

## Client-Side: Local Cache Clearing

```dart
// Clear image cache
PaintingBinding.instance.imageCache.clear();
PaintingBinding.instance.imageCache.clearLiveImages();

// Clear Firestore persistence
await FirebaseFirestore.instance.clearPersistence();
```

## Data Flow

1. User taps action → confirmation dialog (typed confirmation for destructive actions)
2. On confirm → loading overlay, call Cloud Function
3. On success → success snackbar, navigate back (or sign out for account deletion)
4. On error → dismiss loading, error snackbar with message

## Error Handling

- Batch operations use 500-doc batches to respect Firestore limits
- Functions are idempotent — safe to retry on partial failure
- Storage cleanup uses prefix-based bulk delete
- `deleteAccount` checks admin/last-member edge cases before any mutations

## Edge Cases

- **Last admin deleting account**: Blocked — must transfer admin role first
- **Last member deleting account**: Triggers full recursive house delete (existing behavior)
- **Concurrent resets**: Idempotent — second call is a no-op on already-deleted data
- **Storage orphans**: `resetHouseData("all")` and `purgeArchivedIssues` both clean up associated Storage files

## Flutter Provider

New `dataManagementProvider` (StateNotifier) wrapping Cloud Function calls:
- `deleteAccount()`
- `resetHouseData(scope)`
- `purgeArchivedIssues({olderThanDays})`
- `clearLocalCache()`
