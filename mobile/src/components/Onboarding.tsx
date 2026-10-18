import { translator } from "../i18n";
import {
  ArrowRight,
  AudioLines,
  BookOpen,
  Check,
  ChevronDown,
  Compass,
  FileText,
  Hand,
  Heart,
  MessageCircle,
  ShieldCheck,
  Sparkles,
  Volume2,
} from "lucide-react";
import type { Language, Profile } from "../domain";
import { stages, onboardingStages } from "../domain";
export function SetupProgress({
  language,
  questionnaire = false,
}: {
  language: Language;
  questionnaire?: boolean;
}) {
  const t = translator(language);
  return (
    <ol className="setup-progress" aria-label={t("Setup steps", "設定步驟")}>
      <li className={questionnaire ? "complete" : "current"}>
        <span>{questionnaire ? <Check size={13} /> : 1}</span>
        {t("Profile", "建立檔案")}
      </li>
      <li className={questionnaire ? "current" : ""}>
        <span>2</span>
        {t("Questionnaire", "觀察問卷")}
      </li>
    </ol>
  );
}
export function Welcome({
  language,
  onStart,
  onSignIn,
}: {
  language: Language;
  onStart: () => void;
  onSignIn: () => void;
}) {
  const zh = language !== "en",
    t = translator(language);
  return (
    <section className="welcome-screen">
      <div className="welcome-mark" aria-hidden="true">
        <Heart size={38} strokeWidth={1.6} />
      </div>
      <h1>{t("Welcome to CareVoice", "歡迎使用 CareVoice")}</h1>
      <div className="welcome-features">
        <div>
          <Compass />
          <span>{t("Find your next step", "搵下一步")}</span>
        </div>
        <div>
          <AudioLines />
          <span>{t("Keep observations", "記低日常觀察")}</span>
        </div>
        <div>
          <FileText />
          <span>{t("Prepare a report", "準備報告")}</span>
        </div>
      </div>
      <button className="primary full" onClick={onStart}>
        {t("Get started", "開始使用")}
        <ArrowRight size={18} />
      </button>
      <button className="secondary full" onClick={onSignIn}>
        {t("Sign in", "登入")}
      </button>
      <details className="welcome-about">
        <summary role="button"><ShieldCheck size={17} aria-hidden="true" />{t("No scores or diagnosis", "唔會評分或診斷")}<ChevronDown size={15} aria-hidden="true" /></summary>
        <p>{t(
          "CareVoice organises caregiver observations. It does not diagnose, score, or infer a support level. Formal assessment belongs with qualified professionals.",
          "CareVoice 整理照顧者嘅觀察，唔會診斷、評分或推斷支援程度。正式評估由合資格專業人士進行。",
        )}</p>
      </details>
    </section>
  );
}
const groups = [
  ["Social communication", "社交溝通", 10, MessageCircle],
  ["Language & gestures", "語言與手勢", 7, Volume2],
  ["Repetitive behaviours", "重複行為", 4, Sparkles],
  ["Sensory responses", "感官反應", 6, AudioLines],
  ["Play", "遊戲方式", 3, Heart],
  ["Loss of skills", "技能退步", 1, ShieldCheck],
  ["Safety", "安全", 2, ShieldCheck],
] as const;
export function QuestionnaireIntro({
  language,
  onStart,
  onLater,
  completed,
  onCategory,
}: {
  language: Language;
  onStart: () => void;
  onLater: () => void;
  completed: number;
  onCategory: (index: number) => void;
}) {
  const zh = language !== "en",
    t = translator(language);
  return (
    <section className="questionnaire-intro">
      <button className="questionnaire-back" onClick={onLater}>{t("‹ Home", "‹ 首頁")}</button>
      <h1>{t("Observation questionnaire", "觀察問卷")}</h1>

      <div className="questionnaire-meta"><BookOpen size={17} /><span>{t("33 questions · 7 categories", "33 題 · 7 個類別")}</span></div>
      <div className="questionnaire-rule"><ShieldCheck size={17} /><span>{t("No scores or diagnosis", "唔會評分或診斷")}</span></div>
      <div className="questionnaire-progress"><span>{t(`${completed} of 33 answered`, `已回答 ${completed} / 33 題`)}</span><progress value={completed} max={33} aria-label={t("Questionnaire progress", "問卷進度")}/></div>
      <h2 className="subheading">{t("Question categories", "問卷類別")}</h2>
      <div className="category-grid">
        {groups.map(([en, tc, count, Icon], i) => (
          <button type="button" key={en} className={`question-group group-${i}`} onClick={() => onCategory(groups.slice(0,i).reduce((total,g)=>total+g[2],0))}>
            <span className="question-group-icon"><Icon size={20} /></span>
            <strong>{t(en, tc)}</strong>
            <small>
              {count} {t("questions", "題")}
            </small><ArrowRight size={16} aria-hidden="true" />
          </button>
        ))}
      </div>
      <button className="primary full" onClick={onStart}>
        {completed ? t("Continue questionnaire", "繼續問卷") : t("Start questionnaire", "開始問卷")}
        <ArrowRight size={18} />
      </button>
      <button className="secondary full" onClick={onLater}>
        {t("Go to Home", "返首頁")}
      </button>
    </section>
  );
}
export function ProfileFields({
  profile,
  onChange,
  language,
  section = "all",
}: {
  section?: "all" | "basics" | "context";
  profile: Profile;
  onChange: (p: Profile) => void;
  language: Language;
}) {
  const zh = language !== "en",
    t = translator(language);
  return (
    <>
      {section !== "context" && <>
      <label>
        {t("Nickname (optional)", "小朋友嘅暱稱（選填）")}
        <input
          maxLength={40}
          autoComplete="nickname"
          value={profile.nickname}
          onChange={(e) => onChange({ ...profile, nickname: e.target.value })}
        />
      </label>
      <fieldset className="age-fields">
        <legend>{t("Age", "年齡")}</legend>
        <label>
          {t("Years", "歲")}
          <input
            type="number"
            required
            min="0"
            max="6"
            value={Math.floor(profile.ageMonths / 12)}
            onChange={(e) =>
              onChange({
                ...profile,
                ageMonths:
                  Number(e.target.value) * 12 + (profile.ageMonths % 12),
              })
            }
          />
        </label>
        <label>
          {t("Months", "個月")}
          <input
            type="number"
            required
            min="0"
            max="11"
            value={profile.ageMonths % 12}
            onChange={(e) =>
              onChange({
                ...profile,
                ageMonths:
                  Math.floor(profile.ageMonths / 12) * 12 +
                  Number(e.target.value),
              })
            }
          />
        </label>
      </fieldset>
      </>}
      {section === "all" && <>
      <fieldset className="stage-options">
        <legend>{t("Where are you now?", "你而家去到邊個階段？")}</legend>
        {(profile.stage === "diagnosed" ? [...onboardingStages, "diagnosed" as const] : onboardingStages).map(value => (
          <label
            key={value}
            className={profile.stage === value ? "chosen" : ""}
          >
            <input
              type="radio"
              name="journey-stage"
              value={value}
              checked={profile.stage === value}
              onChange={() =>
                onChange({ ...profile, stage: value as Profile["stage"] })
              }
            />
            <span>{t(...stages[value])}</span>
          </label>
        ))}
      </fieldset>
      <p className="fine-print">
        {t(
          "You choose this stage. Questionnaire answers never change it.",
          "呢個階段由你揀，問卷答案唔會改變你嘅選擇。",
        )}
      </p>
      </>}
      {section !== "basics" && <>
      <label>
        {t("First noticed", "你幾時開始留意到？")}
        <input
          type="date"
          required
          max={new Date().toISOString().slice(0, 10)}
          value={profile.firstConcernDate}
          onChange={(e) =>
            onChange({ ...profile, firstConcernDate: e.target.value })
          }
        />
      </label>
      <label>
        {t("What prompted you? (optional)", "係咩令你開始留意？（選填）")}
        <textarea
          value={profile.concernNotes}
          onChange={(e) =>
            onChange({ ...profile, concernNotes: e.target.value })
          }
        />
      </label>
      {["diagnosed", "assessed", "registered", "waitingSupport", "receivingServices"].includes(profile.stage) && (
        <fieldset className="report-details">
          <legend>
            {t(
              "From an existing professional report (optional)",
              "已有專業報告嘅資料（選填）",
            )}
          </legend>
          <p className="fine-print">
            {t(
              "Copy the report exactly. CareVoice does not interpret these details.",
              "請照報告原文填寫，CareVoice 唔會解讀呢啲資料。",
            )}
          </p>
          <label>
            {t("Diagnosing organisation", "診斷機構")}
            <input
              maxLength={160}
              value={profile.diagnosingBody ?? ""}
              onChange={(e) =>
                onChange({ ...profile, diagnosingBody: e.target.value })
              }
            />
          </label>
          <label>
            {t("Report date", "報告日期")}
            <input
              type="date"
              max={new Date().toISOString().slice(0, 10)}
              value={profile.diagnosisDate ?? ""}
              onChange={(e) =>
                onChange({ ...profile, diagnosisDate: e.target.value })
              }
            />
          </label>
          <label>
            {t("Support level as written in the report", "報告寫嘅支援程度")}
            <input
              maxLength={160}
              value={profile.reportedSupportLevel ?? ""}
              onChange={(e) =>
                onChange({ ...profile, reportedSupportLevel: e.target.value })
              }
            />
          </label>
        </fieldset>
      )}
      </>}
    </>
  );
}
