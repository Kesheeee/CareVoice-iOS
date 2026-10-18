import { translator, languageLocale } from "../i18n";
import { QUESTION_COUNT } from "../domain";
import {
  ArrowUpRight,
  BookOpen,
  ChevronRight,
  Compass,
  FileText,
  Pencil,
  UserRound,
} from "lucide-react";
import { type AppData, type Observation } from "../domain";
export function Dashboard({
  data,
  onProfile,
  onCommunity,
  onQuestionnaire,
  onJourney,
  onRecords,
  onReport,
  onAdd,
  onEdit,
}: {
  data: AppData;
  onProfile: () => void;
  onCommunity: () => void;
  onQuestionnaire: () => void;
  onJourney: () => void;
  onRecords: () => void;
  onReport: () => void;
  onAdd: () => void;
  onEdit: (r: Observation) => void;
}) {
  const t = translator(data.language),
    p = data.profile;
  const reviewed = Object.keys(data.answers).length;
  const recent = [...data.records]
    .sort((a, b) => b.date.localeCompare(a.date))
    .slice(0, 3);
  return (
    <div className="home-screen">
      <div className="care-home-header"><h1>{t("Hello", "你好")}</h1><button onClick={onProfile} aria-label={t("Settings", "設定")}><UserRound size={25}/></button></div>
      <p className="care-home-prompt">{p?.nickname ? t(`How is ${p.nickname} doing today?`, `${p.nickname} 今天過得怎樣？`) : t("How is your child doing today?", "小朋友今天過得怎樣？")}</p>
      <div className="care-home-circles">
        {[
          ["📅", t("Tracker", "追蹤"), onRecords],
          ["📝", t("Questions", "問卷"), onQuestionnaire],
          ["🧭", t("Support", "支援"), onJourney],
          ["📋", t("Reports", "報告"), onReport],
          ["💬", t("Community", "社區"), onCommunity],
        ].map(([emoji,label,action])=><button key={String(label)} onClick={action as ()=>void}><span aria-hidden="true">{emoji as string}</span><small>{label as string}</small></button>)}
      </div>
      <section className="care-home-start">
        <img className="care-home-art" src="/media/carevoice-home.png" alt="" aria-hidden="true" />
        <h2>{t("Start here", "由這裡開始")} <span aria-hidden="true">💛</span></h2>
        <p>{t("A little support for your everyday care.", "為日常照顧添一點支援。")}</p>
        <button className="care-home-step" onClick={onCommunity}><span aria-hidden="true">💬</span>{t("Explore questions from parents", "看看家長常見問題")}</button>
        <button className="care-home-step" onClick={onAdd}><span aria-hidden="true">✍️</span>{t("Capture a moment from today", "記下今天的一刻")}</button>
        <button className="care-home-step" onClick={onJourney}><span aria-hidden="true">🧭</span>{t("Find your next step", "尋找下一步")}</button>
        <button className="care-home-start-button" onClick={onAdd}>{t("Add a record", "新增記錄")}</button>
      </section>
      <button className="care-home-checkin" onClick={onRecords}><span aria-hidden="true">🌱</span><div><strong>{data.records.length ? t("Your care, one day at a time", "每天一點，記下照顧點滴") : t("Start your care calendar", "開始你的照顧日曆")}</strong><p>{t("Keep everyday moments together in Tracker.", "在追蹤頁整理每天的點滴。")}</p></div><ChevronRight size={20}/></button>
      <button className="home-questionnaire" onClick={onQuestionnaire}>
        <BookOpen size={20}/><span>{t("Observation questions", "觀察問卷")}</span><span className="home-question-count">{reviewed}/{QUESTION_COUNT}</span><ChevronRight size={17}/>
      </button>
      <div className="home-recent-head">
        <h2>{t("Recent records", "最近記錄")}</h2>
        <button onClick={onRecords}>
          {t("View all", "查看全部")}
          <ChevronRight size={15} />
        </button>
      </div>
      {recent.length ? (
        <div className="home-recent-list">
          {recent.map((r) => (
            <button key={r.id} onClick={() => onEdit({ ...r })}>
              <span className="home-record-symbol">
                <FileText size={18} />
              </span>
              <span className="home-record-details">
                <strong>{r.text}</strong>
                <time>
                  {new Date(r.date).toLocaleString(languageLocale(data.language), {
                    month: "short",
                    day: "numeric",
                    hour: "2-digit",
                    minute: "2-digit",
                    hour12: false,
                  })}
                </time>
              </span>
              <ChevronRight size={16} />
            </button>
          ))}
        </div>
      ) : (
        <div className="home-empty">
          <BookOpen size={24} />
          <span>{t("No records yet", "仲未有記錄")}</span>
        </div>
      )}
      <section className="home-feedback" aria-labelledby="home-feedback-title">
        <h2 id="home-feedback-title">{t("Share your thoughts", "分享你的想法")}</h2>
        <p>{t("Have an idea or feedback?", "有新點子或意見？")}<br />{t("Help us improve CareVoice.", "一起讓 CareVoice 做得更好。")}</p>
        <button type="button" disabled>{t("Give feedback", "提供意見")}</button>
      </section>
    </div>
  );
}
