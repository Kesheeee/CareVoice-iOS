import {useEffect, useRef, useState} from 'react';
import {ArrowLeft, Send, Share2, MessageCircle} from 'lucide-react';
import {translator} from '../i18n';
import type {Language} from '../domain';

export function CareChat({open, language, onClose, onPreview}: {open:boolean;language:Language;onClose:()=>void;onPreview:(text:string)=>void}) {
  const t=translator(language);
  const dialog=useRef<HTMLDialogElement>(null);
  const bottom=useRef<HTMLDivElement>(null);
  const [messages,setMessages]=useState<string[]>([]);
  const [input,setInput]=useState('');
  const [sharing,setSharing]=useState(false);
  const [post,setPost]=useState('');
  const [consent,setConsent]=useState(false);
  useEffect(()=>{if(open)dialog.current?.showModal();else dialog.current?.close();},[open]);
  useEffect(()=>{bottom.current?.scrollIntoView({block:'nearest'});},[messages]);
  const prompts=[t('Appointments','預約'),t('A difficult day','遇到困難'),t('Find support','尋找支援')];
  return <dialog ref={dialog} className="care-chat-dialog" aria-label={t("Ask CareVoice", "詢問 CareVoice")} onCancel={onClose}>
    <header className="care-chat-header"><button aria-label={t('Back','返回')} onClick={()=>sharing?setSharing(false):onClose()}><ArrowLeft/></button><div><h2>{sharing?t('Review your question','檢查你的問題'):'CareVoice'}</h2><span>{t('AI preview','AI 預覽')}</span></div><MessageCircle aria-hidden="true"/></header>
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
        {!messages.length && <div className="care-chat-intro"><span aria-hidden="true">💬</span><h3>{t('What’s on your mind?','今天想聊聊甚麼？')}</h3></div>}
        <details className="care-chat-preview-info"><summary>{t('Preview only · AI not connected','僅供預覽 · AI 未連接')}</summary><p>{t('Nothing is sent. Messages clear when you leave Community or refresh.','不會傳送資料。離開社區或重新整理後，訊息會清除。')}</p></details>
        {!messages.length && <div className="care-chat-prompts">{prompts.map(prompt=><button key={prompt} onClick={()=>setInput(prompt)}>{prompt}</button>)}</div>}
        {messages.map((message,i)=><div className="care-chat-turn" key={i}><div className="care-chat-user"><small>{t('You','你')}</small><p>{message}</p></div><div className="care-chat-placeholder"><small>{t('AI reply placeholder','AI 回覆預留位置')}</small><p>{t('An AI response will appear here once connected.','連接後，AI 回覆會顯示在這裡。')}</p></div></div>)}
        <div ref={bottom}/>
      </div>
      <footer className="care-chat-footer">
        {messages.length>0 && <button className="care-chat-share" onClick={()=>{setPost(messages[0]);setConsent(false);setSharing(true);}}><Share2 size={17}/>{t('Share a question with parents','與其他家長分享問題')}</button>}
        <form onSubmit={e=>{e.preventDefault();if(!input.trim())return;setMessages([...messages,input.trim()]);setInput('');}}><textarea aria-label={t('Message','訊息')} placeholder={t('Type your question…','輸入你的問題…')} rows={1} maxLength={2000} value={input} onChange={e=>setInput(e.target.value)}/><button aria-label={t('Send message','傳送訊息')} disabled={!input.trim()}><Send size={22}/></button></form>
      </footer>
    </>}
  </dialog>;
}
