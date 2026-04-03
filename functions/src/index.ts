import { initializeApp } from "firebase-admin/app";

initializeApp();

export { createHouse } from "./callables/create-house";
export { joinHouse } from "./callables/join-house";
export { leaveHouse } from "./callables/leave-house";
export { removeMember } from "./callables/remove-member";
export { autoCloseIssues } from "./scheduled/auto-close-issues";
export { resetPresence } from "./scheduled/reset-presence";
export { createDeepClean } from "./scheduled/create-deep-clean";
export { claimRoom } from "./callables/claim-room";
export { completeRoom } from "./callables/complete-room";
export { updateStreaks } from "./scheduled/update-streaks";
export { updateHouse } from "./callables/update-house";
export { updateMemberRole } from "./callables/update-member-role";
export { resetHouseData } from "./callables/reset-house-data";
export { deleteAccount } from "./callables/delete-account";
export { purgeArchivedIssues } from "./callables/purge-archived-issues";
export { seedDemoHouse } from "./callables/seed-demo-house";
export { cleanupDemoHouse } from "./callables/cleanup-demo-house";
