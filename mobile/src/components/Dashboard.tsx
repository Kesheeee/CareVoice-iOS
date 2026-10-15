import {
  ArrowRight,
  AudioLines,
  BookOpen,
  ChevronRight,
  Compass,
  FileText,
  Info,
  Pencil,
  Plus,
  UserRound,
} from "lucide-react";
import {
  type AppData,
  type Language,
  type Observation,
  stages,
} from "../domain";
export function Dashboard({
  data,
  onProfile,
  onQuestionnaire,
  onJourney,
  onRecords,
  onReport,
  onAdd,
  onEdit,
}: {
  data: AppData;
  onProfile: () => void;
  onQuestionnaire: () => void;
  onJourney: () => void;
  onRecords: () => void;
  onReport: () => void;
  onAdd: () => void;
  onEdit: (r: Observation) => void;
}) {
  const zh = data.language === "zh",
    t = (en: string, tc: string) => (zh ? tc : en),
    p = data.profile;
  const now = new Date(),
    monthCount = data.records.filter((r) => {
      const d = new Date(r.date);
      return (
        d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth()
      );
    }).length;
  const reviewed = Object.keys(data.answers).length,
    percent = Math.round((reviewed / 30) * 100);
  return (
    <>
      <h1 className="dashboard-greeting">
        {p?.nickname
          ? t(`Hello, ${p.nickname}’s family`, `你好，${p.nickname}的家人`)
          : t("Hello", "你好")}
      </h1>
      <section className="dashboard-profile">
        <div className="profile-row">
          <span className="blue-child-avatar">
            {p?.nickname?.slice(0, 1).toUpperCase() || <UserRound />}
          </span>
          <div className="profile-identity">
            <h2>{p?.nickname || t("Your child", "你的孩子")}</h2>
            {p && (
              <span>
                {Math.floor(p.ageMonths / 12)} {t("years", "歲")}{" "}
                {p.ageMonths % 12} {t("months", "個月")}
              </span>
            )}
          </div>
          <button className="edit-profile" onClick={onProfile}>
            <Pencil size={14} />
            {t("Edit", "編輯")}
          </button>
        </div>
        <div className="dashboard-progress">
          <button onClick={onQuestionnaire}>
            {t("Questionnaire progress", "問卷進度")}
            <ChevronRight size={14} />
          </button>
          <span>
            {reviewed}/30 · {percent}%
          </span>
        </div>
        <div className="progress-track">
          <i style={{ width: `${percent}%` }} />
        </div>
      </section>
      <div className="dashboard-stats">
        <div>
          <strong>{monthCount}</strong>
          <span>{t("Records this month", "本月記錄")}</span>
        </div>
        <div>
          <strong>{percent}%</strong>
          <span>
            {t("Questionnaire progress", "問卷進度")}
            <details className="progress-info">
              <summary
                aria-label={t("About questionnaire progress", "關於問卷進度")}
              >
                <Info size={14} />
              </summary>
              <p>
                {t(
                  "Completion only, not a clinical score. Your stage is selected by you.",
                  "只代表完成進度，並非臨床分數。階段由你自行選擇。",
                )}
              </p>
            </details>
          </span>
        </div>
      </div>
      <div className="section-head">
        <h2>{t("Features", "功能模組")}</h2>
      </div>
      <div className="module-list">
        <button onClick={onJourney}>
          <span className="module-symbol">
            <Compass size={22} />
          </span>
          <strong>{t("Waiting-period navigator", "等待期導航")}</strong>
          <ChevronRight size={17} />
        </button>
        <button onClick={onRecords}>
          <span className="module-symbol">
            <AudioLines size={22} />
          </span>
          <strong>{t("Behavior log", "行為記錄")}</strong>
          <ChevronRight size={17} />
        </button>
        <button onClick={onReport}>
          <span className="module-symbol">
            <FileText size={22} />
          </span>
          <strong>{t("Reports", "報告")}</strong>
          <ChevronRight size={17} />
        </button>
      </div>
      <div className="section-head">
        <h2>{t("Recent activity", "最近活動")}</h2>
        <button className="text-button" onClick={onRecords}>
          {t("View all", "查看全部")}
          <ArrowRight size={14} />
        </button>
      </div>
      {data.records.length ? (
        <div className="activity-timeline">
          {[...data.records]
            .sort((a, b) => b.date.localeCompare(a.date))
            .slice(0, 3)
            .map((r) => (
              <button key={r.id} onClick={() => onEdit({ ...r })}>
                <time>
                  {new Date(r.date).toLocaleString(zh ? "zh-HK" : "en-HK", {
                    month: "short",
                    day: "numeric",
                    hour: "2-digit",
                    minute: "2-digit",
                  })}
                </time>
                <span>{r.text}</span>
              </button>
            ))}
        </div>
      ) : (
        <div className="empty-activity">
          <BookOpen size={22} />
          <span>{t("No observations yet", "暫無觀察記錄")}</span>
        </div>
      )}
      <button className="primary full add-home" onClick={onAdd}>
        <Plus size={18} />
        {t("Add an observation", "新增觀察")}
      </button>
    </>
  );
}
