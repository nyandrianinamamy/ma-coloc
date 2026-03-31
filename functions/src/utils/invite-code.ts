import * as crypto from "crypto";

export function generateInviteCode(): string {
  return crypto.randomBytes(3).toString("hex").toUpperCase(); // 6 chars
}
