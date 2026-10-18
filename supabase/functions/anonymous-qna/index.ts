import { createClient } from "npm:@supabase/supabase-js@2.118.0";
const url = Deno.env.get("SUPABASE_URL")!;
const auth = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {auth:{persistSession:false,autoRefreshToken:false}});
const db = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {auth:{persistSession:false,autoRefreshToken:false}});
const cors = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, apikey, content-type, x-client-info","Access-Control-Allow-Methods":"POST, OPTIONS","Cache-Control":"no-store"};
const response = (status:number, body:unknown) => Response.json(body,{status,headers:cors});
const uuid = (s:unknown):s is string => typeof s === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
Deno.serve(async req => {
 if(req.method==='OPTIONS') return new Response(null,{status:204,headers:cors});
 if(req.method!=='POST') return response(405,{code:'method'});
 try {
  const token=req.headers.get('authorization')?.replace(/^Bearer /i,'');
  if(!token) return response(401,{code:'auth'});
  const {data:{user},error}=await auth.auth.getUser(token);
  if(error||!user||user.is_anonymous) return response(401,{code:'auth'});
  // Bound even requests without a Content-Length header.
  const reader=req.body?.getReader(); if(!reader)return response(400,{code:'input'});
  const chunks:Uint8Array[]=[];let size=0;
  while(true){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>12000){await reader.cancel();return response(413,{code:'input'});}chunks.push(value);}
  const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
  const input=JSON.parse(new TextDecoder().decode(bytes));
  const safe=(row:Record<string,unknown>)=>({id:row.id,body:row.body,createdAt:row.created_at,isMine:row.author_id===user.id});
  if(input.action==='feed'||input.action==='thread'){
   const thread=input.action==='thread';
   if(thread&&!uuid(input.id))return response(400,{code:'input'});
   if(thread){const {data:q}=await db.from('qna_entries').select('id').eq('id',input.id).is('question_id',null).eq('hidden',false).maybeSingle();if(!q)return response(404,{code:'missing'});}
   let query=db.from('qna_entries').select('id,body,author_id,created_at').eq('hidden',false).order('created_at',{ascending:thread}).order('id',{ascending:thread}).limit(51);
   query=thread?query.eq('question_id',input.id):query.is('question_id',null);
   if(input.cursor){if(!uuid(input.cursor.id)||typeof input.cursor.at!=='string'||!/^\d{4}-\d{2}-\d{2}T[\d:.+Z-]+$/.test(input.cursor.at))return response(400,{code:'input'});const op=thread?'gt':'lt';query=query.or(`created_at.${op}.${input.cursor.at},and(created_at.eq.${input.cursor.at},id.${op}.${input.cursor.id})`);}
   const {data,error}=await query;if(error)throw error;
   const rows=data||[], page=rows.slice(0,50),last=page.at(-1);
   return response(200,{entries:page.map(safe),cursor:rows.length>50&&last?{id:last.id,at:last.created_at}:null});
  }
  if(input.action==='post'||input.action==='reply'){
   const body=typeof input.body==='string'?input.body.trim():'';
   if(body.length<3||body.length>2000||input.confirmed!==true)return response(400,{code:'input'});
   if(input.action==='reply'&&!uuid(input.id))return response(400,{code:'input'});
   const {data,error}=await db.from('qna_entries').insert({author_id:user.id,question_id:input.action==='reply'?input.id:null,body}).select('id,body,author_id,created_at').single();
   if(error){if(error.message.includes('qna_rate_limit'))return response(429,{code:'rate-limit'});if(error.message.includes('qna_question_unavailable'))return response(404,{code:'missing'});throw error;}
   return response(200,{entry:safe(data)});
  }
  if(input.action==='remove'){
   if(!uuid(input.id))return response(400,{code:'input'});
   const {data,error}=await db.from('qna_entries').update({hidden:true}).eq('id',input.id).eq('author_id',user.id).select('id');
   if(error)throw error;return response(data?.length?200:404,{ok:!!data?.length});
  }
  if(input.action==='report'){
   if(!uuid(input.id)||!['privacy','harmful','spam','other'].includes(input.reason))return response(400,{code:'input'});
   const {error}=await db.from('qna_reports').upsert({entry_id:input.id,reporter_id:user.id,reason:input.reason},{onConflict:'entry_id,reporter_id',ignoreDuplicates:true});
   if(error)throw error;return response(200,{ok:true});
  }
  return response(400,{code:'input'});
 }catch{return response(500,{code:'unavailable'});}
});
