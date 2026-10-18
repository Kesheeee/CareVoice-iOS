import {test,expect} from '@playwright/test';
test('community question and bookmark flow fits phone',async({page})=>{
 await page.setViewportSize({width:375,height:812});
 await page.addInitScript(()=>localStorage.setItem('carevoice.mobile.v1',JSON.stringify({version:1,language:'en',profile:{nickname:'Preview',ageMonths:40,stage:'registered',concernNotes:'',firstConcernDate:'2026-10-01'},records:[],answers:{},completedSteps:[]})));
 await page.goto('/');await page.locator('.bottom-nav').getByRole('button',{name:'Community',exact:true}).click();
 await page.getByRole('button',{name:'Save question',exact:true}).first().click();
 await expect(page.getByRole('button',{name:'Save question',exact:true}).first()).toHaveAttribute('aria-pressed','true');await expect(page.locator('.ask-stats')).toHaveCount(0);
 expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
});
