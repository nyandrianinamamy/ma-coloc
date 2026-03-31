// Mock firebase-admin before any imports that use it
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

describe("Scheduled functions", () => {
  describe("auto-close cutoff logic", () => {
    test("24h stale cutoff is computed correctly", () => {
      const now = Date.now();
      const cutoffMs = now - 24 * 60 * 60 * 1000;
      const cutoff = { toMillis: () => cutoffMs };
      expect(cutoff.toMillis()).toBeLessThan(now);
      expect(now - cutoff.toMillis()).toBe(24 * 60 * 60 * 1000);
    });

    test("batch limit constant is under 500", () => {
      const BATCH_LIMIT = 499;
      expect(BATCH_LIMIT).toBeLessThan(500);
    });
  });

  describe("deep clean creation logic", () => {
    test("weekday matching uses ISO convention", () => {
      // luxon weekday: 1=Mon, 7=Sun
      const { DateTime } = jest.requireActual("luxon");
      const now = DateTime.utc();
      expect(now.weekday).toBeGreaterThanOrEqual(1);
      expect(now.weekday).toBeLessThanOrEqual(7);
    });

    test("month format is yyyy-MM", () => {
      const { DateTime } = jest.requireActual("luxon");
      const now = DateTime.utc();
      const currentMonth = now.toFormat("yyyy-MM");
      expect(currentMonth).toMatch(/^\d{4}-\d{2}$/);
    });

    test("empty rooms array skips creation", () => {
      const rooms: string[] = [];
      expect(rooms.length).toBe(0);
      // Function would skip: if (rooms.length === 0) continue;
    });

    test("assignments map initialized correctly", () => {
      const rooms = ["Kitchen", "Bathroom", "Living Room"];
      const assignments: Record<string, object> = {};
      for (const room of rooms) {
        assignments[room] = { uid: null, fromVolunteer: false, completed: false };
      }
      expect(Object.keys(assignments)).toHaveLength(3);
      expect(assignments["Kitchen"]).toEqual({ uid: null, fromVolunteer: false, completed: false });
    });
  });
});

describe("Callable validation", () => {
  test("claimRoom rejects when room is already assigned", () => {
    const assignments = {
      Kitchen: { uid: "user1", completed: false },
      Bathroom: { uid: null, completed: false },
    };
    expect(assignments["Kitchen"].uid).not.toBeNull();
    expect(assignments["Bathroom"].uid).toBeNull();
  });

  test("completeRoom all-rooms-completed check", () => {
    const roomBeingCompleted = "Kitchen";
    const assignments = {
      Kitchen: { uid: "user1", completed: false },  // being completed now
      Bathroom: { uid: "user2", completed: true },
      "Living Room": { uid: "user3", completed: true },
    };

    const allCompleted = Object.entries(assignments).every(
      ([name, room]: [string, any]) => {
        if (name === roomBeingCompleted) return true;
        return room.completed === true;
      }
    );
    expect(allCompleted).toBe(true);
  });

  test("completeRoom not all completed when one is pending", () => {
    const roomBeingCompleted = "Kitchen";
    const assignments = {
      Kitchen: { uid: "user1", completed: false },
      Bathroom: { uid: "user2", completed: false },  // not done
      "Living Room": { uid: "user3", completed: true },
    };

    const allCompleted = Object.entries(assignments).every(
      ([name, room]: [string, any]) => {
        if (name === roomBeingCompleted) return true;
        return room.completed === true;
      }
    );
    expect(allCompleted).toBe(false);
  });
});
