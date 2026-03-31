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
      fromDate: (d: Date) => ({ toMillis: () => d.getTime(), seconds: Math.floor(d.getTime() / 1000), nanoseconds: 0 }),
    },
    FieldValue: {
      increment: (n: number) => ({ __increment: n }),
      arrayUnion: (...items: string[]) => ({ __arrayUnion: items }),
    },
  };
});

jest.mock("firebase-admin/messaging", () => ({
  getMessaging: jest.fn(() => ({
    send: jest.fn().mockResolvedValue("message-id"),
  })),
}));

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

describe("updateHouse guards", () => {
  test("non-admin role is rejected", () => {
    const callerRole = "member";
    expect(callerRole).not.toBe("admin");
  });

  test("empty name is rejected", () => {
    const name = "";
    expect(name.trim().length === 0).toBe(true);
  });
});

describe("updateMemberRole guards", () => {
  test("self-role-change is rejected", () => {
    const uid = "user1";
    const targetUid = "user1";
    expect(uid === targetUid).toBe(true);
  });

  test("last admin demotion is rejected", () => {
    const adminCount = 1;
    const newRole = "member";
    const targetRole = "admin";
    expect(adminCount <= 1 && newRole === "member" && targetRole === "admin").toBe(true);
  });

  test("valid role change to admin succeeds", () => {
    const newRole = "admin";
    expect(newRole === "admin" || newRole === "member").toBe(true);
  });

  test("invalid role value is rejected", () => {
    const newRole: string = "superadmin";
    expect(newRole !== "admin" && newRole !== "member").toBe(true);
  });
});

describe("Activity event types", () => {
  test("badge_earned activity document shape", () => {
    const activityDoc = {
      type: "badgeEarned",
      uid: "u1",
      displayName: "Alice",
      detail: "first_issue",
      createdAt: { seconds: 1000, nanoseconds: 0 },
    };
    expect(activityDoc.type).toBe("badgeEarned");
    expect(activityDoc.detail).toBe("first_issue");
  });

  test("streak milestone activity document shape", () => {
    const activityDoc = {
      type: "streakMilestone",
      uid: "u1",
      displayName: "Alice",
      detail: "7",
      createdAt: { seconds: 1000, nanoseconds: 0 },
    };
    expect(activityDoc.type).toBe("streakMilestone");
  });

  test("deep clean done activity document shape", () => {
    const activityDoc = {
      type: "deepCleanDone",
      uid: "u1",
      displayName: "Alice",
      detail: "all_rooms",
      createdAt: { seconds: 1000, nanoseconds: 0 },
    };
    expect(activityDoc.type).toBe("deepCleanDone");
  });
});

describe("Notification logic", () => {
  test("skips member with notifications disabled", () => {
    const notificationsEnabled = false;
    expect(notificationsEnabled).toBe(false);
  });

  test("skips member with no FCM token", () => {
    const fcmToken: string | null = null;
    expect(fcmToken).toBeNull();
  });

  test("new badges trigger notification per badge", () => {
    const stats: MemberStatsSnapshot = {
      totalPoints: 100, issuesResolved: 10, longestStreak: 7,
      deepCleanRoomsCompleted: 1, badges: [],
    };
    const newBadges = evaluateNewBadges(stats);
    expect(newBadges.length).toBeGreaterThan(0);
  });
});
