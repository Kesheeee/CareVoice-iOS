import {test,expect} from '@playwright/test';
test('home fits phones and opens community and settings',async({page})=>{
 await page.addInitScript(()=>localStorage.setItem('carevoice.mobile.v1',JSON.stringify({version:1,language:'en',profile:{nickname:'Alex',ageMonths:40,stage:'registered',concernNotes:'',firstConcernDate:'2026-10-01'},records:[],answers:{},completedSteps:[]})));
 await page.goto('/');
 for(const width of [320,375,414,768]){await page.setViewportSize({width,height:812});expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);}
 await page.setViewportSize({width:375,height:812});await page.screenshot({path:'test-results/home-refresh.png',fullPage:true});
 await page.locator('.care-home-circles').getByRole('button',{name:'Community',exact:true}).click();await expect(page.getByRole('heading',{name:'Community',exact:true})).toBeVisible();
 await page.locator('.bottom-nav').getByRole('button',{name:'Home',exact:true}).click();await page.locator('.care-home-header').getByRole('button',{name:'Settings'}).click();await expect(page.getByRole('heading',{name:'Settings',exact:true})).toBeVisible();
});
