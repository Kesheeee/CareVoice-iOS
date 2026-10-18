import { test, expect } from "@playwright/test";

test("Survey saves all seven stages, goals and notes and preserves answers on Back", async ({ page }) => {
  const stages = ["noticed", "professionalFollowUp", "awaitingAssessment", "assessed", "registered", "waitingSupport", "receivingServices"];
  for (const stage of stages) {
    await page.goto("/"); await page.evaluate(() => localStorage.clear()); await page.goto("/#onboarding"); await page.reload();
    const dialog = page.getByRole("dialog"); const next = dialog.getByRole("button", {name: "Continue", exact: true});
    await dialog.getByLabel("Nickname (optional)").fill("Alex"); await next.click();
    await dialog.getByLabel("Day", {exact:true}).selectOption("01"); await dialog.getByLabel("Month", {exact:true}).selectOption("10"); await dialog.getByLabel("Year", {exact:true}).selectOption("2022"); await next.click();
    await expect(next).toBeDisabled(); await dialog.locator(`input[value="${stage}"]`).check();
    await dialog.getByRole("button", {name:"Back",exact:true}).click();
    await expect(dialog.getByLabel("Year", {exact:true})).toHaveValue("2022"); await next.click();
    await expect(dialog.locator(`input[value="${stage}"]`)).toBeChecked(); await next.click();
    await dialog.getByLabel("Preparing documents", {exact:true}).check();
    await dialog.getByLabel("Recording observations", {exact:true}).check(); await next.click();
    await dialog.getByLabel("Notes (optional)").fill("We would like help preparing.");
    await dialog.getByRole("button", {name:"Back",exact:true}).click();
    await expect(dialog.getByLabel("Preparing documents", {exact:true})).toBeChecked(); await next.click();
    await expect(dialog.getByLabel("Notes (optional)")).toHaveValue("We would like help preparing.");
    await dialog.getByRole("button", {name:"See my next steps",exact:true}).click();
    await expect(dialog).toHaveCount(0);
    const saved = await page.evaluate(() => JSON.parse(localStorage.getItem("carevoice.mobile.v1")!));
    expect(saved.profile).toMatchObject({nickname:"Alex",birthDate:"2022-10-01",stage,supportGoals:["documents","observations"],concernNotes:"We would like help preparing."});
    if(stage === "noticed") await expect(page.getByRole("heading",{name:"Observation questionnaire",exact:true})).toBeVisible();
    else await expect(page.locator(".dashboard-greeting")).toBeVisible();
    await page.reload(); await expect(page.getByRole("dialog")).toHaveCount(0);
  }
});

test("Five survey pages fit phones in both languages; optional answers can be skipped", async ({page}) => {
  for(const language of ["en","zh"]) for(const [width,height] of [[320,640],[375,667],[414,896],[560,1228],[768,812]]) {
    await page.setViewportSize({width,height}); await page.goto("/");
    await page.evaluate(lang => localStorage.setItem("carevoice.mobile.v1", JSON.stringify({version:1,language:lang,profile:null,records:[],answers:{},completedSteps:[]})),language);
    await page.goto("/#onboarding"); await page.reload();
    const dialog=page.getByRole("dialog");
    for(let step=0;step<5;step++) {
      await expect(dialog.locator("h1")).toHaveCount(1);
      expect(await dialog.evaluate(el=>el.scrollWidth<=el.clientWidth)).toBe(true);
      const button=dialog.locator("button.primary"); const bounds=await button.boundingBox();
      expect(bounds!.y+bounds!.height).toBeLessThanOrEqual(height);
      if(step===1) { await dialog.locator("select").nth(0).selectOption("01"); await dialog.locator("select").nth(1).selectOption("10"); await dialog.locator("select").nth(2).selectOption("2022"); }
      if(step===2) {
        const area=await dialog.locator(".onboarding-content").boundingBox();
        await expect(dialog.getByRole("radio")).toHaveCount(7);
        for(const card of await dialog.locator(".onboarding-stage").all()) {
          const box=await card.boundingBox(); expect(box!.y).toBeGreaterThanOrEqual(area!.y); expect(box!.y+box!.height).toBeLessThanOrEqual(area!.y+area!.height);
        }
        const lastCard = await dialog.locator(".onboarding-stage").last().boundingBox();
        expect(bounds!.y - (lastCard!.y + lastCard!.height)).toBeLessThanOrEqual(40);
        await dialog.getByRole("radio").last().check();
      }
      if(width===560 && step===2) await page.screenshot({path:`test-results/survey-tall-${language}.png`});
      if(width===375) await page.screenshot({path:`test-results/survey-${language}-${step}.png`});
      if(step===0 || step===4) await dialog.locator(".survey-skip").click(); else await button.click();
    }
    await expect(dialog).toHaveCount(0);
  }
});
