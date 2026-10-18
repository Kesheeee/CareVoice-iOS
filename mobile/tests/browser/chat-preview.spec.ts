import {test,expect} from '@playwright/test';
test('chat preview and consent before post preview',async({page})=>{
 await page.setViewportSize({width:375,height:812});await page.addInitScript(()=>localStorage.setItem('carevoice.mobile.v1',JSON.stringify({version:1,language:'en',profile:{nickname:'Preview',ageMonths:40,stage:'registered',concernNotes:'',firstConcernDate:'2026-10-01'},records:[],answers:{},completedSteps:[]})));
 await page.goto('/');await page.locator('.bottom-nav').getByRole('button',{name:'Community',exact:true}).click();await page.getByRole('button',{name:'Ask a question',exact:true}).click();
 await page.getByRole('textbox',{name:'Message',exact:true}).fill('How can I prepare for an appointment?');await page.getByRole('button',{name:'Send message'}).click();await expect(page.locator('.care-chat-user')).toContainText('prepare');
 await page.screenshot({path:'test-results/chat-preview.png'});
 await page.getByRole('button',{name:'Share a question with parents'}).click();await expect(page.getByRole('button',{name:'Preview community post'})).toBeDisabled();
 await page.getByLabel('Your community question').fill('What should I bring to an appointment?');await page.getByRole('checkbox').check();await page.getByRole('button',{name:'Preview community post'}).click();await expect(page.locator('.ask-question-card')).toContainText('What should I bring');await expect(page.locator('.ask-question-card')).toContainText('Not published');
});
