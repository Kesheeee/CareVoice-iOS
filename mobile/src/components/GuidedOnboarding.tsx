import { translator, languageLocale } from "../i18n";
import { useRef, useState, type FormEvent } from "react";
import { ArrowLeft, Baby, Check, ClipboardCheck, Clock3, Compass, FileText, Heart, MessageCircle, Search, UsersRound } from "lucide-react";
import { onboardingStages, supportGoals, type Language, type Profile } from "../domain";
import "../onboarding.css";

const stageIcons = [Search, MessageCircle, Clock3, FileText, ClipboardCheck, Heart, UsersRound];
const choiceLabels = [
  ["Noticing differences", "留意到不同"], ["Seeking a referral", "尋求專業轉介"],
  ["Awaiting assessment", "等候評估"], ["Assessment completed", "已完成評估"],
  ["Registered in the queue", "已登記中央輪候"], ["Support while waiting", "輪候期間支援"],
  ["Allocated a service", "已獲編配服務"],
];
const questionIcons = [Baby, Baby, Compass, Heart, MessageCircle];

export function GuidedOnboarding({ profile, onChange, language, onClose, onSave, locked }: {
  profile: Profile; onChange: (value: Profile) => void; language: Language;
  onClose: () => void; onSave: () => void; locked: boolean;
}) {
  const [step, setStep] = useState(0);
  const [chosen, setChosen] = useState(false);
  const [birthday, setBirthday] = useState((profile.birthDate ?? "--").split("-"));
  const content = useRef<HTMLDivElement>(null);
  const title = useRef<HTMLHeadingElement>(null);
  const t = translator(language);
  const headings = [t("What should we call your child?", "點稱呼你嘅小朋友？"), t("When is your child’s birthday?", "小朋友嘅生日係幾時？"), t("Where are you now?", "你而家去到邊個階段？"), t("What would you like help with?", "你想獲得邊方面嘅幫助？"), t("Anything you’d like us to know?", "仲有冇想話畀我哋知嘅事？")];
  const today = new Date();
  const dateString = (date: Date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
  const earliest = new Date(today.getFullYear() - 7, today.getMonth(), today.getDate() + 1);
  const [year, month, day] = birthday;
  const selectedDate = new Date(Number(year), Number(month) - 1, Number(day));
  const birthValue = `${year}-${month}-${day}`;
  const birthdayComplete = Boolean(year && month && day);
  const birthdayValid = birthdayComplete && selectedDate.getFullYear() === Number(year) && selectedDate.getMonth() === Number(month) - 1 && selectedDate.getDate() === Number(day) && birthValue >= dateString(earliest) && birthValue <= dateString(today);
  function changeBirthday(index: number, value: string) {
    const parts = [...birthday]; parts[index] = value; setBirthday(parts);
    const [y, m, d] = parts.map(Number);
    const ageMonths = (today.getFullYear() - y) * 12 + today.getMonth() - (m - 1) - (today.getDate() < d ? 1 : 0);
    if (parts.every(Boolean)) onChange({ ...profile, birthDate: parts.join("-"), ageMonths });
  }
  const heading = headings[step];
  const Icon = questionIcons[step];
  function move(next: number) {
    setStep(next);
    requestAnimationFrame(() => { content.current?.scrollTo({ top: 0 }); title.current?.focus(); });
  }
  function submit(event: FormEvent) {
    event.preventDefault();
    if (locked || (step === 2 && !chosen) || (step === 1 && !birthdayValid)) return;
    if (step < 4) move(step + 1); else onSave();
  }
  function skip() {
    onChange({ ...profile, nickname: "" });
    move(1);
  }
  return <form className={`guided-onboarding survey-onboarding onboarding-step-${step}`} onSubmit={submit}>
    <header className="onboarding-top">
      <button type="button" className="onboarding-back" aria-label={t(step ? "Back" : "Close onboarding", step ? "返回" : "關閉新手設定")} onClick={() => step ? move(step - 1) : onClose()}><ArrowLeft size={21} /></button>
      <progress className="survey-progress-bar" aria-label={t("Setup progress", "設定進度")} value={step + 1} max={5} />
      <span className="onboarding-count">{step + 1} / 5</span>
    </header>
    <div className="onboarding-content" ref={content}>
      <div className="survey-question"><h1 id="profile-title" ref={title} tabIndex={-1}>{heading}</h1></div>
      {step === 0 && <div className="survey-answer stage-tone-0"><label htmlFor="survey-name">{t("Nickname (optional)", "暱稱（選填）")}</label><input id="survey-name" autoComplete="nickname" maxLength={40} placeholder={t("Your child’s nickname", "小朋友嘅暱稱")} value={profile.nickname} onChange={e => onChange({ ...profile, nickname: e.target.value })} /></div>}
      {step === 1 && <section className="birthday-panel">
        <p className="survey-hint">{t("Choose their date of birth. We’ll work out their age for you.", "揀小朋友嘅出生日期，我哋會自動計算年齡。")}</p>
        <fieldset className="birthday-fields"><legend className="sr-only">{t("Date of birth", "出生日期")}</legend>
          <label>{t("Day", "日")}<select aria-label={t("Day", "日")} required value={day} onChange={e => changeBirthday(2, e.target.value)}><option value="">—</option>{Array.from({length:31},(_,i)=>i+1).map(n=><option key={n} value={String(n).padStart(2,"0")}>{n}</option>)}</select></label>
          <label>{t("Month", "月")}<select aria-label={t("Month", "月")} required value={month} onChange={e => changeBirthday(1, e.target.value)}><option value="">—</option>{Array.from({length:12},(_,i)=>i).map(n=><option key={n} value={String(n+1).padStart(2,"0")}>{new Intl.DateTimeFormat(languageLocale(language), {month:"short"}).format(new Date(2020,n,1))}</option>)}</select></label>
          <label>{t("Year", "年")}<select aria-label={t("Year", "年")} required value={year} onChange={e => changeBirthday(0, e.target.value)}><option value="">—</option>{Array.from({length:8},(_,i)=>today.getFullYear()-i).map(n=><option key={n} value={n}>{n}</option>)}</select></label>
        </fieldset>
        <div className="birthday-summary" aria-live="polite">{birthdayValid ? <><strong>{new Intl.DateTimeFormat(languageLocale(language), {day:"numeric",month:"long",year:"numeric"}).format(selectedDate)}</strong><span>{t(`${Math.floor(profile.ageMonths / 12)} years · ${profile.ageMonths % 12} months old`, `${Math.floor(profile.ageMonths / 12)} 歲 ${profile.ageMonths % 12} 個月`)}</span></> : <span>{birthdayComplete ? t("Choose a valid birthday for a child under 7, no later than today.", "請選擇未滿七歲小朋友嘅有效生日，日期不可遲於今日。") : t("Their birthday will appear here", "揀好後，生日會顯示喺呢度")}</span>}</div>
      </section>}
      {step === 2 && <fieldset className="onboarding-stages"><legend className="sr-only">{heading}</legend>
        {onboardingStages.map((value, index) => {
          const StageIcon = stageIcons[index]; const selected = chosen && profile.stage === value;
          return <label key={value} className={`onboarding-stage stage-tone-${index % 6}${selected ? " selected" : ""}`}>
            <input type="radio" name="onboarding-stage" value={value} checked={selected} required onChange={() => { onChange({ ...profile, stage: value }); setChosen(true); }} />
            <StageIcon className="stage-choice-icon" size={23} aria-hidden="true" /><span>{t(choiceLabels[index][0], choiceLabels[index][1])}</span><span className="onboarding-selection" aria-hidden="true">{selected && <Check size={14} />}</span>
          </label>;
        })}
      </fieldset>}
      {step === 3 && <><p className="survey-hint">{t("Choose any that apply", "可選多項")}</p><fieldset className="onboarding-stages"><legend className="sr-only">{heading}</legend>
        {Object.entries(supportGoals).map(([value, label], index) => {
          const selected = (profile.supportGoals ?? []).includes(value);
          const GoalIcon = [Compass, FileText, UsersRound, Heart, Search][index];
          return <label key={value} className={`onboarding-stage stage-tone-${index}${selected ? " selected" : ""}`}><input type="checkbox" checked={selected} onChange={() => onChange({ ...profile, supportGoals: selected ? profile.supportGoals?.filter(goal => goal !== value) : [...(profile.supportGoals ?? []), value] })} /><GoalIcon className="stage-choice-icon" size={24} aria-hidden="true" /><span>{t(...label)}</span><span className="onboarding-selection" aria-hidden="true">{selected && <Check size={14} />}</span></label>;
        })}
      </fieldset></>}
      {step === 4 && <div className="survey-answer stage-tone-4"><label htmlFor="survey-notes">{t("Notes (optional)", "補充資料（選填）")}</label><textarea id="survey-notes" rows={5} maxLength={4000} placeholder={t("Anything about your child or your family’s needs…", "關於小朋友或家庭需要嘅補充…")} value={profile.concernNotes} onChange={e => onChange({ ...profile, concernNotes: e.target.value })} /></div>}
      {step !== 2 && step !== 3 && <aside className="survey-guide-hint"><span className="survey-guide-symbol" aria-hidden="true"><Icon size={30} /></span><p>{[
        t("A nickname is enough. You can leave this blank.", "用暱稱就得，亦可以留空。"),
        t("No need to count the months — we’ll do that for you.", "唔使自己數月齡，我哋幫你計。"),
        t("Choose where you are today. You can update your stage later.", "揀你而家嘅階段，之後可以再更新。"),
        t("You can choose more than one.", "可以揀多過一項。"),
        t("Share as much or as little as you like.", "想分享幾多都得，由你決定。")
      ][step]}</p></aside>}
    </div>
    <footer className="onboarding-footer">
      {step === 0 && <button type="button" className="survey-skip" disabled={locked} onClick={skip}>{t("Skip", "略過")}</button>}
      {step === 4 && !profile.concernNotes && <button type="button" className="survey-skip" disabled={locked} onClick={onSave}>{t("Skip notes", "略過補充資料")}</button>}
      <button className="primary full" type="submit" disabled={locked || (step === 2 && !chosen) || (step === 1 && !birthdayValid)}>{step >= 4 ? t("See my next steps", "睇吓下一步") : t("Continue", "繼續")}</button>
    </footer>
  </form>;
}
