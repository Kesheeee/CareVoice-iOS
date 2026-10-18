import { test, expect } from "@playwright/test";

test("login video keeps playing across two loop boundaries", async ({ page }) => {
  await page.goto("/#sign-in");
  const video = page.locator(".sign-in-video video");
  await expect.poll(() => video.evaluate((el: HTMLVideoElement) => el.readyState)).toBeGreaterThanOrEqual(2);
  for (let loop = 0; loop < 2; loop++) {
    await video.evaluate((el: HTMLVideoElement) => { el.currentTime = el.duration - 0.3; });
    await expect.poll(() => video.evaluate((el: HTMLVideoElement) => el.currentTime)).toBeLessThan(2);
    await expect.poll(() => video.evaluate((el: HTMLVideoElement) => !el.paused && !el.ended)).toBe(true);
  }
});

test("temporary playback refusal can recover on a tap and on page return", async ({ page }) => {
  await page.addInitScript(() => {
    const play = HTMLMediaElement.prototype.play;
    let blocked = true;
    document.addEventListener("pointerdown", () => { blocked = false; });
    HTMLMediaElement.prototype.play = function () {
      if (blocked) {
        this.pause();
        return Promise.reject(new DOMException("Autoplay blocked", "NotAllowedError"));
      }
      return play.call(this);
    };
  });
  await page.goto("/#sign-in");
  const video = page.locator(".sign-in-video video");
  await expect.poll(() => video.evaluate((el: HTMLVideoElement) => el.readyState)).toBeGreaterThanOrEqual(2);
  await expect(page.locator(".sign-in-video img")).toHaveCount(0);
  await page.getByRole("heading", { name: "Welcome back", exact: true }).click();
  await expect.poll(() => video.evaluate((el: HTMLVideoElement) => el.paused)).toBe(false);
  await video.evaluate((el: HTMLVideoElement) => { el.pause(); window.dispatchEvent(new Event("pageshow")); });
  await expect.poll(() => video.evaluate((el: HTMLVideoElement) => el.paused)).toBe(false);
  await page.emulateMedia({ reducedMotion: "reduce" });
  await expect(page.locator(".sign-in-video img")).toBeVisible();
});
