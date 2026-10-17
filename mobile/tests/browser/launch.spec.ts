import { test, expect } from "@playwright/test";

test("Mobile launch opens and dismisses account sheets over the video", async ({ page }) => {
  for (const width of [320, 375, 414, 768]) {
    await page.setViewportSize({ width, height: 812 });
    await page.goto("/");
    await expect(page.getByRole("heading", { name: /Every little moment/ })).toBeVisible();
    await expect(page.getByLabel("Email", { exact: true })).toHaveCount(0);
    if (width === 375) await page.screenshot({ path: "test-results/carevoice-launch.png" });
    await page.getByRole("button", { name: "Get started", exact: true }).click();
    const sheet = page.getByRole("dialog");
    await expect(sheet.getByRole("heading", { name: "Let’s get started" })).toBeVisible();
    await expect.poll(async () => Math.round((await sheet.boundingBox())!.y + (await sheet.boundingBox())!.height)).toBe(812);
    expect(await sheet.evaluate(element => element.scrollWidth <= element.clientWidth)).toBe(true);
    if (width === 375) await page.screenshot({ path: "test-results/carevoice-account-sheet.png" });
    await page.getByRole("button", { name: "Continue with Google" }).click();
    await expect(sheet.getByRole("status")).toContainText("not connected");
    await page.getByRole("button", { name: "Continue with email", exact: true }).click();
    await expect(sheet.getByRole("heading", { name: "Enter your email" })).toBeVisible();
    await expect(sheet.getByLabel("Password", { exact: true })).toHaveCount(0);
    const emailBounds = await sheet.getByLabel("Email", { exact: true }).boundingBox();
    const iconBounds = await sheet.locator(".sign-in-field-icon").boundingBox();
    const continueBounds = await sheet.getByRole("button", { name: "Continue", exact: true }).boundingBox();
    expect(emailBounds!.height).toBe(56);
    expect(continueBounds!.height).toBe(56);
    expect(continueBounds!.width).toBe(emailBounds!.width);
    expect(Math.abs(iconBounds!.y + iconBounds!.height / 2 - emailBounds!.y - emailBounds!.height / 2)).toBeLessThan(1);
    if (width === 375) await page.screenshot({ path: "test-results/email-entry.png" });
    await sheet.getByLabel("Email", { exact: true }).fill("sample@example.com");
    await sheet.getByRole("button", { name: "Continue", exact: true }).click();
    await expect(sheet.getByRole("status")).toContainText("not been sent or saved");
    await sheet.getByRole("button", { name: "Back", exact: true }).click();
    await page.getByRole("button", { name: "Close", exact: true }).click();
    await expect(sheet).toHaveCount(0);
    await expect(page.getByRole("button", { name: "Get started", exact: true })).toBeFocused();
    await page.getByRole("button", { name: "I already have an account", exact: true }).click();
    await expect(sheet.getByRole("heading", { name: "Welcome back" })).toBeVisible();
    await expect(sheet.getByLabel("Email", { exact: true })).toBeVisible();
    await expect.poll(async () => Math.round((await sheet.boundingBox())!.y + (await sheet.boundingBox())!.height)).toBe(812);
    if (width === 375) await page.screenshot({ path: "test-results/welcome-back.png" });
    await page.keyboard.press("Escape");
    await expect(sheet).toHaveCount(0);
  }
});
