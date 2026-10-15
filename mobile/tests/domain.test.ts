import { test } from "node:test";
import assert from "node:assert/strict";
import {
  emptyData,
  needsFollowUp,
  answeredCount,
  reportText,
} from "../src/domain.ts";
import { validateData } from "../src/platform/storage.ts";
test("Backup validation preserves a valid round trip and rejects unsafe shapes", () => {
  const d = emptyData();
  assert.deepEqual(validateData(JSON.parse(JSON.stringify(d))), d);
  for (const bad of [
    { ...d, version: 2 },
    { ...d, answers: { 31: "yes" } },
    { ...d, answers: { 29: "invalid" } },
    { ...d, records: [{ id: "1", text: "test" }] },
    { ...d, profile: { nickname: "A", ageMonths: 999, stage: "noticed" } },
  ])
    assert.throws(() => validateData(bad));
});
test("Loss-of-skills guidance is independent of completion and selected stage", () => {
  for (const id of [29, 30])
    for (const a of ["yes", "unsure"] as const) {
      const d = emptyData();
      d.answers[id] = a;
      assert.equal(needsFollowUp(d.answers), true);
      assert.equal(d.profile, null);
    }
  assert.equal(needsFollowUp({ 29: "no", 30: "skipped" }), false);
});
test("Skipped answers do not count as answered", () =>
  assert.equal(answeredCount({ 1: "never", 2: "skipped", 3: "unsure" }), 2));
test("Report includes observations and guidance without inferring a stage", () => {
  const d = emptyData();
  d.answers[29] = "yes";
  d.records.push({
    id: "1",
    date: "2026-10-15T10:00:00Z",
    text: "Said hello",
    category: "progress",
    location: "Home",
    durationMinutes: 0,
    context: "Playing",
    helped: "Quiet room",
  });
  const text = reportText(d, [], true);
  assert.match(text, /Said hello/);
  assert.match(text, /Duration \(min\): 0/);
  assert.match(text, /qualified professional/);
  assert.doesNotMatch(text, /Parent-selected stage:/);
  assert.equal(d.profile, null);
});
