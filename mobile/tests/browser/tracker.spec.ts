import {test, expect} from '@playwright/test';
test('calendar filters dates and saves a note on the chosen day', async ({page}) => {
  await page.setViewportSize({width:375,height:812});
  await page.addInitScript(() => {
    if(localStorage.getItem('carevoice.mobile.v1')) return;
    localStorage.setItem('carevoice.mobile.v1',JSON.stringify({version:1,language:'en',profile:{nickname:'Preview',ageMonths:40,stage:'registered',concernNotes:'',firstConcernDate:'2026-10-01'},records:[],answers:{},completedSteps:[]}));
  });
  await page.goto('/');
  await page.locator('.bottom-nav').getByRole('button',{name:'Tracker',exact:true}).click();
  await page.getByRole('button',{name:'Previous month'}).click();
  await page.locator('.tracker-day:not(.outside)').filter({hasText:/^15$/}).click();
  const chosen = await page.locator('.tracker-day[aria-pressed=true]').getAttribute('aria-label');
  await page.getByRole('button',{name:'Add record',exact:true}).click();
  await page.getByRole('tab',{name:'Text record',exact:true}).click();
  await page.locator('dialog textarea').first().fill('A calm afternoon together.');
  await page.getByRole('button',{name:'Save record',exact:true}).click();
  await expect(page.getByRole('heading',{name:'Record details'})).toBeVisible();
  const date=await page.evaluate(()=>JSON.parse(localStorage.getItem('carevoice.mobile.v1')!).records[0].date);
  expect(new Date(date).getDate()).toBe(15);
  await page.locator('.bottom-nav').getByRole('button',{name:'Tracker',exact:true}).click();
  await expect(page.locator('.record-main')).toContainText('A calm afternoon');
  expect(chosen).toContain('15');
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
  await page.screenshot({path:'test-results/tracker-calendar.png',fullPage:true});
});
