import {
  ArrowUpRight,
  BookOpen,
  ChevronRight,
  Compass,
  FileText,
  Pencil,
  Plus,
  UserRound,
} from "lucide-react";
import { type AppData, type Observation } from "../domain";
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
  const reviewed = Object.keys(data.answers).length;
  const recent = [...data.records]
    .sort((a, b) => b.date.localeCompare(a.date))
    .slice(0, 3);
  return (
    <div className="home-screen">
      <h1 className="dashboard-greeting">{t("Home", "首頁")}</h1>
      <section
        className="dashboard-profile home-profile"
        aria-label={t("Child profile", "孩子檔案")}
      >
        <span className="home-child-avatar">
          {p?.nickname?.slice(0, 1).toUpperCase() || <UserRound size={22} />}
        </span>
        <div className="home-child-details">
          <h2>{p?.nickname || t("Your child", "你的孩子")}</h2>
          {p && (
            <span>
              {Math.floor(p.ageMonths / 12)} {t("years", "歲")}{" "}
              {p.ageMonths % 12} {t("months", "個月")}
            </span>
          )}
        </div>
        <button className="home-edit" onClick={onProfile}>
          <Pencil size={14} />
          {t("Edit", "編輯")}
        </button>
      </section>
      <button className="primary full home-capture" onClick={onAdd}>
        <Plus size={21} />
        {t("Add an observation", "新增觀察")}
      </button>
      <div className="home-shortcuts">
        <button onClick={onJourney}>
          <span className="home-shortcut-icon">
            <Compass size={24} />
          </span>
          <ArrowUpRight size={17} />
          <strong>{t("Your next step", "下一步")}</strong>
        </button>
        <button onClick={onReport}>
          <span className="home-shortcut-icon">
            <FileText size={24} />
          </span>
          <ArrowUpRight size={17} />
          <strong>{t("Reports", "報告")}</strong>
        </button>
      </div>
      <button className="home-questionnaire" onClick={onQuestionnaire}>
        <BookOpen size={20} />
        <span>{t("Questionnaire", "情況問卷")}</span>
        <span className="home-question-count">{reviewed}/30</span>
        <ChevronRight size={17} />
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
                  {new Date(r.date).toLocaleString(zh ? "zh-HK" : "en-HK", {
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
          <span>{t("No records yet", "暫無記錄")}</span>
        </div>
      )}
    </div>
  );
}
