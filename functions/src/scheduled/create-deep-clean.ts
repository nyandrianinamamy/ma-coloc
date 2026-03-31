import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { DateTime } from "luxon";

export const createDeepClean = onSchedule("every day 09:00", async () => {
  const db = getFirestore();
  const now = DateTime.utc();
  const currentMonth = now.toFormat("yyyy-MM");
  const todayWeekday = now.weekday; // 1=Mon, 7=Sun (ISO)

  const houses = await db.collection("houses").get();

  for (const house of houses.docs) {
    const data = house.data();
    const settings = data.settings || {};
    const deepCleanDay: number = settings.deepCleanDay || 1;
    const lastDeepCleanMonth: string | null = data.lastDeepCleanMonth || null;

    // Only create if today matches deepCleanDay AND we haven't created for this month
    if (todayWeekday !== deepCleanDay) continue;
    if (lastDeepCleanMonth === currentMonth) continue;

    const rooms: string[] = data.rooms || [];
    if (rooms.length === 0) continue;

    // Build empty assignments map: { roomName: { uid: null, completed: false } }
    const assignments: Record<string, object> = {};
    for (const room of rooms) {
      assignments[room] = {
        uid: null,
        fromVolunteer: false,
        completed: false,
      };
    }

    // Build empty volunteerIntents map
    const volunteerIntents: Record<string, never[]> = {};
    for (const room of rooms) {
      volunteerIntents[room] = [];
    }

    const cleanRef = db
      .collection(`houses/${house.id}/deepCleans`)
      .doc(currentMonth);

    const batch = db.batch();

    batch.set(cleanRef, {
      month: currentMonth,
      status: "in_progress",
      volunteerDeadline: Timestamp.fromDate(
        now.plus({ hours: settings.volunteerWindowHours || 48 }).toJSDate()
      ),
      createdAt: Timestamp.now(),
      volunteerIntents,
      assignments,
    });

    // Update house to track last deep clean month
    batch.update(house.ref, {
      lastDeepCleanMonth: currentMonth,
    });

    await batch.commit();
  }
});
