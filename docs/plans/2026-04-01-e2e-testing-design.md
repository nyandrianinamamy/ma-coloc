# E2E Testing with Firebase Emulators — Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Full-stack E2E test suite covering all MaColoc features, running against Firebase emulators on Chrome (headless), gated in CI via GitHub Actions.

**Architecture:** Flutter integration tests connect to local Firebase emulators (Auth, Firestore, Functions). Callable functions run through the emulator for realistic testing. Scheduled function side-effects are seeded directly in Firestore. `demo-macoloc` project prefix eliminates need for real credentials.

**Tech Stack:** Flutter integration_test + Firebase Emulators + GitHub Actions + Chrome headless

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Goal | Full feature E2E + CI gate | Catch full-stack breakages before merge |
| Functions interaction | Hybrid | Callables through emulator (realistic); scheduled side-effects seeded (already Jest-tested) |
| CI | GitHub Actions | Already on GitHub, free tier sufficient |
| Platform | Chrome (web) headless | Fastest/cheapest CI target, business logic identical across platforms |
| Firebase project | `demo-macoloc` | No real credentials needed — emulators accept any `demo-*` project |
| Test structure | 6 flow-based files + 1 shared helper | One file per user journey |

---

## 1. Architecture & Emulator Wiring

### Entry Point

Dedicated `integration_test/e2e_helpers.dart` with:

- `initFirebaseForTest()` — `Firebase.initializeApp()` with web options for `demo-macoloc`, connects all services to emulators
- `clearFirestore()` — HTTP DELETE to `http://localhost:8080/emulator/v1/projects/demo-macoloc/databases/(default)/documents`
- `createTestUser(email, password)` — `FirebaseAuth.instance.createUserWithEmailAndPassword()`
- `signInTestUser(email, password)` — sign-in helper
- `pumpApp(tester, {overrides})` — creates `ProviderScope` + `MaColocApp`, pumps and settles

### Firebase Options for Tests

Web `FirebaseOptions` using `demo-macoloc` project — no real API keys needed for emulator-only usage.

### Test Runner Command

```bash
# Local
firebase emulators:exec --project demo-macoloc \
  "flutter test integration_test/ -d chrome --headless"

# CI (same command, run by GitHub Actions)
```

`emulators:exec` starts emulators, runs the command, tears down automatically.

### Emulator Ports (from existing firebase.json)

| Service | Port |
|---------|------|
| Auth | 9099 |
| Firestore | 8080 |
| Functions | 5001 |
| Storage | 9199 |
| UI | 4000 |

---

## 2. Test Structure & User Flows

### File Organization

```
integration_test/
  e2e_helpers.dart          # Shared setup
  auth_flow_test.dart       # Sign-up, sign-out, redirect guards
  onboarding_flow_test.dart # Create house, join house with invite code
  issue_lifecycle_test.dart # Create issue, view, resolve, points
  deep_clean_flow_test.dart # Claim room, complete, badges, activity
  settings_flow_test.dart   # Admin: edit name, roles, remove, leave
  home_feed_test.dart       # Activity feed, momentum card, volunteer nudge
```

### Flow Coverage

| Flow | Key Assertions | Callables Exercised |
|------|---------------|---------------------|
| Auth | Sign-up works, sign-out redirects to `/sign-in`, unauthenticated access blocked | — |
| Onboarding | Create house -> house doc exists, invite code generated. Second user joins -> member doc | `createHouse`, `joinHouse` |
| Issue lifecycle | Create issue via UI -> Firestore doc. Resolve -> status changes, points awarded | — (direct Firestore) |
| Deep clean | Seed deep clean cycle. Claim -> `claimRoom`. Complete -> `completeRoom`. Activity doc written | `claimRoom`, `completeRoom` |
| Settings | Edit house name -> `updateHouse`. Promote -> `updateMemberRole`. Remove -> `removeMember`. Leave -> `leaveHouse` | all 4 |
| Home feed | Seed activity + issues. Feed renders items. Momentum text thresholds. Volunteer nudge | — (reads seeded data) |

### Scheduled Function Side-Effects (Seeded)

Instead of triggering `autoCloseIssues`, `updateStreaks`, `createDeepClean`, `resetPresence`:
- Seed `activity` subcollection docs directly (badge_earned, streak_milestone, deep_clean_done)
- Seed deep clean cycle docs for volunteer nudge / claim tests
- These functions already have 33 Jest tests covering their logic

---

## 3. CI Pipeline

### GitHub Actions Workflow: `.github/workflows/e2e.yml`

**Triggers:** Push to `master`, PRs targeting `master`

**Steps:**
1. Checkout repo
2. Setup Node 20 + `npm ci` in `functions/`
3. Build functions (`npm run build`)
4. Setup Java 17 (Firebase emulator dependency)
5. Setup Flutter (stable)
6. Install Firebase CLI (`npm install -g firebase-tools`)
7. Run: `firebase emulators:exec --project demo-macoloc "flutter test integration_test/ -d chrome --headless"`

**Key properties:**
- No Firebase credentials/secrets needed (`demo-*` project)
- Single `emulators:exec` manages lifecycle
- Timeout: 15 min
- Estimated runtime: ~4-5 min

---

## 4. App Modifications

### `firebase_options.dart` (MODIFY)

- Add `web` case to `currentPlatform` (return `web` in default branch instead of throwing)
- Add `static const FirebaseOptions web` with `demo-macoloc` project values

### `integration_test/issue_flow_test.dart` (DELETE)

Replace placeholder test with real E2E files.

### No changes to: `main.dart`, any screen, any provider, any Cloud Function

---

## 5. Files Changed

| File | Action |
|------|--------|
| `integration_test/e2e_helpers.dart` | **Create** — shared E2E setup, Firebase init, cleanup, user helpers |
| `integration_test/auth_flow_test.dart` | **Create** — auth E2E tests |
| `integration_test/onboarding_flow_test.dart` | **Create** — onboarding E2E tests |
| `integration_test/issue_lifecycle_test.dart` | **Create** — issue flow E2E tests |
| `integration_test/deep_clean_flow_test.dart` | **Create** — deep clean E2E tests |
| `integration_test/settings_flow_test.dart` | **Create** — settings E2E tests |
| `integration_test/home_feed_test.dart` | **Create** — home feed E2E tests |
| `integration_test/issue_flow_test.dart` | **Delete** — placeholder test |
| `lib/firebase_options.dart` | **Modify** — add web platform support |
| `.github/workflows/e2e.yml` | **Create** — CI workflow |
| `pubspec.yaml` | **Modify** — add `http` package (for emulator reset endpoint) |

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| iOS/Android E2E | Chrome covers business logic; platform-specific bugs caught in manual QA |
| Scheduled function E2E triggers | Already Jest-tested; seeding side-effects is simpler |
| FCM notification E2E | FCM not available in web; token management tested via unit tests |
| Visual regression testing | Out of scope for functional E2E |
| Emulator JAR caching in CI | Marginal benefit for solo project |
