import { test, expect } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.addInitScript(() => {
    if (localStorage.getItem("carevoice.mobile.v1")) return;
    localStorage.setItem("carevoice.mobile.v1", JSON.stringify({
      version: 1, language: "en", profile: { nickname: "Preview", ageMonths: 40, stage: "registered", concernNotes: "", firstConcernDate: "2026-10-01" },
      answers: {}, completedSteps: [], records: [
        { id: "recent", date: "2026-10-18T05:00:00Z", text: "Covered ears in the busy shop.", category: "observation", location: "Supermarket", durationMinutes: 2, context: "", helped: "We stepped outside." },
        { id: "earlier", date: "2026-10-17T05:00:00Z", text: "Asked for a quiet break.", category: "observation", location: "", durationMinutes: null, context: "", helped: "" },
      ],
    }));
  });
});

test("read first, edit explicitly, save back to details, then delete with confirmation", async ({ page }) => {
  await page.goto("/");
  await page.locator(".bottom-nav").getByRole("button", { name: "Records", exact: true }).click();
  await expect(page.getByRole("button", { name: "Reports", exact: true })).toBeVisible();
  await expect(page.locator(".records-options")).toHaveCount(0);
  await page.locator(".record-main").filter({ hasText: "Covered ears" }).click();
  await expect(page.getByRole("heading", { name: "Record details" })).toBeVisible();
  await expect(page.locator("dialog")).toHaveCount(0);
  await page.locator(".record-detail-related-list").getByRole("button").click();
  await expect(page.locator(".record-detail-note")).toHaveText("Asked for a quiet break.");
  await page.getByRole("button", { name: "Edit", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Edit observation" })).toBeVisible();
  await page.locator("dialog textarea").first().fill("Asked for a quiet break. We listened.");
  await page.getByRole("button", { name: "Save observation", exact: true }).click();
  await expect(page.locator("dialog")).toHaveCount(0);
  await expect(page.getByRole("status")).toHaveText("Record saved");
  await expect(page.locator(".record-detail-note")).toHaveText("Asked for a quiet break. We listened.");
  await page.getByRole("button", { name: "Delete record", exact: true }).click();
  await page.getByRole("button", { name: "Keep observation" }).click();
  await expect(page.locator(".record-detail-note")).toBeVisible();
  await page.getByRole("button", { name: "Delete record", exact: true }).click();
  await page.getByRole("button", { name: "Delete observation", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Records", exact: true })).toBeVisible();
  await expect(page.locator(".record-main")).toHaveCount(1);
  await page.reload();
  expect(await page.evaluate(() => JSON.parse(localStorage.getItem("carevoice.mobile.v1")!).records.length)).toBe(1);
});

test("new text record opens saved details", async ({ page }) => {
  await page.goto("/");
  await page.locator(".bottom-nav").getByRole("button", { name: "Records", exact: true }).click();
  await page.getByRole("button", { name: "Add a record" }).click();
  await page.getByRole("tab", { name: "Text record", exact: true }).click();
  await page.locator("dialog textarea").first().fill("A new little win.");
  await page.getByRole("button", { name: "Save record", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Record details" })).toBeVisible();
  await expect(page.locator(".record-detail-note")).toHaveText("A new little win.");
});

test("record details fit phone widths in English and both Chinese variants", async ({ page }) => {
  await page.goto("/");
  for (const language of ["en", "zh", "zh-Hans"]) {
    await page.evaluate(language => {
      const data = JSON.parse(localStorage.getItem("carevoice.mobile.v1")!); data.language = language;
      localStorage.setItem("carevoice.mobile.v1", JSON.stringify(data));
    }, language);
    await page.reload();
    await page.locator(".bottom-nav button").nth(1).click();
    await page.locator(".record-main").first().click();
    for (const width of [320, 375, 414, 768]) {
      await page.setViewportSize({ width, height: 812 });
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
      expect(await page.locator(".record-details").evaluate(el => el.scrollWidth <= el.clientWidth)).toBe(true);
      if (language === "en" && width === 375) await page.screenshot({ path: "test-results/record-details-phone.png", fullPage: true });
    }
  }
});
