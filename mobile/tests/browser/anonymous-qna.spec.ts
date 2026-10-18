import {test,expect} from '@playwright/test';
test('anonymous Q&A supports deliberate publishing and reply UI',async({page})=>{
 await page.setViewportSize({width:375,height:812});
 await page.addInitScript(()=>localStorage.setItem('carevoice.mobile.v1',JSON.stringify({version:1,language:'en',profile:{nickname:'Preview',ageMonths:40,stage:'registered',concernNotes:'',firstConcernDate:'2026-10-01'},records:[],answers:{},completedSteps:[]})));
 await page.goto('/');
 await page.evaluate(async()=>{
 const path='/src/platform/auth.ts';const {authClient}=await import(/* @vite-ignore */path);
 authClient.auth.getSession=async()=>({data:{session:{access_token:'test'}},error:null});
 const entries:any[]=[];const replies:any[]=[];
 Object.defineProperty(authClient,'functions',{value:{invoke:async(_name:string,{body}:any)=>{
 if(body.action==='feed')return {data:{entries,cursor:null},error:null};
 if(body.action==='thread')return {data:{entries:replies,cursor:null},error:null};
 if(body.action==='post'||body.action==='reply'){const entry={id:crypto.randomUUID(),body:body.body,isMine:true,createdAt:new Date().toISOString()};(body.action==='post'?entries:replies).push(entry);return {data:{entry},error:null};}
 return {data:{ok:true},error:null};
 }}});
 });
 await page.locator('.bottom-nav').getByRole('button',{name:'Community',exact:true}).click();
 const section=page.locator('.anonymous-qna');
 await section.getByRole('button',{name:'Ask anonymously',exact:true}).click();
 await section.getByLabel('Your question',{exact:true}).fill('How do you prepare for appointments?');
 await expect(section.getByRole('button',{name:'Publish question',exact:true})).toBeDisabled();
 await section.getByRole('checkbox').check();await section.getByRole('button',{name:'Publish question',exact:true}).click();
 await expect(section.locator('.qna-card')).toContainText('How do you prepare');
 await section.getByRole('button',{name:'View replies'}).click();
 await section.getByLabel('Your reply',{exact:true}).fill('I bring my notes.');
 await section.getByRole('checkbox').check();await section.getByRole('button',{name:'Reply anonymously',exact:true}).click();
 await expect(section.locator('.qna-card').last()).toContainText('I bring my notes.');
 expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
 await section.scrollIntoViewIfNeeded();await page.screenshot({path:'test-results/anonymous-qna.png'});
});
