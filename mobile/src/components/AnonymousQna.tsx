import {useEffect,useRef,useState} from 'react';
import {MessageCircle,ShieldCheck,RefreshCw,ArrowLeft} from 'lucide-react';
import {authClient} from '../platform/auth';
import {translator} from '../i18n';
import type {Language} from '../domain';
type Entry={id:string;body:string;createdAt:string;isMine:boolean};
type Cursor={id:string;at:string}|null;
export function AnonymousQna({language}:{language:Language}){
 const t=translator(language);
 const [entries,setEntries]=useState<Entry[]>([]),[replies,setReplies]=useState<Entry[]>([]);
 const [thread,setThread]=useState<Entry|null>(null),[compose,setCompose]=useState(false);
 const [body,setBody]=useState(''),[confirmed,setConfirmed]=useState(false);
 const [busy,setBusy]=useState(false),[loading,setLoading]=useState(true),[signedIn,setSignedIn]=useState(false);
 const [error,setError]=useState(''),[notice,setNotice]=useState(''),[cursor,setCursor]=useState<Cursor>(null);
 const [report,setReport]=useState<string|null>(null),[reason,setReason]=useState('privacy');
 const request=useRef(0);
 const api=async(input:Record<string,unknown>)=>{
  const {data,error}=await authClient.functions.invoke('anonymous-qna',{body:input});
  if(error){const res=error.context;const detail=res instanceof Response?await res.json().catch(()=>null):null;throw new Error(detail?.code||'unavailable');}
  return data;
 };
 const message=(e:unknown)=>e instanceof Error&&e.message==='rate-limit'?t('Please wait a minute before posting again.','請稍候一分鐘再發佈。'):e instanceof Error&&e.message==='auth'?t('Sign in to join the Q&A.','請登入參與問答。'):t('Couldn’t load or save. Please try again.','未能載入或儲存，請再試一次。');
 const load=async(selected:Entry|null=null,more:Cursor=null)=>{
  const generation=++request.current;setLoading(true);setError('');
  try{
   const {data:{session}}=await authClient.auth.getSession();if(generation!==request.current)return;
   setSignedIn(!!session);if(!session){setEntries([]);setReplies([]);return;}
   const result=await api({action:selected?'thread':'feed',id:selected?.id,cursor:more});if(generation!==request.current)return;
   if(selected)setReplies(old=>more?[...old,...result.entries]:result.entries);else setEntries(old=>more?[...old,...result.entries]:result.entries);
   setCursor(result.cursor);
  }catch(e){if(generation===request.current)setError(message(e));}
  finally{if(generation===request.current)setLoading(false);}
 };
 useEffect(()=>{void load();const {data:{subscription}}=authClient.auth.onAuthStateChange(()=>{setThread(null);setCompose(false);setBody('');setConfirmed(false);setTimeout(()=>void load(),0);});return()=>{request.current++;subscription.unsubscribe();};},[]);
 const open=(entry:Entry|null)=>{setThread(entry);setCompose(false);setBody('');setConfirmed(false);setNotice('');setReport(null);setReplies([]);setCursor(null);void load(entry);};
 const submit=async()=>{if(busy)return;setBusy(true);setError('');try{await api({action:thread?'reply':'post',id:thread?.id,body,confirmed});setBody('');setConfirmed(false);setCompose(false);setNotice(t('Published anonymously.','已匿名發佈。'));await load(thread);}catch(e){setError(message(e));}finally{setBusy(false);}};
 const remove=async(entry:Entry)=>{setBusy(true);setError('');try{await api({action:'remove',id:entry.id});if(thread?.id===entry.id)open(null);else await load(thread);}catch(e){setError(message(e));}finally{setBusy(false);}};
 const card=(entry:Entry,isQuestion=false)=><article className="qna-card" key={entry.id}>
  <div className="qna-byline"><ShieldCheck size={16}/><span>{entry.isMine?t('You · Anonymous','你 · 匿名'):t('Anonymous parent','匿名家長')}</span><time>{new Date(entry.createdAt).toLocaleDateString(language==='en'?'en-GB':'zh-HK',{month:'short',day:'numeric'})}</time></div>
  <p>{entry.body}</p>
  <div className="qna-card-actions">{isQuestion&&!thread&&<button onClick={()=>open(entry)}><MessageCircle size={16}/>{t('View replies','查看回覆')}</button>}{entry.isMine?<button disabled={busy} onClick={()=>void remove(entry)}>{t('Remove','移除')}</button>:<button onClick={()=>{setReport(entry.id);setNotice('');}}>{t('Report','舉報')}</button>}</div>
 </article>;
 return <section className="anonymous-qna" aria-labelledby="qna-heading">
  <div className="qna-heading"><h2 id="qna-heading">{t('Anonymous Q&A','匿名問答')}</h2><button aria-label={t('Refresh questions','重新載入問題')} disabled={loading||busy} onClick={()=>void load(thread)}><RefreshCw size={18}/></button></div>
  <p className="qna-caption">{t('Ask parents. Share experiences. Keep your name private.','向家長提問，分享經驗，毋須公開姓名。')}</p>
  {!signedIn&&!loading?<p className="qna-empty">{t('Sign in to read, ask and reply anonymously.','登入後即可閱讀、匿名提問及回覆。')}</p>:<>
   {thread?<button className="qna-back" onClick={()=>open(null)}><ArrowLeft size={16}/>{t('All questions','所有問題')}</button>:<button className="secondary full" disabled={!signedIn||busy} onClick={()=>{setCompose(!compose);setBody('');setConfirmed(false);}}>{t('Ask anonymously','匿名提問')}</button>}
   {thread&&card(thread,true)}
   {(compose||thread)&&<form className="qna-compose" onSubmit={e=>{e.preventDefault();void submit();}}>
    <label htmlFor="qna-body">{thread?t('Your reply','你的回覆'):t('Your question','你的問題')}</label>
    <textarea id="qna-body" value={body} disabled={busy} onChange={e=>{setBody(e.target.value);setConfirmed(false);}} minLength={3} maxLength={2000} required rows={3} placeholder={t('What would you like to share?','你想分享甚麼？')}/>
    <small>{t('Shared with signed-in users. CareVoice keeps a private account link.','內容供已登入用戶閱讀。CareVoice 會保留私人帳戶連結。')}</small>
    <label className="qna-consent"><input type="checkbox" checked={confirmed} disabled={busy} onChange={e=>setConfirmed(e.target.checked)}/>{t('I removed names and personal details.','我已移除姓名及個人資料。')}</label>
    <button className="primary" disabled={busy||!confirmed||body.trim().length<3}>{busy?t('Publishing…','發佈中……'):thread?t('Reply anonymously','匿名回覆'):t('Publish question','發佈問題')}</button>
   </form>}
   {loading&&<p role="status">{t('Loading…','載入中……')}</p>}
   {notice&&<p role="status" className="qna-caption">{notice}</p>}
   {thread?replies.map(entry=>card(entry)):entries.map(entry=>card(entry,true))}
   {!loading&&!error&&!(thread?replies:entries).length&&<p className="qna-empty">{thread?t('No replies yet. Share your experience.','暫時未有回覆，分享你的經驗吧。'):t('No questions yet. Start the conversation.','暫時未有問題，開始交流吧。')}</p>}
   {cursor&&<button className="secondary full" disabled={loading} onClick={()=>void load(thread,cursor)}>{t('Load more','載入更多')}</button>}
  </>}
  {error&&<p role="alert">{error}</p>}
  {report&&<form className="qna-compose" onSubmit={async e=>{e.preventDefault();setBusy(true);try{await api({action:'report',id:report,reason});setReport(null);setNotice(t('Report submitted.','已提交舉報。'));}catch(e){setError(message(e));}finally{setBusy(false);}}}>
   <label>{t('Report reason','舉報原因')}<select value={reason} onChange={e=>setReason(e.target.value)}><option value="privacy">{t('Personal details','個人資料')}</option><option value="harmful">{t('Harmful content','有害內容')}</option><option value="spam">{t('Spam','垃圾內容')}</option><option value="other">{t('Other','其他')}</option></select></label>
   <button className="primary" disabled={busy}>{t('Submit report','提交舉報')}</button><button type="button" className="secondary" onClick={()=>setReport(null)}>{t('Cancel','取消')}</button>
  </form>}
  <small className="qna-caption">{t('Parent experiences, not professional advice.','家長經驗分享，並非專業意見。')}</small>
 </section>;
}
