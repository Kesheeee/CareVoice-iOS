import { test, expect } from '@playwright/test';
import { encodeWav } from '../../src/platform/wav';

test('audio upload transcribes, appends text, and rejects long or unreadable files', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 812 });
  await page.addInitScript(() => localStorage.setItem('carevoice.mobile.v1', JSON.stringify({version:1,language:'en',profile:{nickname:'Preview',ageMonths:40,stage:'registered',concernNotes:'',firstConcernDate:'2026-10-01'},records:[],answers:{},completedSteps:[]})));
  await page.goto('/');
  await page.getByRole('button', { name: 'Add a record', exact:true }).first().click();
  await page.evaluate(async () => {
    const path = '/src/platform/auth.ts';
    const { authClient } = await import(/* @vite-ignore */ path);
    authClient.auth.getSession = async () => ({data:{session:{access_token:'test-only'}},error:null});
    (window as any).uploadCalls = 0;
    Object.defineProperty(authClient, "functions", { value: { invoke: async (_name: string, options: any) => {
      (window as any).uploadCalls++;
      const bytes = await options.body.arrayBuffer();
      (window as any).uploadedMagic = new TextDecoder().decode(bytes.slice(0,4));
      return {data:{text:'Today we played together.',language:'en-US'},error:null};
    } } });
  });
  const dialog = page.getByRole('dialog', { name:'Quick Record' });
  await dialog.getByRole('tab', {name:'Text record'}).click();
  const field = dialog.getByRole('textbox', {name:'What happened?',exact:true});
  await field.fill('Earlier note.');
  await dialog.getByRole('tab', {name:'Voice record'}).click();
  await expect(dialog.getByRole('button',{name:'Upload audio',exact:true})).toBeVisible();
  const file = dialog.locator('input[type=file]');
  const wav = Buffer.from(encodeWav(new Float32Array(16000)));
  await file.setInputFiles({name:'day.wav',mimeType:'audio/wav',buffer:wav});
  await expect(field).toHaveValue('Earlier note.\nToday we played together.');
  expect(await page.evaluate(() => (window as any).uploadedMagic)).toBe('RIFF');
  const long = Buffer.alloc(44+16000*2*61); wav.copy(long,0,0,44);
  long.writeUInt32LE(long.length-8,4); long.writeUInt32LE(long.length-44,40);
  await file.setInputFiles({name:'long.wav',mimeType:'audio/wav',buffer:long});
  await expect(dialog.getByRole('alert')).toContainText('up to 60 seconds');
  await file.setInputFiles({name:'broken.mp3',mimeType:'audio/mpeg',buffer:Buffer.from('not audio')});
  await expect(dialog.getByRole('alert')).toContainText('Photos and videos aren’t supported');
  await file.setInputFiles({name:'movie.mp4',mimeType:'video/mp4',buffer:wav});
  await expect(dialog.getByRole('alert')).toContainText('Photos and videos aren’t supported');
  expect(await page.evaluate(() => (window as any).uploadCalls)).toBe(1);
  await expect(field).toHaveValue('Earlier note.\nToday we played together.');
  await page.screenshot({path:'test-results/audio-upload.png'});
});

