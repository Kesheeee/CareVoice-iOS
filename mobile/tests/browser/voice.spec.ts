import { test, expect } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.addInitScript(() => {
    localStorage.setItem("carevoice.mobile.v1", JSON.stringify({
      version: 1, language: "en", profile: { nickname: "Voice test", ageMonths: 40, stage: "registered", concernNotes: "", firstConcernDate: "2026-10-01" },
      records: [], answers: {}, completedSteps: [],
    }));
    const w = window as any;
    w.voiceStarts = 0; w.voiceAborts = 0;
    class MockSpeechRecognition {
      onstart: any = null; onresult: any = null; onerror: any = null; onend: any = null;
      constructor() { w.voiceEngine = this; }
      start() { w.voiceStarts++; this.onstart?.(); }
      stop() { this.onend?.(); }
      abort() { w.voiceAborts++; }
    }
    w.SpeechRecognition = MockSpeechRecognition;
  });
  await page.goto("/");
  await page.getByRole("button", { name: "Records", exact: true }).click();
  await page.getByRole("button", { name: "Add a record", exact: true }).click();
});

test("Microphone starts only on tap, transcript is reviewed and appended without losing typed notes", async ({ page }) => {
  const dialog = page.getByRole("dialog", { name: "Quick Record" });
  const field = dialog.getByRole("textbox", { name: "What happened?", exact: true });
  await expect(dialog.getByRole("button", { name: "Save record", exact: true })).toBeDisabled();
  expect(await page.evaluate(() => (window as any).voiceStarts)).toBe(0);
  await dialog.getByRole("tab", { name: "Text record" }).click();
  await field.fill("Already typed note.");
  await dialog.getByRole("tab", { name: "Voice record" }).click();
  await dialog.getByRole("button", { name: "Start recording", exact: true }).click();
  expect(await page.evaluate(() => (window as any).voiceStarts)).toBe(1);
  await expect(field).toHaveAttribute("readonly", "");
  await expect(dialog.getByRole("button", { name: "Save record", exact: true })).toBeDisabled();
  await page.evaluate(() => (window as any).voiceEngine.onresult({ results: [{ isFinal: false, 0: { transcript: "We went" } }] }));
  await expect(field).toHaveValue("Already typed note.");
  await page.evaluate(() => (window as any).voiceEngine.onresult({ results: [{ isFinal: true, 0: { transcript: "We went to the park." } }] }));
  await expect(field).toHaveValue("Already typed note.\nWe went to the park.");
  await dialog.getByRole("button", { name: "Stop recording", exact: true }).click();
  await dialog.getByRole("button", { name: "Record more", exact: true }).click();
  await page.evaluate(() => (window as any).voiceEngine.onresult({ results: [{ isFinal: true, 0: { transcript: "It was quiet." } }] }));
  await dialog.getByRole("button", { name: "Stop recording", exact: true }).click();
  await expect(field).toHaveValue("Already typed note.\nWe went to the park.\nIt was quiet.");
  await dialog.getByRole("button", { name: "Save record", exact: true }).click();
  await expect(dialog).toHaveCount(0);
  const saved = await page.evaluate(() => JSON.parse(localStorage.getItem("carevoice.mobile.v1")!));
  expect(saved.records).toHaveLength(1);
  expect(saved.records[0].text).toBe("Already typed note.\nWe went to the park.\nIt was quiet.");
});

test("Cancel stops capture, saves nothing and permission errors allow text entry", async ({ page }) => {
  const dialog = page.getByRole("dialog", { name: "Quick Record" });
  await dialog.getByRole("button", { name: "Start recording", exact: true }).click();
  await dialog.getByRole("button", { name: "Cancel", exact: true }).click();
  expect(await page.evaluate(() => (window as any).voiceAborts)).toBeGreaterThan(0);
  expect(await page.evaluate(() => JSON.parse(localStorage.getItem("carevoice.mobile.v1")!).records)).toHaveLength(0);
  await page.getByRole("button", { name: "Add a record", exact: true }).click();
  await dialog.getByRole("button", { name: "Start recording", exact: true }).click();
  await page.evaluate(() => (window as any).voiceEngine.onerror({ error: "not-allowed" }));
  await expect(dialog.getByRole("alert")).toContainText("blocked");
  await dialog.getByRole("tab", { name: "Text record" }).click();
  await expect(dialog.getByLabel("What happened?", { exact: true })).toBeEditable();
});
