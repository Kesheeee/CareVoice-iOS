import {test,expect,webkit} from '@playwright/test';
test('chat fits phones with compact composer and aligned empty state',async()=>{
 const browser=await webkit.launch();
 try {
 const page=await browser.newPage({baseURL:'http://127.0.0.1:5173',viewport:{width:375,height:812}});
 await page.addInitScript(()=>localStorage.setItem('carevoice.mobile.v1',JSON.stringify({version:1,language:'en',profile:{nickname:'Preview',ageMonths:40,stage:'registered',concernNotes:'',firstConcernDate:'2026-10-01'},records:[],answers:{},completedSteps:[]})));
 await page.goto('/');await page.locator('.bottom-nav').getByRole('button',{name:'Community',exact:true}).click();await page.getByRole('button',{name:'Ask a question',exact:true}).click();
 for(const width of [320,375,430]){
 await page.setViewportSize({width,height:812});
 const dialog=page.getByRole('dialog',{name:'Ask CareVoice'});
 expect(await dialog.evaluate(e=>e.scrollWidth<=e.clientWidth)).toBe(true);
 const input=page.getByRole('textbox',{name:'Message',exact:true});
 expect((await input.boundingBox())!.height).toBeLessThanOrEqual(50);
 await expect(input).toBeVisible();
 }
 await page.setViewportSize({width:375,height:812});await page.screenshot({path:'test-results/chat-layout-webkit.png'});
 await page.getByRole('button',{name:'Appointments',exact:true}).click();await expect(page.getByRole('textbox',{name:'Message',exact:true})).toHaveValue('Appointments');
 } finally {await browser.close();}
});
