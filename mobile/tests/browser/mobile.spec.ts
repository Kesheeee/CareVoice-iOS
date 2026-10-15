import { test, expect, type Page } from "@playwright/test";
const nav = (page: Page, name: string) =>
  page.locator(".bottom-nav").getByRole("button", { name, exact: true });
async function profile(page: Page, stage = "Just noticing differences") {
  await page.getByRole("button", { name: "Get started", exact: true }).click();
  await page.getByLabel("Nickname (optional)").fill("Alex");
  await page.getByRole("radio", { name: stage, exact: true }).check();
  await page.getByRole("button", { name: "Save profile", exact: true }).click();
}
test("Queenie onboarding, skip/autosave, regression follow-up and bilingual reports", async ({
  page,
}) => {
  await page.goto("/");
  await expect(
    page.getByRole("heading", { name: "Welcome to CareVoice" }),
  ).toBeVisible();
  await profile(page);
  await expect(
    page.getByRole("heading", {
      name: "Observation questionnaire",
      exact: true,
    }),
  ).toBeVisible();
  await expect(page.locator(".category-grid>div")).toHaveCount(7);
  await page
    .getByRole("button", { name: "Start questionnaire", exact: true })
    .click();
  await page.getByRole("button", { name: "Not sure", exact: true }).click();
  await page.getByRole("button", { name: "Next", exact: true }).click();
  await expect(page.getByText("2 / 30", { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Skip for now", exact: true }).click();
  await expect(page.getByText("3 / 30", { exact: true })).toBeVisible();
  await page
    .getByRole("button", { name: "Review answers", exact: true })
    .click();
  await expect(page.locator(".review-boundary")).toContainText("No score");
  await page.getByRole("button", { name: /^29\./ }).click();
  await page.getByRole("button", { name: "Yes", exact: true }).click();
  await expect(page.getByText("A change worth discussing")).toBeVisible();
  await expect(page.locator(".notice a")).toHaveAttribute(
    "href",
    "https://www.dhcas.gov.hk/en/faq.html",
  );
  await page
    .getByLabel("Roughly when did this happen? (optional)")
    .fill("Last month");
  await nav(page, "Profile").click();
  await page
    .getByRole("button", { name: "Switch to Traditional Chinese" })
    .click();
  await nav(page, "我的").click();
  await page.getByRole("button", { name: /報告與分享/ }).click();
  await expect(page.locator(".report-paper")).toContainText("Last month");
  await expect(page.locator(".report-paper")).toContainText("剛留意到一些不同");
  await page.reload();
  await expect(page.locator(".dashboard-profile")).toContainText("Alex");
  const saved = await page.evaluate(() =>
    JSON.parse(localStorage.getItem("carevoice.mobile.v1")!),
  );
  expect(saved.profile.stage).toBe("noticed");
  expect(saved.answers[2]).toBe("skipped");
  expect(saved.regressionWhen[29]).toBe("Last month");
});
test("Every other caregiver-selected stage bypasses automatic questionnaire; manual access remains", async ({
  page,
}) => {
  for (const stage of [
    "A professional suggested follow-up",
    "Referred / awaiting assessment",
    "Assessed, with a report",
    "Already diagnosed",
    "Registered for services",
  ]) {
    await page.goto("/");
    await page.evaluate(() => localStorage.clear());
    await page.reload();
    await profile(page, stage);
    await expect(page.locator(".dashboard-greeting")).toBeVisible();
    await expect(page.locator(".questionnaire-intro")).toHaveCount(0);
    await nav(page, "Profile").click();
    await page.getByRole("button", { name: /Observation questions/ }).click();
    await expect(page.getByText("1 / 30", { exact: true })).toBeVisible();
  }
});
test("Record methods, persistence, explicit related records, edit/filter/delete", async ({
  page,
}) => {
  await page.goto("/");
  await profile(page, "Registered for services");
  await nav(page, "Records").click();
  await page.getByRole("button", { name: "Voice entry", exact: true }).click();
  await expect(
    page.getByText("Use your keyboard microphone", { exact: true }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Close", exact: true }).click();
  for (const text of ["Said hello during play", "Waved goodbye"]) {
    await page
      .getByRole("button", { name: "Text record", exact: true })
      .click();
    await page.getByLabel("What happened?").fill(text);
    await page.getByLabel("Category", { exact: true }).selectOption("progress");
    await page.getByLabel("Place (optional)").fill("Home");
    await page
      .getByRole("button", { name: "Save observation", exact: true })
      .click();
  }
  await expect(page.locator(".related-records")).toHaveCount(1);
  await expect(page.locator(".related-records")).toContainText("same category");
  await page.reload();
  await nav(page, "Records").click();
  await page
    .locator(".record-main")
    .filter({ hasText: "Waved goodbye" })
    .click();
  await page.getByLabel("What happened?").fill("Waved goodbye again");
  await page
    .getByRole("button", { name: "Save observation", exact: true })
    .click();
  await page
    .getByRole("textbox", { name: "Search observations" })
    .fill("missing");
  await expect(page.getByText("No matching observations")).toBeVisible();
  await page.getByRole("textbox", { name: "Search observations" }).fill("");
  await page
    .locator(".record-main")
    .filter({ hasText: "Waved goodbye again" })
    .click();
  await page
    .getByRole("button", { name: "Delete observation", exact: true })
    .click();
  await page
    .getByRole("button", { name: "Delete observation", exact: true })
    .click();
  await expect(page.locator(".record-main")).toHaveCount(1);
  await nav(page, "Community").click();
  await expect(
    page.getByRole("heading", { name: "Official resources & support" }),
  ).toBeVisible();
  await page
    .getByText("Does this questionnaire assess my child?", { exact: true })
    .click();
  await expect(page.locator(".community-questions")).toContainText(
    "Only you choose your journey stage.",
  );
});
test("Old version-one saved data remains usable and diagnosed report fields are copied only", async ({
  page,
}) => {
  await page.goto("/");
  await page.evaluate(() =>
    localStorage.setItem(
      "carevoice.mobile.v1",
      JSON.stringify({
        version: 1,
        language: "en",
        profile: {
          nickname: "Existing",
          ageMonths: 40,
          stage: "diagnosed",
          concernNotes: "",
          firstConcernDate: "2026-10-01",
        },
        records: [],
        answers: { 1: "often" },
        completedSteps: [],
      }),
    ),
  );
  await page.reload();
  await expect(page.locator(".dashboard-profile")).toContainText("Existing");
  await page.getByRole("button", { name: "Edit", exact: true }).click();
  await page
    .getByLabel("Diagnosing organisation", { exact: true })
    .fill("Example clinic");
  await page
    .getByLabel("Support level as written in the report")
    .fill("Copied wording");
  await page.getByRole("button", { name: "Save profile", exact: true }).click();
  await nav(page, "Profile").click();
  await page.getByRole("button", { name: /Reports & sharing/ }).click();
  await expect(page.locator(".report-paper")).toContainText("Copied wording");
  await expect(page.locator(".report-paper")).toContainText(
    "copied from report",
  );
  await page.getByRole("button", { name: "Family", exact: true }).click();
  await expect(page.locator(".report-paper")).not.toContainText(
    "Copied wording",
  );
});
test("Phone layouts and bilingual pages fit at 320, 375, 414 and 768px with no subtitles", async ({
  page,
}) => {
  for (const width of [320, 375, 414, 768]) {
    await page.setViewportSize({ width, height: 900 });
    await page.goto("/");
    await page.evaluate(() => localStorage.clear());
    await page.reload();
    await page.screenshot({
      path: `test-results/blue-welcome-${width}.png`,
      fullPage: true,
    });
    await profile(page);
    await page.getByRole("button", { name: "Go to Home", exact: true }).click();
    for (const lang of ["en", "zh"]) {
      if (lang === "zh") {
        await nav(page, "Profile").click();
        await page
          .getByRole("button", { name: "Switch to Traditional Chinese" })
          .click();
        await nav(page, "首頁").click();
      }
      await expect(page.locator(".top-tabs")).toHaveCount(0);
      await expect(page.locator(".topbar button")).toHaveCount(0);
      await page.screenshot({
        path: `test-results/blue-home-${lang}-${width}.png`,
        fullPage: true,
      });
      for (const name of lang === "en"
        ? ["Home", "Records", "Community", "Profile"]
        : ["首頁", "記錄", "社區", "我的"]) {
        await nav(page, name).click();
        expect(
          await page.evaluate(
            () => document.documentElement.scrollWidth <= innerWidth,
          ),
        ).toBe(true);
        await expect(
          page.locator(".page-heading>p,.page-sub,.card-sub"),
        ).toHaveCount(0);
      }
      await nav(page, lang === "en" ? "Records" : "記錄").click();
      await page
        .getByRole("button", {
          name: lang === "en" ? "Text record" : "文字記錄",
          exact: true,
        })
        .click();
      expect(
        await page.evaluate(
          () =>
            document.querySelector("dialog")!.scrollWidth <=
            document.querySelector("dialog")!.clientWidth,
        ),
      ).toBe(true);
      await page
        .getByRole("button", {
          name: lang === "en" ? "Close" : "關閉",
          exact: true,
        })
        .click();
      await nav(page, lang === "en" ? "Home" : "首頁").click();
    }
  }
});
