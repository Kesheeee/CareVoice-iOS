import { test, expect } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.addInitScript(() => {
    if (!localStorage.getItem("carevoice.mobile.v1")) localStorage.setItem("carevoice.mobile.v1", JSON.stringify({
      version: 1, language: "en", profile: { nickname: "Language test", ageMonths: 40, stage: "registered", concernNotes: "繁體筆記", firstConcernDate: "2026-10-01" },
      records: [], answers: {}, completedSteps: [],
    }));
  });
  await page.goto("/");
  await page.getByRole("button", { name: "Settings", exact: true }).click();
  await page.getByRole("button", { name: "Language", exact: true }).click();
});

test("Choosing requires Save; all three languages persist without changing notes", async ({ page }) => {
  const sheet = page.getByRole("dialog");
  await sheet.getByRole("radio", { name: /Simplified Chinese/ }).check();
  expect(await page.evaluate(() => JSON.parse(localStorage.getItem("carevoice.mobile.v1")!).language)).toBe("en");
  await sheet.getByRole("button", { name: "Cancel", exact: true }).click();
  await expect(page.getByRole("button", { name: "Language", exact: true })).toBeFocused();
  await page.getByRole("button", { name: "Language", exact: true }).click();
  await expect(sheet.getByRole("radio", { name: /English/ })).toBeChecked();
  for (const [value, choice, save, settings, language] of [
    ["zh-Hans", "Simplified Chinese", "Save", "设定", "语言"],
    ["zh", "Traditional Chinese", "保存", "設定", "語言"],
    ["en", "English", "儲存", "Settings", "Language"],
  ]) {
    await sheet.getByRole("radio", { name: new RegExp(choice) }).check();
    await sheet.getByRole("button", { name: save, exact: true }).click();
    await expect(sheet).toHaveCount(0);
    await expect(page.locator(".language-saved")).toBeVisible();
    await page.reload();
    const data = await page.evaluate(() => JSON.parse(localStorage.getItem("carevoice.mobile.v1")!));
    expect(data.language).toBe(value);
    expect(data.profile.concernNotes).toBe("繁體筆記");
    await expect(page.locator("html")).toHaveAttribute("lang", value === "zh" ? "zh-Hant" : value);
    await page.getByRole("button", { name: settings, exact: true }).click();
    await page.getByRole("button", { name: language, exact: true }).click();
    await expect(sheet.getByRole("radio", { name: new RegExp(choice) })).toBeChecked();
  }
});

test("Storage failures keep the chooser open and the previous language intact", async ({ page }) => {
  await page.evaluate(() => { Storage.prototype.setItem = () => { throw new Error("Storage full"); }; });
  const sheet = page.getByRole("dialog");
  await sheet.getByRole("radio", { name: /Simplified Chinese/ }).check();
  await sheet.getByRole("button", { name: "Save", exact: true }).click();
  await expect(sheet.getByRole("alert")).toContainText("Could not save");
  expect(await page.evaluate(() => JSON.parse(localStorage.getItem("carevoice.mobile.v1")!).language)).toBe("en");
  await page.keyboard.press("Escape");
  await expect(sheet).toHaveCount(0);
});
