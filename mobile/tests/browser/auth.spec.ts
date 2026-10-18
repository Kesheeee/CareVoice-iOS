import { test, expect } from "@playwright/test";

const user = { id: "11111111-1111-4111-8111-111111111111", email: "caregiver@example.com", aud: "authenticated", role: "authenticated", app_metadata: {}, user_metadata: {}, created_at: "2026-10-18T00:00:00Z" };
const token = () => `${Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })).toString("base64url")}.${Buffer.from(JSON.stringify({ sub: user.id, aud: "authenticated", exp: Math.floor(Date.now() / 1000) + 3600 })).toString("base64url")}.test-signature`;
const session = () => ({ access_token: token(), refresh_token: "test-refresh-token", expires_in: 3600, token_type: "bearer", user });
const notebook = { version: 1, language: "en", profile: { nickname: "Saved child", ageMonths: 40, stage: "registered", concernNotes: "Private notes", firstConcernDate: "2026-10-01" }, records: [], answers: {}, completedSteps: [] };

test.beforeEach(async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 740 });
  // Tests never send real email or create real accounts.
  await page.route("https://lbbpuwtwhiectsmhhuej.supabase.co/**", route => route.abort());
});

test("Continue requests an email, preserves the address and does not sign in before verification", async ({ page }) => {
  let sends = 0;
  await page.route("**/auth/v1/otp**", async route => {
    sends++;
    expect(route.request().postDataJSON().email).toBe(user.email);
    expect(new URL(route.request().url()).searchParams.get("redirect_to")).toBe("http://127.0.0.1:5173/");
    await route.fulfill({ json: {} });
  });
  await page.goto("/");
  await page.getByRole("button", { name: "Get started", exact: true }).click();
  await page.getByRole("button", { name: "Continue with email" }).click();
  await page.getByLabel("Email", { exact: true }).fill(user.email);
  await page.getByRole("button", { name: "Continue", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Check your email" })).toBeVisible();
  await expect(page.locator(".sign-in-delivery")).toContainText(user.email);
  expect(sends).toBe(1);
  await expect(page.getByRole("button", { name: /Resend in/ })).toBeDisabled();
  await expect(page.locator(".guided-onboarding-dialog")).toHaveCount(0);
  await page.route("**/auth/v1/verify", route => route.fulfill({ status: 403, headers: { "x-supabase-api-version": "2024-01-01", "access-control-expose-headers": "X-Supabase-Api-Version" }, json: { code: "otp_expired", msg: "Token has expired" } }));
  await page.getByRole("button", { name: "Enter an email code" }).click();
  await page.getByLabel("Email code").fill("123456");
  await page.getByRole("button", { name: "Verify and sign in" }).click();
  await expect(page.getByRole("alert")).toContainText("expired");
  await page.getByRole("button", { name: "Back", exact: true }).click();
  await expect(page.getByLabel("Email", { exact: true })).toHaveValue(user.email);
});

test("Email failure keeps the address and allows another attempt", async ({ page }) => {
  await page.route("**/auth/v1/otp**", route => route.fulfill({ status: 403, headers: { "x-supabase-api-version": "2024-01-01", "access-control-expose-headers": "X-Supabase-Api-Version" }, json: { code: "email_address_not_authorized", msg: "Email address not authorized" } }));
  await page.goto("/");
  await page.getByRole("button", { name: "Get started", exact: true }).click();
  await page.getByRole("button", { name: "Continue with email" }).click();
  await page.getByLabel("Email", { exact: true }).fill(user.email);
  await page.getByRole("button", { name: "Continue", exact: true }).click();
  await expect(page.getByRole("alert")).toContainText("Email delivery is not set up");
  await expect(page.getByLabel("Email", { exact: true })).toHaveValue(user.email);
  await expect(page.getByRole("button", { name: "Continue", exact: true })).toBeEnabled();
});

test("Password login restores only this account's notebook, survives reload, and signs out", async ({ page }) => {
  await page.addInitScript(({ id, notebook }) => {
    localStorage.setItem(`carevoice.mobile.v1.account.${id}`, JSON.stringify(notebook));
    localStorage.setItem("carevoice.mobile.v1.account.someone-else", JSON.stringify({ ...notebook, profile: { ...notebook.profile, nickname: "Another person's child" } }));
  }, { id: user.id, notebook });
  await page.route("**/auth/v1/token**", async route => {
    expect(route.request().postDataJSON().email).toBe(user.email);
    await route.fulfill({ json: session() });
  });
  await page.route("**/auth/v1/user", route => route.fulfill({ json: user }));
  await page.route("**/auth/v1/logout**", route => route.fulfill({ status: 204 }));
  await page.goto("/#sign-in");
  await page.getByLabel("Email", { exact: true }).fill(user.email);
  await page.getByLabel("Password", { exact: true }).fill("test-password-not-real");
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Home", exact: true })).toBeVisible();
  await expect(page.locator("main")).toContainText("Saved child");
  await expect(page.locator("main")).not.toContainText("Another person's child");
  await page.reload();
  await expect(page.getByRole("heading", { name: "Home", exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Settings", exact: true }).click();
  await expect(page.getByText(user.email, { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Sign out", exact: true }).click();
  await expect(page.getByRole("button", { name: "Get started", exact: true })).toBeVisible();
  await expect(page.getByRole("button", { name: "Settings", exact: true })).toHaveCount(0);
});

test("Email callback asks before copying preview notes and removes tokens from the URL", async ({ page }) => {
  await page.addInitScript(notebook => localStorage.setItem("carevoice.mobile.v1", JSON.stringify(notebook)), notebook);
  await page.route("**/auth/v1/user", route => route.fulfill({ json: user }));
  await page.goto(`/#access_token=${token()}&refresh_token=test-refresh-token&expires_in=3600&token_type=bearer&type=magiclink`);
  await expect(page.getByRole("heading", { name: "Keep your existing notes?" })).toBeVisible();
  expect(await page.evaluate(id => localStorage.getItem(`carevoice.mobile.v1.account.${id}`), user.id)).toBeNull();
  await page.getByRole("button", { name: "Keep my notes", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Home", exact: true })).toBeVisible();
  await expect(page.locator("main")).toContainText("Saved child");
  expect(page.url()).not.toContain("access_token");
  expect(await page.evaluate(id => JSON.parse(localStorage.getItem(`carevoice.mobile.v1.account.${id}`)!).profile.concernNotes, user.id)).toBe("Private notes");
});
