import { test, expect } from "@playwright/test";
import { readFile } from "node:fs/promises";

test.beforeEach(async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 740 });
  await page.addInitScript(() => { if (!localStorage.getItem("carevoice.mobile.v1")) localStorage.setItem("carevoice.mobile.v1", JSON.stringify({
    version: 1, language: "en", profile: { nickname: "Report test", ageMonths: 40, stage: "registered", concernNotes: "Original concern", firstConcernDate: "2026-10-01" },
    records: [{ id: "report-test", date: "2026-10-18T02:00:00Z", text: "A quiet space helped. 原始筆記", category: "observation", location: "Park", durationMinutes: 5, context: "Busy morning", helped: "Quiet time" }],
    answers: { 101: "yes" }, completedSteps: [],
  })); });
  await page.goto("/");
  await page.getByRole("button", { name: "Settings", exact: true }).click();
  await page.getByRole("button", { name: "Reports & sharing" }).click();
});

test("Native share receives the selected report and cancelling never downloads a copy", async ({ page }) => {
  await page.evaluate(() => Object.defineProperty(navigator, "share", { configurable: true, value: async (payload: unknown) => { (window as any).sharedReport = payload; } }));
  await page.getByRole("button", { name: "Share or download report" }).click();
  const payload = await page.evaluate(() => (window as any).sharedReport);
  expect(payload.text).toContain("Appointment preparation report");
  expect(payload.text).toContain("A quiet space helped. 原始筆記");
  expect(payload.text).toContain("Original concern");
  await page.getByRole("button", { name: "Family", exact: true }).click();
  await page.getByRole("button", { name: "Share or download report" }).click();
  const family = await page.evaluate(() => (window as any).sharedReport.text);
  expect(family).toContain("Family observation summary");
  expect(family).not.toContain("Original concern");
  expect(family).not.toContain("Questions for the appointment");
  let downloads = 0;
  page.on("download", () => downloads++);
  await page.evaluate(() => Object.defineProperty(navigator, "share", { configurable: true, value: async () => { throw new DOMException("Cancelled", "AbortError"); } }));
  await page.getByRole("button", { name: "Share or download report" }).click();
  await expect(page.getByRole("button", { name: "Share or download report" })).toBeEnabled();
  expect(downloads).toBe(0);
});

for (const scenario of ["unavailable", "rejected"]) test(`Report downloads as readable UTF-8 when sharing is ${scenario}`, async ({ page }) => {
  await page.evaluate(scenario => Object.defineProperty(navigator, "share", { configurable: true, value: scenario === "unavailable" ? undefined : async () => { throw new DOMException("Blocked", "NotAllowedError"); } }), scenario);
  const downloadEvent = page.waitForEvent("download");
  await page.getByRole("button", { name: "Share or download report" }).click();
  const download = await downloadEvent;
  expect(download.suggestedFilename()).toBe("carevoice-report.txt");
  const text = await readFile((await download.path())!, "utf8");
  expect(text).toContain("Appointment preparation report");
  expect(text).toContain("A quiet space helped. 原始筆記");
  expect(text).toContain("Duration (min): 5");
});

test("Print button invokes browser printing and print layout includes the report only", async ({ page }) => {
  await page.evaluate(() => { window.print = () => { (window as any).printInvoked = true; }; });
  await page.getByRole("button", { name: "Print / save PDF" }).click();
  expect(await page.evaluate(() => (window as any).printInvoked)).toBe(true);
  await page.emulateMedia({ media: "print" });
  await expect(page.locator(".report-paper")).toBeVisible();
  await expect(page.locator(".report-actions")).toBeHidden();
  await expect(page.locator(".bottom-nav")).toBeHidden();
  await expect(page.locator(".segmented")).toBeHidden();
  const pdf = await page.pdf({ format: "A4" });
  expect(pdf.subarray(0, 5).toString()).toBe("%PDF-");
  expect(pdf.length).toBeGreaterThan(1000);
});

test("Simplified Chinese headings remain structured and empty responses are explained", async ({ page }) => {
  await page.evaluate(() => {
    const data = JSON.parse(localStorage.getItem("carevoice.mobile.v1")!);
    data.language = "zh-Hans";
    data.answers = {};
    localStorage.setItem("carevoice.mobile.v1", JSON.stringify(data));
  });
  await page.reload();
  await page.getByRole("button", { name: "设定", exact: true }).click();
  await page.getByRole("button", { name: "报告同分享" }).click();
  await expect(page.getByRole("heading", { name: "观察记录", exact: true })).toBeVisible();
  await expect(page.locator(".report-paper")).toContainText("尚未记录问卷回答。");
  await expect(page.locator(".report-paper")).toContainText("原始筆記");
});
