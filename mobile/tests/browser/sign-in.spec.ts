import { test, expect } from "@playwright/test";

test("Fullscreen video is silent, has no controls, and respects reduced motion", async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 812 });
  await page.goto("/#sign-in");
  const video = page.locator(".sign-in-video video");
  await expect.poll(() => video.evaluate((element: HTMLVideoElement) => element.readyState)).toBeGreaterThanOrEqual(2);
  await expect.poll(() => video.evaluate((element: HTMLVideoElement) => element.paused)).toBe(false);
  await expect(page.getByRole("button", { name: "Pause animation" })).toHaveCount(0);
  expect(await video.evaluate((element: HTMLVideoElement) => element.controls)).toBe(false);
  const bounds = await page.locator(".sign-in-video").boundingBox();
  expect(bounds).toEqual({ x: 0, y: 0, width: 375, height: 812 });
  expect(await video.evaluate((element: HTMLVideoElement) => element.muted && element.loop && element.playsInline)).toBe(true);
  await page.emulateMedia({ reducedMotion: "reduce" });
  await expect(video).toHaveCount(0);
  await expect(page.locator(".sign-in-video img")).toBeVisible();
  expect(await page.locator(".sign-in-video img").evaluate((element: HTMLImageElement) => element.naturalWidth)).toBeGreaterThan(0);
  await page.reload();
  await expect(page.locator(".sign-in-video video")).toHaveCount(0);
});

test("An unavailable video falls back to the still image", async ({ page }) => {
  await page.route("**/media/carevoice-family-hd.mp4", route => route.abort());
  await page.goto("/#sign-in");
  await expect(page.locator(".sign-in-video img")).toBeVisible();
  await expect(page.getByRole("button", { name: "Sign in", exact: true })).toBeVisible();
});

test("Sign-in preview stays local and returns to onboarding", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("button", { name: "I already have an account", exact: true }).click();
  await page.getByRole("button", { name: "Continue with email", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Sign in to CareVoice" })).toBeVisible();
  await expect(page.locator(".bottom-nav")).toHaveCount(0);
  const requests: string[] = [];
  page.on("request", request => { if (request.method() === "POST") requests.push(request.url()); });
  await page.getByLabel("Email", { exact: true }).fill("sample@example.com");
  await page.getByLabel("Password", { exact: true }).fill("sample-only-123");
  await page.getByRole("button", { name: "Show password" }).click();
  await expect(page.getByLabel("Password", { exact: true })).toHaveAttribute("type", "text");
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(page.locator(".sign-in-screen").getByRole("status")).toContainText("not been sent or saved");
  await expect(page.getByLabel("Password", { exact: true })).toHaveValue("");
  expect(requests).toEqual([]);
  expect(await page.evaluate(() => JSON.stringify({ ...localStorage, ...sessionStorage }))).not.toContain("sample-only-123");
  await page.getByRole("button", { name: "Forgot password?" }).click();
  await expect(page.locator(".sign-in-screen").getByRole("status")).toContainText("No reset email has been sent");
  await page.getByRole("button", { name: "Continue on this device" }).click();
  await expect(page.getByLabel("Nickname (optional)")).toBeVisible();
});

test("Sign-in fits phone and tablet widths in both languages", async ({ page }) => {
  for (const language of ["en", "zh"]) {
    await page.goto("/");
    if (language === "zh") {
      await page.getByRole("button", { name: "Get started", exact: true }).click();
      await page.getByRole("button", { name: "Continue on this device", exact: true }).click();
      await page.getByRole("radio", { name: "Already diagnosed", exact: true }).check();
      await page.getByRole("button", { name: "Save profile", exact: true }).click();
      await page.locator(".bottom-nav").getByRole("button", { name: "Profile", exact: true }).click();
      await page.getByRole("button", { name: "Switch to Traditional Chinese" }).click();
      await page.getByRole("button", { name: "登入", exact: true }).click();
    } else {
      await page.getByRole("button", { name: "I already have an account", exact: true }).click();
      await page.getByRole("button", { name: "Continue with email", exact: true }).click();
    }
    for (const width of [320, 375, 414, 768]) {
      await page.setViewportSize({ width, height: 900 });
      await expect(page.locator(".sign-in-screen")).toBeVisible();
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
      const wrappedButtons = await page.locator(".sign-in-screen button").evaluateAll(buttons => buttons.filter(button => button.scrollWidth > button.clientWidth).length);
      expect(wrappedButtons).toBe(0);
    }
    await page.setViewportSize({ width: 375, height: 900 });
    await page.screenshot({ path: `test-results/sign-in-${language}.png`, fullPage: true });
  }
});
