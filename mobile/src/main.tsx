import React, { useEffect, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  AudioLines,
  ArrowLeft,
  ArrowRight,
  ArrowUpRight,
  BookOpen,
  Check,
  ChevronRight,
  ChevronDown,
  CircleCheck,
  Compass,
  Download,
  FileText,
  Globe2,
  Mic,
  UsersRound,
  Heart,
  House,
  Leaf,
  LockKeyhole,
  MessageCircle,
  MoreHorizontal,
  Pencil,
  Plus,
  Search,
  Share2,
  ShieldCheck,
  Sparkles,
  Sun,
  Trash2,
  UserRound,
  Settings,
  X,
} from "lucide-react";
import {
  onboardingDestination,
  answeredCount,
  answers,
  categories,
  emptyData,
  needsFollowUp,
  needsSafetyRouting,
  QUESTION_COUNT,
  nextSteps,
  reportText,
  stages,
  type Answer,
  type AppData,
  type Category,
  type Language,
  type Observation,
  type Profile,
  type Question,
  type Stage,
} from "./domain";
import { browserStore, validateData } from "./platform/storage";
import { download, shareReport } from "./platform/share";
import questionsJson from "./questions.json";
import legacyQuestions from "./legacy-questions.json";
import { SafetyRouting } from "./components/SafetyRouting";
import "./styles.css";
import "./blue.css";
import {
  QuestionnaireIntro,
  ProfileFields,
  SetupProgress,
} from "./components/Onboarding";
import { Dashboard } from "./components/Dashboard";
import { RecordsScreen } from "./components/RecordsScreen";
import { ReportPreview } from "./components/ReportPreview";
import { Community } from "./components/Community";
import { LaunchScreen } from "./components/LaunchScreen";
import { GuidedOnboarding } from "./components/GuidedOnboarding";
const questions: Question[] = questionsJson;
type Page =
  | "signIn"
  | "welcome"
  | "questionnaireIntro"
  | "home"
  | "records"
  | "resources"
  | "profile"
  | "questionnaire"
  | "journey"
  | "report";
const blankProfile = (): Profile => ({
  nickname: "",
  ageMonths: 36,
  stage: "noticed",
  concernNotes: "",
  firstConcernDate: new Date().toISOString().slice(0, 10),
});
const newRecord = (): Observation => ({
  id:
    typeof crypto.randomUUID === "function"
      ? crypto.randomUUID()
      : Array.from(crypto.getRandomValues(new Uint8Array(16)), (b) =>
          b.toString(16).padStart(2, "0"),
        ).join(""),
  date: new Date().toISOString(),
  text: "",
  category: "observation",
  location: "",
  durationMinutes: null,
  context: "",
  helped: "",
});
function App() {
  const [initial] = useState(() => {
    try {
      return { data: browserStore.load(), error: "" };
    } catch {
      return {
        data: emptyData(),
        error:
          "Saved data could not be read. It has not been overwritten. Download a copy before resetting. / 讀唔到已儲存嘅資料，原有資料冇被覆蓋。重設之前，請先下載備份。",
      };
    }
  });
  const [data, setData] = useState(initial.data),
    [error, setError] = useState(initial.error),
    [locked, setLocked] = useState(!!initial.error);
  const [page, setPage] = useState<Page>(
      window.location.hash === "#sign-in" ? "signIn" : initial.data.profile ? "home" : "welcome",
    ),
    [profileOpen, setProfileOpen] = useState(window.location.hash === "#onboarding"),
    [draftProfile, setDraftProfile] = useState<Profile>(() => initial.data.profile ?? blankProfile()),
    [record, setRecord] = useState<Observation | null>(null),
    [deleteId, setDeleteId] = useState<string | null>(null),
    [resetOpen, setResetOpen] = useState(false);
  const [search, setSearch] = useState(""),
    [filter, setFilter] = useState<Category | "all">("all"),
    [qIndex, setQIndex] = useState(0),
    [review, setReview] = useState(false),
    [professional, setProfessional] = useState(true),
    [saved, setSaved] = useState(false);
  const [voiceEntry, setVoiceEntry] = useState(false);
  const mainRef = useRef<HTMLElement>(null),
    importRef = useRef<HTMLInputElement>(null);
  const zh = data.language === "zh",
    t = (a: string, b: string) => (zh ? b : a),
    pair = (v: [string, string]) => v[zh ? 1 : 0];
  function update(fn: (d: AppData) => AppData) {
    if (locked) return;
    const next = fn(data);
    try {
      browserStore.save(next);
      setData(next);
      setError("");
    } catch {
      setError(
        t(
          "Could not save. Your last saved records are preserved. Free some browser storage and try again.",
          "儲存唔到，上次儲存嘅記錄仲喺度。請騰出瀏覽器儲存空間，再試一次。",
        ),
      );
    }
  }
  function go(p: Page) {
    window.history.replaceState(null, "", `${window.location.pathname}${window.location.search}${p === "signIn" ? "#sign-in" : ""}`);
    setPage(p);
    setSaved(false);
    window.scrollTo({ top: 0 });
    requestAnimationFrame(() => mainRef.current?.focus());
  }
  useEffect(() => {
    document.documentElement.lang = zh ? "zh-Hant" : "en";
  }, [zh]);
  useEffect(() => {
    window.scrollTo({ top: 0 });
  }, [qIndex, review]);
  useEffect(() => {
    if (!profileOpen && !record && !resetOpen && !deleteId) return;
    const before = document.activeElement as HTMLElement;
    const dialog = document.querySelector<HTMLDialogElement>("dialog");
    dialog?.showModal();
    dialog?.querySelector<HTMLElement>("input,button")?.focus();
    return () => {
      dialog?.close();
      before?.focus();
    };
  }, [profileOpen, record?.id, resetOpen, deleteId]);
  const openProfile = () => {
    setDraftProfile(data.profile ?? blankProfile());
    setProfileOpen(true);
  };
  const followUp = needsFollowUp(data.answers);
  const safetyRouting = needsSafetyRouting(data.answers);
  useEffect(() => {
    if ((followUp || safetyRouting) && page === "questionnaire") window.scrollTo({ top: 0 });
  }, [followUp, safetyRouting, data.answers[132], data.answers[133], page]);
  const warning = followUp ? (
    <aside className="notice" role="alert">
      <Heart size={20} />
      <div>
        <strong>{t("A change worth discussing", "值得跟進嘅變化")}</strong>
        <p>
          {t(
            "You answered Yes or Not sure about a loss of skills. Discuss this observation promptly with a qualified professional.",
            "你喺技能退步題目揀咗「有」或「唔肯定」。請盡快同醫生或母嬰健康院討論你嘅觀察。",
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
          {t(
            "Contact your MCHC or family doctor · DH guidance",
            "聯絡母嬰健康院或家庭醫生 · 衛生署指引",
          )}
          <ArrowUpRight size={14} />
        </a>
        <small>
          {t(
            "Source checked 15 October 2026",
            "資料已喺 2026 年 10 月 15 日核對",
          )}
        </small>
      </div>
    </aside>
  ) : null;
  const dateLabel = (d: string) =>
    new Date(d).toLocaleDateString(zh ? "zh-HK" : "en-HK", {
      month: "short",
      day: "numeric",
    });
  function questionnaireStart() {
    setReview(false);
    const first = questions.findIndex((q) => !data.answers[q.id]);
    setQIndex(first < 0 ? 0 : first);
    go("questionnaire");
  }
  async function importBackup(file?: File) {
    if (!file) return;
    try {
      if (file.size > 10_000_000) throw Error();
      const incoming = validateData(JSON.parse(await file.text()));
      if (
        !window.confirm(
          t(
            "Replace this device’s CareVoice data with this backup?",
            "要用呢份備份取代呢部裝置嘅 CareVoice 資料？",
          ),
        )
      )
        return;
      browserStore.save(incoming);
      setLocked(false);
      setData(incoming);
      setError("");
      go("home");
    } catch {
      setError(
        t(
          "Could not import this backup. Current data was kept. Choose a valid CareVoice JSON backup.",
          "匯入唔到備份，現有資料仲喺度。請揀一份有效嘅 CareVoice JSON 備份。",
        ),
      );
    } finally {
      if (importRef.current) importRef.current.value = "";
    }
  }
  function saveChildProfile() {
    if (locked) return;
    const next = { ...data, profile: { ...draftProfile, nickname: draftProfile.nickname.trim() } };
    try {
      browserStore.save(next);
      setData(next);
      setError("");
      setProfileOpen(false);
      if (!data.profile) go(onboardingDestination(next.profile.stage));
    } catch {
      setError(t("Profile could not be saved. Please try again.", "儲存唔到檔案，請再試一次。"));
    }
  }
  return (
    <div className={`app-shell${page === "signIn" || page === "welcome" ? " sign-in-shell launch-shell" : ""}`}>
      {error && (
        <div role="alert" className="error-banner">
          {error}
          <button
            onClick={() =>
              download(
                localStorage.getItem("carevoice.mobile.v1") || "",
                "carevoice-recovery.json",
                "application/json",
              )
            }
          >
            {t("Download saved data", "下載已存資料")}
          </button>
        </div>
      )}
      <main ref={mainRef} tabIndex={-1}>
        {(page === "signIn" || page === "welcome") && (
          <LaunchScreen key={page} language={data.language} initialSignIn={page === "signIn"}
            onCloseSignIn={() => go(data.profile ? "profile" : "welcome")}
            onContinue={() => { if (data.profile) go("home"); else openProfile(); }} />
        )}
        {page === "questionnaireIntro" && (
          <QuestionnaireIntro
            language={data.language}
            onStart={questionnaireStart}
            onLater={() => go("home")}
          />
        )}
        {page === "home" && (
          <>
            {safetyRouting && <SafetyRouting language={data.language} />}
            {warning}
            <Dashboard
              data={data}
              onProfile={openProfile}
              onQuestionnaire={() => go("questionnaireIntro")}
              onJourney={() => go("journey")}
              onRecords={() => go("records")}
              onReport={() => go("report")}
              onAdd={() => {
                setVoiceEntry(false);
                setRecord(newRecord());
              }}
              onEdit={(r) => {
                setVoiceEntry(false);
                setRecord(r);
              }}
            />
          </>
        )}
        {page === "records" && (
          <RecordsScreen
            records={data.records}
            language={data.language}
            search={search}
            filter={filter}
            onSearch={setSearch}
            onFilter={setFilter}
            onAdd={() => {
              setVoiceEntry(false);
              setRecord(newRecord());
            }}
            onVoice={() => {
              setVoiceEntry(true);
              setRecord(newRecord());
            }}
            onReport={() => go("report")}
            onEdit={(r) => {
              setVoiceEntry(false);
              setRecord(r);
            }}
          />
        )}
        {page === "journey" && (
          <div className="journey-screen">
            <Back onClick={() => go("home")} label={t("Home", "首頁")} />
            <PageHeading title={t("Next steps", "下一步")} />
            {!data.profile ? (
              <Empty
                icon={<Compass />}
                title={t("Where are you now?", "你而家去到邊個階段？")}

                action={
                  <button className="primary" onClick={openProfile}>
                    {t("Create a profile", "建立檔案")}
                  </button>
                }
              />
            ) : (
              <>
                <h2 className="journey-section">{t("Your stage", "你而家嘅階段")}</h2>
                <button className="journey-stage" onClick={openProfile} aria-label={`${t("Update my stage", "更新階段")} · ${pair(stages[data.profile.stage])}`}>
                  <span className="journey-stage-icon" aria-hidden="true"><Compass size={22} strokeWidth={1.7} /></span>
                  <span>{pair(stages[data.profile.stage])}</span>
                  <Pencil size={17} aria-hidden="true" />
                </button>
                <h2 className="subheading">
                  {t("Your personal checklist", "你嘅個人清單")}
                </h2>
                <div className="checklist">
                  {nextSteps(data.profile.stage).map((s, i) => {
                    const key = `${data.profile!.stage}-${i}`,
                      done = data.completedSteps.includes(key);
                    return (
                      <button
                        key={key}
                        role="checkbox"
                        aria-checked={done}
                        className={done ? "done" : ""}
                        onClick={() =>
                          update((d) => ({
                            ...d,
                            completedSteps: done
                              ? d.completedSteps.filter((k) => k !== key)
                              : [...d.completedSteps, key],
                          }))
                        }
                      >
                        <span className="check-circle">
                          {done && <Check size={16} />}
                        </span>
                        <span className="journey-step-label">{pair(s)}</span>
                      </button>
                    );
                  })}
                </div>
                <details className="journey-note"><summary role="button">{t("About your checklist", "關於你嘅清單")}<ChevronDown size={15} aria-hidden="true" /></summary>
                <p className="fine-print">
                  {t(
                    "This is your checklist. Completing a step does not register you for a service or change an official waiting list.",
                    "呢份係你嘅個人清單。剔選項目唔代表已登記服務，亦唔會改變官方輪候狀況。",
                  )}
                </p>
                </details>
                <button
                  className="journey-resources"
                  onClick={() => go("resources")}
                >
                  <ShieldCheck size={20} aria-hidden="true" />
                  <span>{t("Explore official resources", "查看官方資源")}</span>
                  <ArrowRight size={16} />
                </button>
              </>
            )}
          </div>
        )}
        {page === "questionnaire" && (
          <div className="questionnaire-screen">
            <Back onClick={() => go("home")} label={t("Home", "首頁")} />
            {safetyRouting && <SafetyRouting language={data.language} />}
            {warning}
            {review ? (
              <>
                <PageHeading title={t("Your responses", "你嘅回答")} />
                <aside className="review-boundary">
                  <ShieldCheck size={20} />
                  {t(
                    "Caregiver observations only. No score, diagnosis or inferred stage.",
                    "只整理照顧者嘅觀察，唔會評分、診斷或推斷階段。",
                  )}
                </aside>
                <button className="primary full" onClick={() => go("home")}>
                  {t("Enter Home", "返首頁")}
                  <ArrowRight size={18} />
                </button>
                <div className="review-count">
                  <BookOpen />
                  <strong>{answeredCount(data.answers)} / {QUESTION_COUNT}</strong>
                  <span>{t("answered", "已回答")}</span>
                </div>
                {Object.keys(data.answers).some(id => Number(id) < 101) && <p className="fine-print">{t("Earlier questionnaire responses are preserved in your report and backup. These revised questions start fresh.", "舊版問卷回答已保留喺報告同備份。新版問題需要重新回答。")}</p>}
                <div className="review-list">
                  {questions.map((q, i) => (
                    <button
                      key={q.id}
                      onClick={() => {
                        setQIndex(i);
                        setReview(false);
                      }}
                    >
                      <span>
                        {i + 1}. {zh ? q.zh : q.en}
                      </span>
                      <strong>
                        {data.answers[q.id]
                          ? pair(answers[data.answers[q.id]])
                          : t("Unanswered", "未答")}
                      </strong>
                      <Pencil size={14} />
                    </button>
                  ))}
                </div>
                <button className="primary full" onClick={() => go("report")}>
                  {t("Prepare a report", "準備報告")}
                  <ArrowRight size={17} />
                </button>
              </>
            ) : (
              <>
                <div className="section-head question-top">
                  <span>{t("Questionnaire", "觀察問卷")}</span>
                  <button
                    className="text-button"
                    onClick={() => setReview(true)}
                  >
                    {t("Review answers", "檢視回答")}
                  </button>
                </div>
                <div className="question-progress">
                  <div className="progress-track" role="progressbar" aria-label={t("Question progress", "問卷進度")} aria-valuemin={1} aria-valuemax={QUESTION_COUNT} aria-valuenow={qIndex + 1}>
                    <i style={{ width: `${((qIndex + 1) / QUESTION_COUNT) * 100}%` }} />
                  </div>
                  <span>{qIndex + 1} / {QUESTION_COUNT}</span>
                </div>
                <p className="question-category">
                  {zh
                    ? questions[qIndex].categoryZH
                    : questions[qIndex].categoryEN}
                </p>
                <h1 className="question-title">
                  {zh ? questions[qIndex].zh : questions[qIndex].en}
                </h1>

                <div className="answer-options">
                  {(questions[qIndex].options ?? (questions[qIndex].yesNo
                    ? ["yes", "no", "unsure"]
                    : ["never", "sometimes", "often", "unsure"])
                  ).map((a) => (
                    <button
                      key={a}
                      aria-pressed={data.answers[questions[qIndex].id] === a}
                      className={
                        data.answers[questions[qIndex].id] === a
                          ? "selected"
                          : ""
                      }
                      onClick={() =>
                        update((d) => ({
                          ...d,
                          answers: {
                            ...d.answers,
                            [questions[qIndex].id]: a as Answer,
                          },
                        }))
                      }
                    >
                      {pair(answers[a as Answer])}
                      <span className="check-circle">
                        {data.answers[questions[qIndex].id] === a && (
                          <Check size={16} />
                        )}
                      </span>
                    </button>
                  ))}
                </div>
                {questions[qIndex].safety === "regression" &&
                  ["yes", "unsure"].includes(
                    data.answers[questions[qIndex].id],
                  ) && (
                    <label className="regression-note">
                      {t(
                        "Roughly when did this happen? (optional)",
                        "大概係幾時發生？（選填）",
                      )}
                      <input
                        maxLength={250}
                        value={
                          data.regressionWhen?.[questions[qIndex].id] ?? ""
                        }
                        onChange={(e) =>
                          update((d) => ({
                            ...d,
                            regressionWhen: {
                              ...d.regressionWhen,
                              [questions[qIndex].id]: e.target.value,
                            },
                          }))
                        }
                      />
                    </label>
                  )}
                <div className="question-controls">
                  <button
                    className="secondary"
                    disabled={qIndex === 0}
                    onClick={() => setQIndex((i) => i - 1)}
                  >
                    <ArrowLeft size={17} />
                    {t("Back", "上一題")}
                  </button>
                  <button
                    className="primary"
                    disabled={!data.answers[questions[qIndex].id]}
                    onClick={() =>
                      qIndex === questions.length - 1 ? setReview(true) : setQIndex((i) => i + 1)
                    }
                  >
                    {t(
                      qIndex === questions.length - 1 ? "Review" : "Next",
                      qIndex === questions.length - 1 ? "檢視" : "下一題",
                    )}
                    <ArrowRight size={17} />
                  </button>
                </div>
                <button
                  className="skip-button"
                  onClick={() => {
                    update((d) => ({
                      ...d,
                      answers: {
                        ...d.answers,
                        [questions[qIndex].id]: "skipped",
                      },
                    }));
                    qIndex === questions.length - 1 ? setReview(true) : setQIndex((i) => i + 1);
                  }}
                >
                  {t("Skip for now", "暫時略過")}
                </button>
                <p className="fine-print centered">
                  <LockKeyhole size={12} />
                  {t(
                    "Answers save automatically on this device.",
                    "答案會自動儲存喺呢部裝置。",
                  )}
                </p>
              </>
            )}
          </div>
        )}
        {page === "resources" && <Community language={data.language} />}
        {page === "profile" && (
          <div className="profile-screen">
            <PageHeading title={t("Settings", "設定")} />
            <h2 className="profile-section">{t("Preferences", "偏好設定")}</h2>
            <div className="settings-list">
              <button onClick={openProfile}>
                <UserRound size={20} />{t("Profile", "個人檔案")}
                <ChevronRight size={17} />
              </button>
              <button
                aria-label={t(
                  "Switch to Traditional Chinese",
                  "Switch to English",
                )}
                onClick={() =>
                  update((d) => ({ ...d, language: zh ? "en" : "zh" }))
                }
              >
                <Globe2 size={20} />
                {t("Language", "語言")}
                <span>{zh ? "繁體中文" : "English"}</span>
                <ChevronRight size={17} />
              </button>
            </div>
            <h2 className="profile-section">{t("Care", "照顧工具")}</h2>
            <div className="settings-list">
              <button onClick={questionnaireStart}>
                <BookOpen size={20} />
                {t("Observation questions", "觀察問卷")}
                <span>{answeredCount(data.answers)}/{QUESTION_COUNT}</span>
                <ChevronRight size={17} />
              </button>
              <button onClick={() => go("report")}>
                <FileText size={20} />
                {t("Reports & sharing", "報告同分享")}
                <ChevronRight size={17} />
              </button>
            </div>
            <h2 className="profile-section">{t("Data", "資料管理")}</h2>
            <div className="settings-list">
              <button
                onClick={() =>
                  download(
                    JSON.stringify(data, null, 2),
                    "carevoice-backup.json",
                    "application/json",
                  )
                }
              >
                <Download size={20} />
                {t("Download a backup", "下載備份")}
                <ChevronRight size={17} />
              </button>
              <button onClick={() => importRef.current?.click()}>
                <Share2 size={20} />
                {t("Restore a backup", "還原備份")}
                <ChevronRight size={17} />
              </button>
            </div>
            <div className="settings-list profile-delete">
              <button
                className="danger-text"
                onClick={() => setResetOpen(true)}
              >
                <Trash2 size={20} />
                {t("Delete all local data", "刪除呢部裝置嘅所有資料")}
                <ChevronRight size={17} />
              </button>
            </div>
            <details className="profile-privacy">
              <summary role="button"><ShieldCheck size={17} />{t("Privacy & storage", "私隱同儲存")}<ChevronDown size={16} /></summary>
              <div>
                <h3>
                  {t("Your notebook stays with you", "你嘅記錄，由你保管")}
                </h3>
                <p>
                  {t(
                    "Records stay in this browser. No account, analytics, or cloud sync. Clearing browser data can erase them; keep a backup. Browser storage is not encrypted by CareVoice.",
                    "記錄儲存喺呢個瀏覽器，冇帳戶、分析追蹤或雲端同步。清除瀏覽器資料會刪埋記錄，記得保留備份。CareVoice 冇加密瀏覽器入面儲存嘅資料。",
                  )}
                </p>
              </div>
            <p className="fine-print">
              {t(
                "CareVoice organises caregiver observations. It does not provide a diagnosis, score, or clinical assessment.",
                "CareVoice 幫你整理照顧者嘅觀察，唔會提供診斷、評分或臨床評估。",
              )}
            </p>
            </details>
          </div>
        )}
        {page === "report" && (
          <div className="reports-screen">
            <Back
              onClick={() => go("records")}
              label={t("Observations", "觀察記錄")}
            />
            <PageHeading title={t("Reports", "報告")} />
            <div className="segmented" role="group" aria-label={t("Report audience", "報告對象")}>
              <button
                aria-pressed={professional}
                className={professional ? "active" : ""}
                onClick={() => setProfessional(true)}
              >
                {t("Appointment", "專業會面")}
              </button>
              <button
                aria-pressed={!professional}
                className={!professional ? "active" : ""}
                onClick={() => setProfessional(false)}
              >
                {t("Family", "家庭摘要")}
              </button>
            </div>
            {safetyRouting && <SafetyRouting language={data.language} />}
            {warning}
            <ReportPreview text={reportText(data, [...questions, ...legacyQuestions.filter(q => data.answers[q.id])], professional)} />
            <div className="report-actions">
            <button
              className="primary full"
              onClick={() =>
                void shareReport(
                  reportText(data, [...questions, ...legacyQuestions.filter(q => data.answers[q.id])], professional),
                  "CareVoice",
                )
              }
            >
              <Share2 size={18} />
              {t("Share or download report", "分享或下載報告")}
            </button>
            <button className="secondary full" onClick={() => window.print()}>
              <FileText size={18} />
              {t("Print / save PDF", "列印／儲存 PDF")}
            </button>
            </div>
            <details className="report-sharing-note"><summary role="button">{t("About sharing", "關於分享")}<ChevronDown size={15} /></summary>
            <p className="fine-print">
              {t(
                "Review before sharing. Exported reports are independent copies; deleting app data won’t remove them.",
                "分享之前記得睇清楚。匯出嘅報告係獨立副本，刪除應用程式資料唔會刪埋呢啲副本。",
              )}
            </p>
            </details>
          </div>
        )}
      </main>
      {!["welcome", "signIn", "questionnaireIntro"].includes(page) && (
        <nav
          className="bottom-nav"
          aria-label={t("Main navigation", "主要導覽")}
        >
          {(
            [
              ["home", House, "Home", "首頁"],
              ["records", BookOpen, "Records", "記錄"],
              ["resources", UsersRound, "Community", "社區"],
              ["profile", Settings, "Settings", "設定"],
            ] as const
          ).map(([p, Icon, en, cn]) => (
            <button
              key={p}
              className={
                page === p ||
                (p === "home" && ["journey", "questionnaire"].includes(page)) ||
                (p === "records" && page === "report")
                  ? "active"
                  : ""
              }
              aria-current={
                page === p ||
                (p === "home" && ["journey", "questionnaire"].includes(page)) ||
                (p === "records" && page === "report")
                  ? "page"
                  : undefined
              }
              onClick={() => go(p)}
            >
              <Icon size={23} strokeWidth={1.8} aria-hidden="true" />
              <span className="sr-only">{t(en, cn)}</span>
            </button>
          ))}
        </nav>
      )}
      <input
        ref={importRef}
        type="file"
        accept="application/json,.json"
        hidden
        onChange={(e) => void importBackup(e.target.files?.[0])}
      />
      {profileOpen && (
        <dialog
          className={data.profile ? "sheet" : "guided-onboarding-dialog"}
          aria-labelledby="profile-title"
          onCancel={() => setProfileOpen(false)}
        >
          {!data.profile ? <GuidedOnboarding profile={draftProfile} onChange={setDraftProfile} language={data.language}
            locked={locked} onClose={() => setProfileOpen(false)} onSave={saveChildProfile} /> : <form
            onSubmit={(e) => {
              e.preventDefault();
              if (locked) return;
              const next = {
                ...data,
                profile: {
                  ...draftProfile,
                  nickname: draftProfile.nickname.trim(),
                },
              };
              try {
                browserStore.save(next);
                setData(next);
                setError("");
                setProfileOpen(false);
                if (!data.profile)
                  go(onboardingDestination(next.profile.stage));
              } catch {
                setError(
                  t(
                    "Profile could not be saved. Please try again.",
                    "儲存唔到檔案，請再試一次。",
                  ),
                );
              }
            }}
          >
            <div className="sheet-head">
              <h2 id="profile-title">
                {t(
                  data.profile ? "Edit profile" : "Create child profile",
                  data.profile ? "編輯檔案" : "建立小朋友檔案",
                )}
              </h2>
              <button
                type="button"
                className="icon-button"
                aria-label={t("Close", "關閉")}
                onClick={() => setProfileOpen(false)}
              >
                <X />
              </button>
            </div>

            <div className="sheet-body">
              {!data.profile && <SetupProgress language={data.language} />}
              <ProfileFields
                profile={draftProfile}
                onChange={setDraftProfile}
                language={data.language}
              />
            </div>
            <div className="sheet-actions">
              <button className="primary full" disabled={locked} type="submit">
                {t("Save profile", "儲存檔案")}
                <Check size={18} />
              </button>
            </div>
          </form>}
        </dialog>
      )}
      {record && (
        <dialog
          className="sheet observation-sheet"
          aria-labelledby="record-title"
          onCancel={() => setRecord(null)}
        >
          <form
            onSubmit={(e) => {
              e.preventDefault();
              if (!record.text.trim() || locked) return;
              const next = {
                ...data,
                records: [
                  ...data.records.filter((r) => r.id !== record.id),
                  { ...record, text: record.text.trim() },
                ],
              };
              try {
                browserStore.save(next);
                setData(next);
                setError("");
                setRecord(null);
                setSaved(true);
              } catch {
                setError(
                  t(
                    "Observation could not be saved. Please try again.",
                    "儲存唔到觀察記錄，請再試一次。",
                  ),
                );
              }
            }}
          >
            <div className="sheet-head">
              <h2 id="record-title">
                {t(
                  data.records.some((r) => r.id === record.id)
                    ? "Edit observation"
                    : "Add observation",
                  data.records.some((r) => r.id === record.id)
                    ? "編輯觀察"
                    : "新增觀察",
                )}
              </h2>
              <button
                type="button"
                className="icon-button"
                aria-label={t("Close", "關閉")}
                onClick={() => setRecord(null)}
              >
                <X />
              </button>
            </div>

            <div className="sheet-body">
              {voiceEntry && (
                <div className="voice-entry-help">
                  <Mic size={22} />
                  <strong>
                    {t("Use your keyboard microphone", "用鍵盤嘅咪輸入")}
                  </strong>
                  <p>
                    {t(
                      "Tap the observation field, then your phone keyboard’s microphone. Check the transcript before saving. CareVoice does not record or upload audio.",
                      "撳觀察欄位，再撳手機鍵盤嘅咪。儲存之前記得核對文字，CareVoice 唔會錄音或上傳聲音。",
                    )}
                  </p>
                </div>
              )}
              <label>
                {t("What happened?", "發生咗咩事？")}
                <textarea
                  className="observation-input"
                  required
                  maxLength={10000}
                  value={record.text}
                  placeholder={t("Today, I noticed…", "今日，我留意到……")}
                  onChange={(e) =>
                    setRecord({ ...record, text: e.target.value })
                  }
                />
              </label>
              <label>
                {t("Category", "分類")}
                <select
                  aria-label={t("Category", "分類")}
                  value={record.category}
                  onChange={(e) =>
                    setRecord({
                      ...record,
                      category: e.target.value as Category,
                    })
                  }
                >
                  {Object.entries(categories).map(([k, v]) => (
                    <option key={k} value={k}>
                      {pair(v)}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                {t("When", "時間")}
                <input
                  type="datetime-local"
                  required
                  value={new Date(
                    new Date(record.date).getTime() -
                      new Date(record.date).getTimezoneOffset() * 60000,
                  )
                    .toISOString()
                    .slice(0, 16)}
                  onChange={(e) => {
                    if (e.target.value)
                      setRecord({
                        ...record,
                        date: new Date(e.target.value).toISOString(),
                      });
                  }}
                />
              </label>
              <details className="observation-details">
                <summary role="button">{t("More details", "補充資料")}<ChevronDown size={17} aria-hidden="true" /></summary>
              <div className="form-row">
                <label>
                  {t("Place (optional)", "地點（選填）")}
                  <input
                    maxLength={120}
                    value={record.location}
                    onChange={(e) =>
                      setRecord({ ...record, location: e.target.value })
                    }
                  />
                </label>
                <label>
                  {t("Minutes (optional)", "分鐘（選填）")}
                  <input
                    type="number"
                    min="0"
                    max="1440"
                    value={record.durationMinutes ?? ""}
                    onChange={(e) =>
                      setRecord({
                        ...record,
                        durationMinutes:
                          e.target.value === "" ? null : Number(e.target.value),
                      })
                    }
                  />
                </label>
              </div>
                <label>
                  {t("What happened before?", "之前發生咗咩事？")}
                  <textarea
                    value={record.context}
                    onChange={(e) =>
                      setRecord({ ...record, context: e.target.value })
                    }
                  />
                </label>
                <label>
                  {t("What helped?", "有咩幫到手？")}
                  <textarea
                    value={record.helped}
                    onChange={(e) =>
                      setRecord({ ...record, helped: e.target.value })
                    }
                  />
                </label>
              </details>

            </div>
            <div className="sheet-actions">
              <button
                className="primary full"
                disabled={!record.text.trim() || locked}
                type="submit"
              >
                {t("Save observation", "儲存觀察")}
                <Check size={18} />
              </button>
              {data.records.some((r) => r.id === record.id) && (
                <button
                  type="button"
                  className="danger-button full"
                  onClick={() => {
                    const id = record.id;
                    setRecord(null);
                    setDeleteId(id);
                  }}
                >
                  <Trash2 size={17} />
                  {t("Delete observation", "刪除觀察")}
                </button>
              )}
            </div>
          </form>
        </dialog>
      )}
      {deleteId && (
        <dialog
          className="sheet compact"
          aria-labelledby="delete-title"
          onCancel={() => setDeleteId(null)}
        >
          <h2 id="delete-title">
            {t("Delete this observation?", "要刪除呢條觀察記錄？")}
          </h2>
          <p>
            {t(
              "This removes it from this browser. Exported copies won’t be affected.",
              "呢條觀察記錄會喺呢個瀏覽器刪除，已匯出嘅副本唔受影響。",
            )}
          </p>
          <button
            className="danger-button full"
            onClick={() => {
              update((d) => ({
                ...d,
                records: d.records.filter((r) => r.id !== deleteId),
              }));
              setDeleteId(null);
            }}
          >
            {t("Delete observation", "刪除觀察")}
          </button>
          <button className="secondary full" onClick={() => setDeleteId(null)}>
            {t("Keep observation", "保留觀察")}
          </button>
        </dialog>
      )}
      {resetOpen && (
        <dialog
          className="sheet compact"
          aria-labelledby="reset-title"
          onCancel={() => setResetOpen(false)}
        >
          <h2 id="reset-title">
            {t("Delete all local data?", "刪除呢部裝置嘅所有資料？")}
          </h2>
          <p>
            {t(
              "Your profile, observations and answers will be removed from this browser. Download a backup first if you want to keep them.",
              "你嘅檔案、觀察同答案會喺呢個瀏覽器刪除。如果想保留，請先下載備份。",
            )}
          </p>
          <button
            className="secondary full"
            onClick={() =>
              download(
                JSON.stringify(data, null, 2),
                "carevoice-backup.json",
                "application/json",
              )
            }
          >
            {t("Download backup", "下載備份")}
          </button>
          <button
            className="danger-button full"
            onClick={() => {
              try {
                browserStore.clear();
                setData(emptyData());
                setLocked(false);
                setError("");
                setResetOpen(false);
                go("welcome");
              } catch {
                setError(
                  t(
                    "Could not delete data. Please try again.",
                    "刪除唔到資料，請再試一次。",
                  ),
                );
              }
            }}
          >
            {t("Delete everything", "全部刪除")}
          </button>
          <button
            className="text-button full"
            onClick={() => setResetOpen(false)}
          >
            {t("Cancel", "取消")}
          </button>
        </dialog>
      )}
      <div className="sr-only" role="status">
        {saved ? t("Observation saved", "觀察已儲存") : ""}
      </div>
    </div>
  );
}
function PageHeading({ title }: { title: string }) {
  return (
    <div className="page-heading">
      <h1>{title}</h1>
    </div>
  );
}
function Back({ onClick, label }: { onClick: () => void; label: string }) {
  return (
    <button className="back-button" onClick={onClick}>
      <ArrowLeft size={17} />
      {label}
    </button>
  );
}
function Empty({
  icon,
  title,
  action,
}: {
  icon: React.ReactNode;
  title: string;
  action?: React.ReactNode;
}) {
  return (
    <section className="empty-state">
      <span>{icon}</span>
      <h2>{title}</h2>

      {action}
    </section>
  );
}
createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
