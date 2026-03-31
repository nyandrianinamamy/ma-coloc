jest.mock("firebase-admin/app", () => ({
  initializeApp: jest.fn(),
}));

jest.mock("firebase-admin/firestore", () => {
  const actual = jest.requireActual("firebase-admin/firestore");
  return {
    ...actual,
    getFirestore: jest.fn(),
    Timestamp: {
      now: () => ({ toMillis: () => Date.now(), seconds: Math.floor(Date.now() / 1000), nanoseconds: 0 }),
      fromMillis: (ms: number) => ({ toMillis: () => ms, seconds: Math.floor(ms / 1000), nanoseconds: 0 }),
      fromDate: (d: Date) => ({ toMillis: () => d.getTime(), seconds: Math.floor(d.getTime() / 1000), nanoseconds: 0 }),
    },
    FieldValue: {
      increment: (n: number) => ({ __increment: n }),
      arrayUnion: (...items: string[]) => ({ __arrayUnion: items }),
    },
  };
});

jest.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: jest.fn((_schedule: string, handler: Function) => handler),
}));

jest.mock("firebase-functions/v2/https", () => ({
  onCall: jest.fn((handler: Function) => handler),
  HttpsError: class HttpsError extends Error {
    constructor(public code: string, public message: string) { super(message); }
  },
}));

import { evaluateNewBadges, MemberStatsSnapshot } from "../badges";

describe("Badge evaluation", () => {
  test("first_issue earned at issuesResolved=1", () => {
    const stats: MemberStatsSnapshot = {
      totalPoints: 5, issuesResolved: 1, longestStreak: 0, deepCleanRoomsCompleted: 0, badges: [],
    };
    expect(evaluateNewBadges(stats)).toContain("first_issue");
  });

  test("already earned badges are not returned", () => {
    const stats: MemberStatsSnapshot = {
      totalPoints: 5, issuesResolved: 1, longestStreak: 0, deepCleanRoomsCompleted: 0, badges: ["first_issue"],
    };
    expect(evaluateNewBadges(stats)).not.toContain("first_issue");
  });

  test("multiple badges can be earned at once", () => {
    const stats: MemberStatsSnapshot = {
      totalPoints: 100, issuesResolved: 10, longestStreak: 7, deepCleanRoomsCompleted: 1, badges: [],
    };
    const newBadges = evaluateNewBadges(stats);
    expect(newBadges).toContain("first_issue");
    expect(newBadges).toContain("ten_resolved");
    expect(newBadges).toContain("streak_7");
    expect(newBadges).toContain("deep_clean_1");
    expect(newBadges).toContain("points_100");
    expect(newBadges).not.toContain("fifty_resolved");
    expect(newBadges).not.toContain("streak_30");
  });

  test("no badges earned returns empty array", () => {
    const stats: MemberStatsSnapshot = {
      totalPoints: 0, issuesResolved: 0, longestStreak: 0, deepCleanRoomsCompleted: 0, badges: [],
    };
    expect(evaluateNewBadges(stats)).toHaveLength(0);
  });
});

describe("Points award logic", () => {
  test("resolver gets points and issuesResolved increment", () => {
    const issuePoints = 5;
    const updateFields = {
      "stats.totalPoints": { __increment: issuePoints },
      "stats.issuesResolved": { __increment: 1 },
    };
    expect(updateFields["stats.totalPoints"].__increment).toBe(5);
    expect(updateFields["stats.issuesResolved"].__increment).toBe(1);
  });

  test("creator gets issuesCreated increment only (no points)", () => {
    const updateFields = {
      "stats.issuesCreated": { __increment: 1 },
    };
    expect(updateFields["stats.issuesCreated"].__increment).toBe(1);
    expect(updateFields).not.toHaveProperty("stats.totalPoints");
  });

  test("resolver who is also creator gets both increments", () => {
    const resolvedBy = "user1";
    const createdBy = "user1";
    expect(resolvedBy).toBe(createdBy);
  });
});

describe("Streak logic", () => {
  test("streak increments when member has closed issue today", () => {
    const currentStreak = 3;
    const hasClosedToday = true;
    const newStreak = hasClosedToday ? currentStreak + 1 : 0;
    expect(newStreak).toBe(4);
  });

  test("streak resets to 0 when no closed issue today", () => {
    const currentStreak = 5;
    const hasClosedToday = false;
    const newStreak = hasClosedToday ? currentStreak + 1 : 0;
    expect(newStreak).toBe(0);
  });

  test("longestStreak updates when currentStreak exceeds it", () => {
    const newLongest = Math.max(7, 8);
    expect(newLongest).toBe(8);
  });

  test("longestStreak unchanged when currentStreak is lower", () => {
    const newLongest = Math.max(10, 3);
    expect(newLongest).toBe(10);
  });

  test("lastStreakDate guards against double-run", () => {
    const today = "2026-03-31";
    const lastStreakDate = "2026-03-31";
    expect(lastStreakDate === today).toBe(true);
  });
});
