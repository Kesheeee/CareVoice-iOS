import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateAudioUpload } from '../src/platform/wav.ts';
const box = (type: string, body: Buffer) => {const b=Buffer.alloc(8+body.length);b.writeUInt32BE(b.length);b.write(type,4);body.copy(b,8);return b;};
const track=(type:string)=>box('trak',box('mdia',box('hdlr',Buffer.concat([Buffer.alloc(8),Buffer.from(type)]))));
const container=(video:boolean)=>Buffer.concat([box('ftyp',Buffer.from('M4A ')),box('moov',Buffer.concat([track('soun'),...(video?[track('vide')]:[])]))]);
test('M4A must contain audio without video tracks',async()=>{
 await validateAudioUpload(new File([container(false)],'memo.m4a',{type:'audio/mp4'}));
 await assert.rejects(validateAudioUpload(new File([container(true)],'renamed.m4a',{type:'audio/mp4'})),/file-type/);
});
test('rejects photos, videos and disguised image content',async()=>{
 for(const [name,type] of [['photo.jpg','image/jpeg'],['video.mp4','video/mp4'],['photo.mp3','audio/mpeg']]){
 await assert.rejects(validateAudioUpload(new File(['image content'],name,{type})),/file-type/);
 }
});
