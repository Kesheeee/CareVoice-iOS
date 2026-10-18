import { CareChat } from "./CareChat";
import { useState } from "react";
import { MessageCircle, Bookmark, X, Send, Heart } from "lucide-react";
import { translator } from "../i18n";
import { ArrowUpRight, ShieldCheck, ChevronDown, CalendarDays, Stethoscope, Route, Building2, Baby, School } from "lucide-react";
import type { Language } from "../domain";
const resources = [
  [
    "Child Assessment Service (CAS)",
    "兒童體能智力測驗服務（CAS）",
    "https://www.dhcas.gov.hk/en/faq.html",
    "https://www.dhcas.gov.hk/tc/faq.html",
    "DH",
  ],
  [
    "Assessment registration & appointments",
    "評估登記及預約",
    "https://www.dhcas.gov.hk/en/registration_appointment.html",
    "https://www.dhcas.gov.hk/tc/registration_appointment.html",
    "DH",
  ],
  [
    "Follow-up & service referrals",
    "跟進與服務轉介",
    "https://www.dhcas.gov.hk/en/management_referral.html",
    "https://www.dhcas.gov.hk/tc/management_referral.html",
    "DH",
  ],
  [
    "Central referral system (CRSRS)",
    "康復服務中央轉介系統（CRSRS）",
    "https://www.swd.gov.hk/en/pubsvc/rehab/cat_crsrehab/centralref/",
    "https://www.swd.gov.hk/tc/pubsvc/rehab/cat_crsrehab/centralref/",
    "SWD",
  ],
];
export function Community({ language }: { language: Language }) {
  const [compose, setCompose] = useState(false);
  const [question, setQuestion] = useState("");
  const [drafts, setDrafts] = useState<string[]>([]);
  const [saved, setSaved] = useState<number[]>([]);
  const [view, setView] = useState<"questions" | "drafts" | "saved">("questions");
  const [expanded, setExpanded] = useState<number | null>(null);
  const zh = language !== "en",
    t = translator(language);
  const questions = [
    [t("Getting started", "開始了解"), t("Where can I discuss my concerns?", "有疑問可以找誰？"), t("You can bring your observations to your family doctor or Maternal & Child Health Centre to discuss next steps.", "你可以帶同日常觀察，與家庭醫生或母嬰健康院討論下一步。")],
    [t("Daily care", "日常照顧"), t("What can I record each day?", "每天可以記錄甚麼？"), t("Record what you noticed, where it happened, what came before and what seemed to help. Your Tracker keeps these moments together.", "記下你留意到的事情、地點、之前發生的事，以及似乎有幫助的方法。追蹤頁會整理這些點滴。")],
    [t("Appointments", "預約準備"), t("What can I prepare while waiting?", "等候期間可以準備甚麼？"), t("Keep observations and questions together, then prepare a report for your appointment. Confirm service arrangements with your referring professional.", "整理日常觀察和問題，並準備預約時使用的報告。請向轉介專業人士確認服務安排。")],
  ];
  const link = (en: string, tc: string, url: string, source: string, Icon = ShieldCheck) => (
    <a
      className="community-link"
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      key={en}
      aria-label={`${t(en, tc)} · ${source}`}
    >
      <span className="community-resource-icon" aria-hidden="true"><Icon size={20} strokeWidth={1.7} /></span>
      <strong>{t(en, tc)}</strong>
      <ArrowUpRight size={18} />
    </a>
  );
  return (
    <div className="community-screen">
      <div className="page-heading">
        <h1>{t("Community", "社區")}</h1>
      </div>
      <section className="ask-hero">
        <img className="ask-hero-photo" src="/media/carevoice-community.png" alt="" aria-hidden="true" />
        <div className="ask-hero-copy">
        <h2>{t("Ask CareVoice", "問問 CareVoice")}</h2>
        <p>{t("What’s on your mind today?", "今天有甚麼想聊聊？")}</p>
        <button className="primary" onClick={() => setCompose(!compose)}><MessageCircle size={18}/>{t("Ask a question", "提出問題")}</button>
        </div>
      </section>
      <CareChat open={compose} language={language} onClose={() => setCompose(false)} onPreview={text => {setDrafts([...drafts,text]);setView("drafts");}} />
      <section className="ask-browser">
        <div className="ask-section-heading"><h2>{view === "drafts" ? t("My post previews", "我的貼文預覽") : view === "saved" ? t("Saved questions", "已收藏問題") : t("Questions you may have", "你可能想問")}</h2>{view !== "questions" && <button onClick={() => setView("questions")}>{t("View all", "查看全部")}</button>}</div>
        {view === "drafts" ? (drafts.length ? drafts.map((draft,i)=><article className="ask-question-card" key={i}><span className="ask-topic">{t("Private preview · Not published", "私人預覽 · 未發佈")}</span><p>{draft}</p><button onClick={()=>{setDrafts(drafts.filter((_,j)=>i!==j));}}>{t("Remove preview", "移除預覽")}</button></article>) : <p>{t("Your question drafts will appear here.", "你的問題草稿會顯示於此。")}</p>) : <>
        {view === "saved" && saved.length === 0 && <p>{t("Tap the bookmark on a question to keep it here for this visit.", "點按問題的書籤，在這次瀏覽期間收藏。")}</p>}
        {questions.map(([topic,title,answer],i) => view === "saved" && !saved.includes(i) ? null : <article className="ask-question-card" key={title}>
          <div className="ask-section-heading"><span className="ask-topic">{topic}</span><button aria-label={t("Save question", "收藏問題")} aria-pressed={saved.includes(i)} onClick={()=>setSaved(saved.includes(i)?saved.filter(n=>n!==i):[...saved,i])}><Bookmark size={22} fill={saved.includes(i)?"currentColor":"none"}/></button></div>
          <button className="ask-question-title" aria-expanded={expanded===i} onClick={()=>setExpanded(expanded===i?null:i)}>{title}<ChevronDown size={20}/></button>
          {expanded===i && <p>{answer}</p>}
        </article>)}
        </>}
      </section>
      <h2 id="community-resources" className="community-section">
        {t("Official resources & support", "官方資源與支援")}
      </h2>
      <div className="community-group">
        {resources.map(([en, tc, url, tcUrl, dept], index) =>
          link(
            en,
            tc,
            zh ? tcUrl : url,
            dept === "DH"
              ? t("Department of Health", "衛生署")
              : t("Social Welfare Department", "社會福利署"),
            [Stethoscope, CalendarDays, Route, Building2][index],
          ),
        )}
      </div>
      <h2 className="community-section">
        {t("Support for parents", "家長資源")}
      </h2>
      <div className="community-group">
        {link(
          "Maternal & Child Health Centres",
          "母嬰健康院",
          "https://www.dh.gov.hk/english/main/main_fhs/main_fhs.html",
          t("Department of Health", "衛生署"),
          Baby,
        )}
        {link(
          "On-site pre-school support",
          "到校學前支援",
          "https://www.swd.gov.hk/oprs/index_en.htm",
          t("Social Welfare Department", "社會福利署"),
          School,
        )}
      </div>
      <h2 className="community-section">{t("Common questions", "常見問題")}</h2>
      <div className="community-questions">
        <details>
          <summary role="button">
            {t("Where can I discuss my concerns?", "有疑問可以搵邊個？")}
            <ChevronDown size={17} aria-hidden="true" />
          </summary>
          <p>
            {t(
              "Start with your family doctor or Maternal & Child Health Centre. They can discuss your observations and whether a referral is needed.",
              "可以先同家庭醫生或母嬰健康院傾吓你嘅觀察，同埋需唔需要轉介。",
            )}
          </p>
          <a
            href={
              zh
                ? "https://www.dhcas.gov.hk/tc/faq.html"
                : "https://www.dhcas.gov.hk/en/faq.html"
            }
            target="_blank"
            rel="noopener noreferrer"
          >
            {t("CAS official guidance", "CAS 官方指引")}
            <ArrowUpRight size={13} />
          </a>
        </details>
        <details>
          <summary role="button">
            {t(
              "Does this questionnaire assess my child?",
              "呢份問卷會評估小朋友嗎？",
            )}
            <ChevronDown size={17} aria-hidden="true" />
          </summary>
          <p>
            {t(
              "No. It records your observations without scores, diagnosis or a suggested clinical level. Only you choose your journey stage.",
              "唔會。問卷只記錄你嘅觀察，唔會評分、診斷或建議臨床程度。你而家嘅階段只會由你揀。",
            )}
          </p>
        </details>
        <details>
          <summary role="button">
            {t("What can I prepare while waiting?", "等候期間可以準備啲咩？")}
            <ChevronDown size={17} aria-hidden="true" />
          </summary>
          <p>
            {t(
              "Keep your observations and questions together. Use your personal checklist and bring a report to your next professional appointment. Confirm service arrangements with your referring professional.",
              "整理日常觀察同問題，用個人清單記低，見面時帶埋記錄報告。服務安排記得同轉介專業人士確認。",
            )}
          </p>
        </details>
      </div>
      <details className="community-about">
        <summary role="button"><ShieldCheck size={15} aria-hidden="true" />{t("About these resources", "關於呢啲資源")}<ChevronDown size={15} aria-hidden="true" /></summary>
        <p className="fine-print">
        {t(
          "Official links reviewed 15 October 2026. Service providers confirm eligibility and arrangements. External links open in your browser.",
          "官方連結已喺 2026 年 10 月 15 日核對。服務資格同安排由機構確認，外部連結會喺瀏覽器開啟。",
        )}
        </p>
        <p className="fine-print">{t("Sources: Department of Health and Social Welfare Department.", "資料來源：衛生署及社會福利署。")}</p>
      </details>
    </div>
  );
}
