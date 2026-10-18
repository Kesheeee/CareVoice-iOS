import {test,expect} from '@playwright/test';
test('birthday wheels support scrolling and keyboard selection',async({page})=>{
 await page.setViewportSize({width:375,height:812});await page.goto('/#onboarding');
 await page.getByRole('button',{name:'Continue',exact:true}).click();
 for(const [name,index] of [['Day',18],['Month',10],['Year',4]] as const){
 const wheel=page.getByRole('listbox',{name,exact:true});await wheel.evaluate((el,i)=>{el.scrollTop=i*44},index);await page.waitForTimeout(250);
 }
 await expect(page.getByRole('listbox',{name:'Day',exact:true}).getByRole('option',{selected:true})).toHaveText('18');
 await expect(page.getByRole('button',{name:'Continue',exact:true})).toBeEnabled();
 await page.getByRole('listbox',{name:'Day',exact:true}).focus();await page.keyboard.press('ArrowDown');await page.waitForTimeout(350);
 await expect(page.getByRole('listbox',{name:'Day',exact:true}).getByRole('option',{selected:true})).toHaveText('19');
 await page.screenshot({path:'test-results/birthday-wheel.png',fullPage:true});
});
