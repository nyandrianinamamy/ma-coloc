# Demo Data Flow for TestFlight Review

## Goal

Add an "Explore with demo data" option on the Welcome screen so Apple TestFlight reviewers (and curious users) can experience the full app without creating a real account or household.

## Architecture

### Approach: Anonymous Auth + Server-Side Seeding

- **Anonymous Firebase Auth** for a real session with no credentials required
- **Single `seedDemoHouse` Cloud Function** creates house, members, issues, deep clean, and activity events in one batched write
- **`cleanupDemoHouse` Cloud Function** tears down all demo data and deletes the anonymous account
- Demo houses flagged with `isDemo: true` on the house doc

## Client-Side Flow

### Entry Point — Welcome Screen

A "Explore with demo data" text button below existing Google/Email sign-in options.

Tap sequence:
1. Show loading indicator
2. `FirebaseAuth.instance.signInAnonymously()`
3. Call `seedDemoHouse` callable — returns `{ houseId }`
4. `currentHouseIdProvider` picks up the house
5. Router redirects to `/home`

### Demo State Detection

The reviewer's `Member` doc has `isDemo: true`. Used to:
- Show an "Exit demo" button in the Profile screen
- Optionally display a subtle "Demo mode" indicator

### Exit Demo — Profile Screen

1. Call `cleanupDemoHouse` Cloud Function
2. Delete anonymous auth account
3. Sign out, redirect to `/welcome`

## Cloud Functions

### `seedDemoHouse` (callable)

**Validation:**
- Caller must be authenticated (anonymous OK)
- If caller already has a house, return existing `houseId`

**Batch write creates:**

```
/houses/{demoHouseId}
  name: "Appart Rue Exemple"
  members: [callerUid, "demo-alex", "demo-sam", "demo-jordan"]
  rooms: ["Kitchen", "Living Room", "Bathroom", "Hallway", "Bedroom"]
  inviteCode: "DEMO01"
  isDemo: true
  settings: default HouseSettings

  /members/callerUid      → admin, "You", some starter stats
  /members/demo-alex      → 145 pts, streak 7, 3 badges
  /members/demo-sam       → 98 pts, streak 3, 1 badge
  /members/demo-jordan    → 67 pts, streak 0, 0 badges

  /issues/ (7 issues)
    - "Dirty dishes in the sink"     → chore, open
    - "Buy oat milk"                 → grocery, open
    - "Broken bathroom handle"       → repair, in_progress, assigned to demo-alex
    - "Vacuum the living room"       → chore, resolved by demo-sam
    - "Trash bags running low"       → grocery, open
    - "Hallway light flickering"     → repair, disputed
    - "Clean fridge"                 → chore, in_progress, assigned to callerUid

  /deepCleans/{currentMonth}
    - status: volunteering
    - volunteerIntents: Kitchen → demo-alex, Bathroom → demo-sam

  /activityEvents/ (5 events)
    - demo-alex earned "streak_7" badge
    - demo-sam resolved "Vacuum the living room"
    - demo-jordan created "Hallway light flickering"
    - demo-alex streak milestone (7 days)
    - demo-sam completed deep clean room
```

**Returns:** `{ houseId: string }`

### `cleanupDemoHouse` (callable)

**Validation:**
- Caller must be in a house with `isDemo: true`

**Actions:**
1. Delete all subcollections (members, issues, deepCleans, activityEvents)
2. Delete the house doc
3. Delete the anonymous auth account via Admin SDK

## Security & Edge Cases

- **No security rule changes needed** — Admin SDK bypasses rules; anonymous user is a real auth user so existing membership-based rules apply
- **Double-tap protection** — `seedDemoHouse` returns existing house if caller already has one
- **Scheduled functions** — run on demo houses (makes it feel real)
- **Fake member UIDs** — "demo-alex" etc. don't have auth accounts; app only reads their Member docs
- **App kill + reopen** — anonymous auth persists, reviewer lands back on `/home`
- **Stale demo cleanup** — optional scheduled function to purge demo houses older than 7 days
- **No read-only restrictions** — reviewer can create/resolve issues for a convincing review
- **Demo data lives in production Firestore** — isolated by `isDemo` flag, cleaned up on exit
