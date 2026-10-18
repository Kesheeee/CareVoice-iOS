import { test } from "node:test";
import assert from "node:assert/strict";
import { recordStreak } from "../src/streak.ts";
const now = new Date(2026, 9, 18, 14);
const rows = (...days: number[]) => days.map(day => ({date:new Date(2026,9,day,10).toISOString()}));
test("streak counts unique days and preserves yesterday's streak", () => {
 assert.equal(recordStreak([], now), 0);
 assert.equal(recordStreak(rows(18,18,17,16), now), 3);
 assert.equal(recordStreak(rows(17,16), now), 2);
 assert.equal(recordStreak(rows(16,15), now), 0);
 assert.equal(recordStreak(rows(19), now), 0);
 assert.equal(recordStreak(rows(18,16), now), 1);
});
test("streak crosses month and year boundaries", () => {
 assert.equal(recordStreak([{date:new Date(2025,11,31,10).toISOString()},{date:new Date(2026,0,1,10).toISOString()}],new Date(2026,0,1,14)),2);
});
