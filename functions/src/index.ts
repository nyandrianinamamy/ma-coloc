import { initializeApp } from "firebase-admin/app";

initializeApp();

export { createHouse } from "./callables/create-house";
export { joinHouse } from "./callables/join-house";
export { leaveHouse } from "./callables/leave-house";
export { removeMember } from "./callables/remove-member";
export { autoCloseIssues } from "./scheduled/auto-close-issues";
export { resetPresence } from "./scheduled/reset-presence";
export { createDeepClean } from "./scheduled/create-deep-clean";
