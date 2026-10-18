import {useEffect, useRef, useState} from 'react';
import {ArrowLeft, Send, Share2, MessageCircle, ExternalLink} from 'lucide-react';
import {translator} from '../i18n';
import type {Language} from '../domain';
import {ask, isAskConfigured, type AskResponse, type HistoryMessage} from '../platform/ask';

type Turn = { user: string; response: AskResponse | null; loading: boolean; error: boolean | string };

export function CareChat({open, language, onClose, onPreview}: {open:boolean;language:Language;onClose:()=>void;onPreview:(text:string)=>void}) {
  const t=translator(language);
  const dialog=useRef<HTMLDialogElement>(null);
  const bottom=useRef<HTMLDivElement>(null);
  const [turns,setTurns]=useState<Turn[]>([]);
  const [input,setInput]=useState('');
  const [busy,setBusy]=useState(false);
  const [sharing,setSharing]=useState(false);
  const [post,setPost]=useState('');
  const [consent,setConsent]=useState(false);
  useEffect(()=>{if(open)dialog.current?.showModal();else dialog.current?.close();},[open]);
  useEffect(()=>{bottom.current?.scrollIntoView({block:'nearest'});},[turns]);
  const prompts=[t('Appointments','預約'),t('A difficult day','遇到困難'),t('Find support','尋找支援')];

  const submit=async(text:string)=>{
    const message=text.trim();
    if(!message||busy||!isAskConfigured)return;
    const history:HistoryMessage[]=[];
    for(const turn of turns){
      history.push({role:'user',content:turn.user});
      if(!turn.loading&&turn.response?.reply)history.push({role:'assistant',content:turn.response.reply});
    }
    setInput('');setBusy(true);
    setTurns(prev=>[...prev,{user:message,response:null,loading:true,error:false}]);
    try{
      const response=await ask(message,language,history);
      setTurns(prev=>prev.map((turn,i)=>i===prev.length-1?{...turn,response,loading:false}:turn));
    }catch(error){
      setTurns(prev=>prev.map((turn,i)=>i===prev.length-1?{...turn,response:{suggestions:[]},loading:false,error:error instanceof Error?error.message:true}:turn));
    }finally{
      setBusy(false);
    }
  };

  return <dialog ref={dialog} className="care-chat-dialog" aria-label={t("Ask CareVoice", "詢問 CareVoice")} onCancel={onClose}>
    <header className="care-chat-header"><button aria-label={t('Back','返回')} onClick={()=>sharing?setSharing(false):onClose()}><ArrowLeft/></button><div><h2>{sharing?t('Review your question','檢查你的問題'):'CareVoice'}</h2><span>{t('AI assistance','AI 助手')}</span></div><MessageCircle aria-hidden="true"/></header>
    {sharing ? <div className="care-chat-review">
      <h3>{t('What would you like other parents to see?','你想讓其他家長看到甚麼？')}</h3>
      <p>{t('Only the text below goes into your post preview. Your chat and child’s records are not included.','貼文預覽只包括以下文字，不包含對話或小朋友的記錄。')}</p>
      <label htmlFor="care-share-text">{t('Your community question','你的社區問題')}</label>
      <textarea id="care-share-text" value={post} onChange={e=>{setPost(e.target.value);setConsent(false);}} maxLength={2000} rows={7}/>
      <label className="care-chat-consent"><input type="checkbox" checked={consent} onChange={e=>setConsent(e.target.checked)}/>{t('I have removed names and identifying details.','我已移除姓名及可識別身份的資料。')}</label>
      <p className="care-chat-notice">{t('Community publishing and matching are not connected yet. This creates a private preview on this page, not a public post.','社區發佈及配對尚未連接。這只會在本頁建立私人預覽，不會公開發佈。')}</p>
      <button className="primary" disabled={!post.trim()||!consent} onClick={()=>{onPreview(post.trim());setSharing(false);onClose();}}>{t('Preview community post','預覽社區貼文')}</button>
    </div> : <>
      <div className="care-chat-messages" role="log" aria-label={t('Conversation','對話')} aria-live="polite">
        {!turns.length && <div className="care-chat-intro"><span aria-hidden="true">💬</span><h3>{t('What’s on your mind?','今天想聊聊甚麼？')}</h3></div>}
        {!isAskConfigured && <p role="status">{t('AI chat is not connected yet. You can still ask parents in Community.','AI 對話尚未連接，你仍可在社區向其他家長提問。')}</p>}
        {!turns.length && <div className="care-chat-prompts">{prompts.map(prompt=><button key={prompt} disabled={!isAskConfigured||busy} onClick={()=>submit(prompt)}>{prompt}</button>)}</div>}
        {turns.map((turn,i)=><div className="care-chat-turn" key={i}>
          <div className="care-chat-user"><small>{t('You','你')}</small><p>{turn.user}</p></div>
          {turn.loading ? <div className="care-chat-reply"><p>{t('Thinking…','思考中……')}</p></div>
          : turn.error ? <div className="care-chat-reply care-chat-error"><p>{turn.error==='ai_not_configured'?t('AI setup is not finished yet. Please try again later.','AI 設定尚未完成，請稍後再試。'):t('Could not reach CareVoice. Please try again.','暫時未能連接 CareVoice，請再試。')}</p></div>
          : turn.response?.safety ? <div className="care-chat-reply care-chat-safety">
              <p className="care-chat-signal">{turn.response.safety.signal}</p>
              <p className="care-chat-route">{turn.response.safety.route}</p>
              {turn.response.safety.contact && <p className="care-chat-contact">{turn.response.safety.contact}</p>}
            </div>
          : turn.response?.suggestions?.length ? <div className="care-chat-reply">
              {turn.response.reply && <p>{turn.response.reply}</p>}
              {turn.response.suggestions.map((s,j)=><article className="care-chat-suggestion" key={j}>
                <p className="care-chat-why">{s.why}</p>
                <p className="care-chat-title">{s.title}</p>
                {s.plain && <p className="care-chat-plain">{s.plain}</p>}
                {s.url && <a className="care-chat-source" href={s.url} target="_blank" rel="noopener noreferrer">{t('Official source','官方來源')}<ExternalLink size={12} aria-hidden="true"/></a>}
              </article>)}
              <p className="care-chat-ai-note">{t('AI suggestion. Confirm with a professional before acting.','此為 AI 建議，行動前請與專業人士確認。')}</p>
            </div>
          : <div className="care-chat-reply"><p>{turn.response?.reply || t('I could not find matching official information. You can call the Social Welfare Department hotline 2343 2255 (24 hours).','未能找到相關官方資料。你可以致電社會福利署熱線 2343 2255（24 小時）。')}</p></div>}
        </div>)}
        <div ref={bottom}/>
      </div>
      <footer className="care-chat-footer">
        {turns.length>0 && <button className="care-chat-share" onClick={()=>{setPost(turns[0]?.user||'');setConsent(false);setSharing(true);}}><Share2 size={17}/>{t('Share a question with parents','與其他家長分享問題')}</button>}
        <form onSubmit={e=>{e.preventDefault();submit(input);}}><textarea aria-label={t('Message','訊息')} placeholder={t('Describe what happened, what came before, and what helped…','描述發生咗咩事、之前嘅情況，同埋有咩方法幫到手……')} rows={2} maxLength={2000} value={input} disabled={busy||!isAskConfigured} onChange={e=>setInput(e.target.value)}/><button aria-label={t('Send message','傳送訊息')} disabled={!input.trim()||busy||!isAskConfigured}><Send size={22}/></button></form>
      </footer>
    </>}
  </dialog>;
}
