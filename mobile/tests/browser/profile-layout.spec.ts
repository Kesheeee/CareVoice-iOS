import {test,expect,chromium,webkit} from '@playwright/test';
for(const browserName of ['chromium','webkit'] as const){
 test.describe(browserName,()=>{

  test('edit profile fits narrow phone screens',async()=>{
   const browser=await ({chromium,webkit}[browserName]).launch();
   const page=await browser.newPage({baseURL:'http://127.0.0.1:5173'});
   try {
   await page.addInitScript(()=>localStorage.setItem('carevoice.mobile.v1',JSON.stringify({version:1,language:'en',profile:{nickname:'Preview',ageMonths:40,stage:'registered',concernNotes:'',firstConcernDate:'2026-10-01'},records:[],answers:{},completedSteps:[]})));
   await page.setViewportSize({width:375,height:812});await page.goto('/');
   await page.locator('.bottom-nav').getByRole('button',{name:'Profile',exact:true}).click();
   await page.getByRole('button',{name:'Edit profile',exact:true}).click();
   const dialog=page.getByRole('dialog',{name:'Edit profile'});
   for(const width of [320,375,390,430]){
    await page.setViewportSize({width,height:812});
    const overflow=await dialog.evaluate(el=>[el,...el.querySelectorAll('.sheet-body,fieldset,label,input,textarea')].filter(node=>node.scrollWidth>node.clientWidth+1).map(node=>node.tagName+':'+node.className));
    expect(overflow).toEqual([]);
    await dialog.getByLabel('Report date',{exact:true}).fill('2026-10-01');
    await expect(dialog.getByRole('button',{name:'Save profile'})).toBeVisible();
   }
   await page.screenshot({path:`test-results/profile-${browserName}.png`});
   } finally { await browser.close(); }
  });
 });
}
