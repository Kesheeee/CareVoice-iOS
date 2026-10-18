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

test("A video error falls back to the still image", async ({ page }) => {
  await page.goto("/#sign-in");
  // WebKit media requests may bypass Playwright routing; exercise the media error event directly.
  await page.locator(".sign-in-video video").dispatchEvent("error");
  await expect(page.locator(".sign-in-video img")).toBeVisible();
  await expect(page.getByRole("button", { name: "Sign in", exact: true })).toBeVisible();
});

test("Password forms fit phone widths in all three languages", async ({ page }) => {
  await page.route("https://lbbpuwtwhiectsmhhuej.supabase.co/**", route => route.abort());
  await page.goto("/#sign-in");
  for (const language of ["en", "zh", "zh-Hans"]) {
    await page.evaluate(language => localStorage.setItem("carevoice.mobile.v1", JSON.stringify({version:1,language,profile:null,records:[],answers:{},completedSteps:[]})), language);
    await page.reload();
    for (const width of [320, 375, 414]) {
      await page.setViewportSize({ width, height: 740 });
      await expect(page.locator(".sign-in-screen")).toBeVisible();
      expect(await page.locator("dialog").evaluate(el => el.scrollWidth <= el.clientWidth)).toBe(true);
      expect(await page.locator(".sign-in-screen button").evaluateAll(buttons => buttons.filter(button => button.scrollWidth > button.clientWidth).length)).toBe(0);
    }
    await page.locator(".sign-in-switch").click();
    await expect(page.locator(".create-account-screen")).toBeVisible();
    expect(await page.locator("dialog").evaluate(el => el.scrollWidth <= el.clientWidth)).toBe(true);
    await expect(page.locator("input[autocomplete=new-password]")).toHaveCount(2);
  }
});
