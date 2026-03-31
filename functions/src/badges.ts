import { FieldValue } from "firebase-admin/firestore";

export interface MemberStatsSnapshot {
  totalPoints: number;
  issuesResolved: number;
  longestStreak: number;
  deepCleanRoomsCompleted: number;
  badges: string[];
}

interface BadgeCondition {
  id: string;
  check: (stats: MemberStatsSnapshot) => boolean;
}

const BADGE_CONDITIONS: BadgeCondition[] = [
  { id: "first_issue", check: (s) => s.issuesResolved >= 1 },
  { id: "ten_resolved", check: (s) => s.issuesResolved >= 10 },
  { id: "fifty_resolved", check: (s) => s.issuesResolved >= 50 },
  { id: "streak_7", check: (s) => s.longestStreak >= 7 },
  { id: "streak_30", check: (s) => s.longestStreak >= 30 },
  { id: "deep_clean_1", check: (s) => s.deepCleanRoomsCompleted >= 1 },
  { id: "deep_clean_10", check: (s) => s.deepCleanRoomsCompleted >= 10 },
  { id: "points_100", check: (s) => s.totalPoints >= 100 },
];

export function evaluateNewBadges(stats: MemberStatsSnapshot): string[] {
  return BADGE_CONDITIONS
    .filter((b) => b.check(stats) && !stats.badges.includes(b.id))
    .map((b) => b.id);
}

export function badgeUpdateFields(stats: MemberStatsSnapshot): Record<string, any> | null {
  const newBadges = evaluateNewBadges(stats);
  if (newBadges.length === 0) return null;
  return { "stats.badges": FieldValue.arrayUnion(...newBadges) };
}
