import { test, expect } from "@playwright/test";

const user = {
  id: "11111111-1111-4111-8111-111111111111",
  email: "caregiver@example.com",
  aud: "authenticated",
  role: "authenticated",
  app_metadata: {},
  user_metadata: {},
  created_at: "2026-10-18T00:00:00Z",
};
const token = () =>
  `${Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })).toString("base64url")}.${Buffer.from(JSON.stringify({ sub: user.id, aud: "authenticated", exp: Math.floor(Date.now() / 1000) + 3600 })).toString("base64url")}.test-signature`;
const session = () => ({
  access_token: token(),
  refresh_token: "test-refresh-token",
  expires_in: 3600,
  token_type: "bearer",
  user,
});
const notebook = {
  version: 1,
  language: "en",
  profile: {
    nickname: "Saved child",
    ageMonths: 40,
    stage: "registered",
    concernNotes: "Private notes",
    firstConcernDate: "2026-10-01",
  },
  records: [],
  answers: {},
  completedSteps: [],
};

test.beforeEach(async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 740 });
  // Tests never send real email or create real accounts.
  await page.route("https://lbbpuwtwhiectsmhhuej.supabase.co/**", (route) =>
    route.abort(),
  );
});

async function openSignup(page: import("@playwright/test").Page) {
  await page.goto("/");
  await page.getByRole("button", { name: "Get started", exact: true }).click();
  await page
    .getByRole("button", { name: "Continue with email", exact: true })
    .click();
  await page.getByLabel("Email", { exact: true }).fill(user.email);
  await page
    .getByLabel("Password", { exact: true })
    .fill("Test-password-9!");
  await page
    .getByLabel("Confirm password", { exact: true })
    .fill("Test-password-9!");
}

test("Signup checks password confirmation and waits for verification", async ({
  page,
}) => {
  let sends = 0;
  await page.route("**/auth/v1/signup**", async (route) => {
    sends++;
    expect(route.request().postDataJSON()).toMatchObject({
      email: user.email,
      password: "Test-password-9!",
    });
    expect(new URL(route.request().url()).searchParams.get("redirect_to")).toBe(
      "http://127.0.0.1:5173/",
    );
    await route.fulfill({ json: { ...user, identities: [] } });
  });
  await openSignup(page);
  for (const weak of ["lowercase9!", "UPPERCASE9!", "NoNumber!", "NoSymbol99"]) {
    await page.getByLabel("Password", { exact: true }).fill(weak);
    await page.getByLabel("Confirm password", { exact: true }).fill(weak);
    await page.getByRole("button", { name: "Create account", exact: true }).click();
    await expect(page.getByRole("alert")).toContainText("five password requirements");
    expect(sends).toBe(0);
  }
  await page.getByLabel("Password", { exact: true }).fill("Test-password-9!");
  await expect(page.locator('.password-requirements li[data-met="true"]')).toHaveCount(5);
  await page
    .getByLabel("Confirm password", { exact: true })
    .fill("different-password");
  await page
    .getByRole("button", { name: "Create account", exact: true })
    .click();
  await expect(page.getByRole("alert")).toContainText("passwords don’t match");
  expect(sends).toBe(0);
  await page
    .getByLabel("Confirm password", { exact: true })
    .fill("Test-password-9!");
  await page
    .getByRole("button", { name: "Create account", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Check your email" }),
  ).toBeVisible();
  expect(sends).toBe(1);
  await expect(page.locator(".guided-onboarding-dialog")).toHaveCount(0);
  expect(
    await page.evaluate(() =>
      JSON.stringify({ ...localStorage, ...sessionStorage }),
    ),
  ).not.toContain("Test-password-9!");
  await page.getByRole("button", { name: "Back to sign in" }).click();
  await expect(page.getByLabel("Email", { exact: true })).toHaveValue(
    user.email,
  );
  await expect(page.getByLabel("Password", { exact: true })).toHaveValue("");
  await expect(page.getByText("Use an email sign-in link instead")).toHaveCount(
    0,
  );
});

test("Signup delivery failure preserves details and allows retry", async ({
  page,
}) => {
  await page.route("**/auth/v1/signup**", (route) =>
    route.fulfill({
      status: 403,
      headers: {
        "x-supabase-api-version": "2024-01-01",
        "access-control-expose-headers": "X-Supabase-Api-Version",
      },
      json: {
        code: "email_address_not_authorized",
        msg: "Email address not authorized",
      },
    }),
  );
  await openSignup(page);
  await page
    .getByRole("button", { name: "Create account", exact: true })
    .click();
  await expect(page.getByRole("alert")).toContainText(
    "Email delivery is not set up",
  );
  await expect(page.getByLabel("Email", { exact: true })).toHaveValue(
    user.email,
  );
  await expect(
    page.getByRole("button", { name: "Create account", exact: true }),
  ).toBeEnabled();
});

test("Invalid and unconfirmed logins do not grant access", async ({ page }) => {
  await page.goto("/#sign-in");
  for (const [code, message] of [
    ["email_not_confirmed", "confirmation link"],
    ["invalid_credentials", "email or password is incorrect"],
  ]) {
    await page.route("**/auth/v1/token**", (route) =>
      route.fulfill({
        status: 400,
        headers: {
          "x-supabase-api-version": "2024-01-01",
          "access-control-expose-headers": "X-Supabase-Api-Version",
        },
        json: { code, msg: code },
      }),
    );
    await page.getByLabel("Email", { exact: true }).fill(user.email);
    await page
      .getByLabel("Password", { exact: true })
      .fill("Test-password-9!");
    await page.getByRole("button", { name: "Sign in", exact: true }).click();
    await expect(page.getByRole("alert")).toContainText(message);
    await expect(
      page.getByRole("heading", { name: "Home", exact: true }),
    ).toHaveCount(0);
  }
});

test("Signup fits phones and keeps keyboard focus visible", async ({
  page,
}) => {
  for (const width of [320, 375, 414]) {
    await page.setViewportSize({ width, height: 667 });
    await page.goto("/");
    await page
      .getByRole("button", { name: "Get started", exact: true })
      .click();
    await page
      .getByRole("button", { name: "Continue with email", exact: true })
      .click();
    await expect(
      page.getByRole("heading", { name: "Create your account" }),
    ).toBeFocused();
    const back = page.getByRole("button", { name: "Back", exact: true });
    expect(await back.evaluate((el) => el.matches(":focus-visible"))).toBe(
      false,
    );
    expect(
      await page
        .locator("dialog")
        .evaluate((el) => el.scrollWidth <= el.clientWidth),
    ).toBe(true);
    await page
      .getByRole("button", { name: "Create account", exact: true })
      .scrollIntoViewIfNeeded();
    await expect(
      page.getByRole("button", { name: "Create account", exact: true }),
    ).toBeInViewport();
    await page
      .getByRole("button", { name: "I already have an account", exact: true })
      .last()
      .click();
    await page.keyboard.press("Shift+Tab");
    await expect(back).toBeFocused();
    expect(
      await back.evaluate((el) => getComputedStyle(el).outlineStyle),
    ).not.toBe("none");
  }
});

test("Password login restores only this account's notebook, survives reload, and signs out", async ({
  page,
}) => {
  await page.addInitScript(
    ({ id, notebook }) => {
      localStorage.setItem(
        `carevoice.mobile.v1.account.${id}`,
        JSON.stringify(notebook),
      );
      localStorage.setItem(
        "carevoice.mobile.v1.account.someone-else",
        JSON.stringify({
          ...notebook,
          profile: { ...notebook.profile, nickname: "Another person's child" },
        }),
      );
    },
    { id: user.id, notebook },
  );
  await page.route("**/auth/v1/token**", async (route) => {
    expect(route.request().postDataJSON().email).toBe(user.email);
    await route.fulfill({ json: session() });
  });
  await page.route("**/auth/v1/user", (route) => route.fulfill({ json: user }));
  await page.route("**/auth/v1/logout**", (route) =>
    route.fulfill({ status: 204 }),
  );
  await page.goto("/#sign-in");
  await page.getByLabel("Email", { exact: true }).fill(user.email);
  await page
    .getByLabel("Password", { exact: true })
    .fill("Test-password-9!");
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Home", exact: true }),
  ).toBeVisible();
  await expect(page.locator("main")).toContainText("Saved child");
  await expect(page.locator("main")).not.toContainText(
    "Another person's child",
  );
  await page.reload();
  await expect(
    page.getByRole("heading", { name: "Home", exact: true }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Settings", exact: true }).click();
  await expect(page.getByText(user.email, { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Sign out", exact: true }).click();
  await expect(
    page.getByRole("button", { name: "Get started", exact: true }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Settings", exact: true }),
  ).toHaveCount(0);
});

test("Email callback asks before copying preview notes and removes tokens from the URL", async ({
  page,
}) => {
  await page.addInitScript(
    (notebook) =>
      localStorage.setItem("carevoice.mobile.v1", JSON.stringify(notebook)),
    notebook,
  );
  await page.route("**/auth/v1/user", (route) => route.fulfill({ json: user }));
  await page.goto(
    `/#access_token=${token()}&refresh_token=test-refresh-token&expires_in=3600&token_type=bearer&type=signup`,
  );
  await expect(
    page.getByRole("heading", { name: "Keep your existing notes?" }),
  ).toBeVisible();
  expect(
    await page.evaluate(
      (id) => localStorage.getItem(`carevoice.mobile.v1.account.${id}`),
      user.id,
    ),
  ).toBeNull();
  await page
    .getByRole("button", { name: "Keep my notes", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Home", exact: true }),
  ).toBeVisible();
  await expect(page.locator("main")).toContainText("Saved child");
  expect(page.url()).not.toContain("access_token");
  expect(
    await page.evaluate(
      (id) =>
        JSON.parse(localStorage.getItem(`carevoice.mobile.v1.account.${id}`)!)
          .profile.concernNotes,
      user.id,
    ),
  ).toBe("Private notes");
});

test("Existing email-link accounts can request and complete a password reset", async ({
  page,
}) => {
  let resets = 0;
  await page.route("**/auth/v1/recover**", async (route) => {
    resets++;
    expect(route.request().postDataJSON().email).toBe(user.email);
    await route.fulfill({ json: {} });
  });
  await page.goto("/#sign-in");
  await page.getByRole("button", { name: "Set or reset password" }).click();
  await page.getByLabel("Email", { exact: true }).fill(user.email);
  await page.getByRole("button", { name: "Send reset email" }).click();
  await expect(
    page.getByRole("heading", { name: "Check your email" }),
  ).toBeVisible();
  expect(resets).toBe(1);
  await expect(
    page.getByRole("heading", { name: "Home", exact: true }),
  ).toHaveCount(0);
  await page.addInitScript(
    ({ id, notebook }) =>
      localStorage.setItem(
        `carevoice.mobile.v1.account.${id}`,
        JSON.stringify(notebook),
      ),
    { id: user.id, notebook },
  );
  let updates = 0;
  await page.route("**/auth/v1/user", async (route) => {
    if (route.request().method() === "PUT") {
      updates++;
      expect(route.request().postDataJSON().password).toBe("New-test-password-9!");
    }
    await route.fulfill({ json: user });
  });
  await page.goto(
    `/?recovery-test=1#access_token=${token()}&refresh_token=test-refresh-token&expires_in=3600&token_type=bearer&type=recovery`,
  );
  await expect(
    page.getByRole("heading", { name: "Choose a new password" }),
  ).toBeVisible();
  await page.reload();
  await expect(
    page.getByRole("heading", { name: "Choose a new password" }),
  ).toBeVisible();
  await page.getByLabel("New password", { exact: true }).fill("weakpassword");
  await page.getByLabel("Confirm password", { exact: true }).fill("weakpassword");
  await page.getByRole("button", { name: "Save password and continue" }).click();
  await expect(page.getByRole("alert")).toContainText("five password requirements");
  expect(updates).toBe(0);
  await page
    .getByLabel("New password", { exact: true })
    .fill("New-test-password-9!");
  await page
    .getByLabel("Confirm password", { exact: true })
    .fill("does-not-match");
  await page
    .getByRole("button", { name: "Save password and continue" })
    .click();
  await expect(page.getByRole("alert")).toContainText("passwords don’t match");
  expect(updates).toBe(0);
  await page
    .getByLabel("Confirm password", { exact: true })
    .fill("New-test-password-9!");
  await page
    .getByRole("button", { name: "Save password and continue" })
    .click();
  await expect(
    page.getByRole("heading", { name: "Home", exact: true }),
  ).toBeVisible();
  expect(updates).toBe(1);
  expect(
    await page.evaluate(() =>
      JSON.stringify({ ...localStorage, ...sessionStorage }),
    ),
  ).not.toContain("New-test-password-9!");
});


test("Email rate limits explain the failed request without reporting signup success", async ({ page }) => {
  await page.route("**/auth/v1/signup**", route => route.fulfill({ status: 429, headers: { "x-supabase-api-version": "2024-01-01", "access-control-expose-headers": "X-Supabase-Api-Version" }, json: { code: "over_email_send_rate_limit", msg: "email rate limit exceeded" } }));
  await openSignup(page);
  await page.getByRole("button", { name: "Create account", exact: true }).click();
  await expect(page.getByRole("alert")).toContainText("Email delivery has reached its sending limit");
  await expect(page.getByRole("heading", { name: "Check your email" })).toHaveCount(0);
  await expect(page.getByLabel("Email", { exact: true })).toHaveValue(user.email);
});
