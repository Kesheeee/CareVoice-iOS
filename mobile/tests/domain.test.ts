import { test } from "node:test";
import assert from "node:assert/strict";
import {
  emptyData,
  needsFollowUp,
  needsSafetyRouting,
  answeredCount,
  reportText,
  onboardingDestination,
  relatedRecords,
} from "../src/domain.ts";
import { validateData } from "../src/platform/storage.ts";
import { translator } from "../src/i18n.ts";

test("Simplified Chinese survives backups and localises report labels without rewriting notes", () => {
  const data = emptyData();
  data.language = "zh-Hans";
  data.records = [{ id: "language-record", date: "2026-10-18T02:00:00Z", text: "繁體筆記", category: "observation", location: "學校", durationMinutes: null, context: "", helped: "" }];
  assert.equal(validateData(JSON.parse(JSON.stringify(data))).language, "zh-Hans");
  assert.equal(translator("zh-Hans")("Language", "語言"), "语言");
  const report = reportText(data, [], false);
  assert.ok(report.includes("观察记录"));
  assert.ok(report.includes("繁體筆記"));
  assert.ok(report.includes("學校"));
});

test("Only the just-noticing stage enters the automatic questionnaire", () => {
  assert.equal(onboardingDestination("noticed"), "questionnaireIntro");
  for (const stage of [
    "professionalFollowUp",
    "awaitingAssessment",
    "assessed",
    "diagnosed",
    "registered",
  ] as const)
    assert.equal(onboardingDestination(stage), "home");
});
test("Related records use explicit category and past date, without inferred relationships", () => {
  const r = {
    id: "now",
    date: "2026-10-15",
    text: "Now",
    category: "progress" as const,
    location: "",
    durationMinutes: null,
    context: "",
    helped: "",
  };
  const past = { ...r, id: "past", date: "2026-10-14" };
  assert.deepEqual(
    relatedRecords(
      [
        r,
        past,
        { ...past, id: "future", date: "2026-10-16" },
        { ...past, id: "other", category: "play" },
      ],
      r,
    ),
    [past],
  );
});
test("Optional regression/report fields round-trip alongside older version-one data", () => {
  const d = emptyData();
  d.regressionWhen = { 29: "Last month" };
  assert.deepEqual(
    validateData(JSON.parse(JSON.stringify(d))).regressionWhen,
    d.regressionWhen,
  );
  assert.throws(() => validateData({ ...d, regressionWhen: { 29: 123 } }));
  assert.throws(() =>
    validateData({ ...d, regressionWhen: { 1: "Invalid question" } }),
  );
});
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
  for (const id of [29, 30, 131])
    for (const a of ["yes", "unsure"] as const) {
      const d = emptyData();
      d.answers[id] = a;
      assert.equal(needsFollowUp(d.answers), true);
      assert.equal(d.profile, null);
    }
  assert.equal(needsFollowUp({ 29: "no", 30: "skipped" }), false);
});
test("Skipped answers do not count as answered", () =>
  assert.equal(answeredCount({ 1: "yes", 101: "never", 102: "skipped", 103: "unsure" }), 2));
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

test("Safety routing responds to Yes and Not sure, never treats Skip as No", () => {
  for (const id of [132, 133]) {
    for (const a of ["yes", "unsure"] as const) assert.equal(needsSafetyRouting({ [id]: a }), true);
    for (const a of ["no", "skipped"] as const) assert.equal(needsSafetyRouting({ [id]: a }), false);
  }
});
test("Revised and legacy answers persist independently, including play choices", () => {
  const d = emptyData(); d.answers = {1:"often",29:"yes",101:"never",129:"varied",131:"unsure",132:"skipped",133:"no"};
  d.regressionWhen = {29:"Previously",131:"Yesterday"};
  assert.deepEqual(validateData(JSON.parse(JSON.stringify(d))),d);
  assert.equal(answeredCount(d.answers),4);
  assert.throws(() => validateData({...d, answers:{134:"yes"}}));
});
