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
  X,
} from "lucide-react";
import {
  onboardingDestination,
  answeredCount,
  answers,
  categories,
  emptyData,
  needsFollowUp,
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
import "./styles.css";
import "./blue.css";
import {
  Welcome,
  QuestionnaireIntro,
  ProfileFields,
  SetupProgress,
} from "./components/Onboarding";
import { Dashboard } from "./components/Dashboard";
import { RecordsScreen } from "./components/RecordsScreen";
import { Community } from "./components/Community";
const questions: Question[] = questionsJson;
type Page =
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
          "Saved data could not be read. It has not been overwritten. Download a copy before resetting. / 未能讀取資料，原有資料並未被覆寫。請先下載備份。",
      };
    }
  });
  const [data, setData] = useState(initial.data),
    [error, setError] = useState(initial.error),
    [locked, setLocked] = useState(!!initial.error);
  const [page, setPage] = useState<Page>(
      initial.data.profile ? "home" : "welcome",
    ),
    [profileOpen, setProfileOpen] = useState(false),
    [draftProfile, setDraftProfile] = useState<Profile>(blankProfile),
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
          "未能儲存。上次儲存的記錄已保留。請釋放瀏覽器儲存空間後重試。",
        ),
      );
    }
  }
  function go(p: Page) {
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
  useEffect(() => {
    if (followUp && page === "questionnaire") window.scrollTo({ top: 0 });
  }, [followUp, page]);
  const warning = followUp ? (
    <aside className="notice" role="alert">
      <Heart size={20} />
      <div>
        <strong>{t("A change worth discussing", "值得跟進的變化")}</strong>
        <p>
          {t(
            "You answered Yes or Not sure about a loss of skills. Discuss this observation promptly with a qualified professional.",
            "你在技能退步題目回答「是」或「不確定」。請盡快與合資格專業人士討論這些觀察。",
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
            "資料於 2026 年 10 月 15 日核對",
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
            "以此備份取代本裝置的 CareVoice 資料？",
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
          "未能匯入備份，現有資料已保留。請選擇有效的 CareVoice JSON 備份。",
        ),
      );
    } finally {
      if (importRef.current) importRef.current.value = "";
    }
  }
  return (
    <div className="app-shell">
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
        {page === "welcome" && (
          <Welcome language={data.language} onStart={openProfile} />
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
          <>
            <Back onClick={() => go("home")} label={t("Home", "首頁")} />
            <PageHeading title={t("Waiting-period navigator", "等待期導航")} />
            {!data.profile ? (
              <Empty
                icon={<Compass />}
                title={t("Where are you now?", "你目前在哪個階段？")}

                action={
                  <button className="primary" onClick={openProfile}>
                    {t("Create a profile", "建立檔案")}
                  </button>
                }
              />
            ) : (
              <>
                <div className="stage-card">
                  <Compass size={24} />
                  <small>{t("YOUR CURRENT STAGE", "目前階段")}</small>
                  <h2>{pair(stages[data.profile.stage])}</h2>
                  <button className="text-button" onClick={openProfile}>
                    {t("Update my stage", "更新階段")}
                    <Pencil size={14} />
                  </button>
                </div>
                <h2 className="subheading">
                  {t("Your personal checklist", "你的個人清單")}
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
                        {pair(s)}
                      </button>
                    );
                  })}
                </div>
                <p className="fine-print">
                  {t(
                    "This is your checklist. Completing a step does not register you for a service or change an official waiting list.",
                    "這是你的個人清單。勾選項目不代表已登記服務，亦不會更改官方輪候狀況。",
                  )}
                </p>
                <button
                  className="secondary full"
                  onClick={() => go("resources")}
                >
                  {t("Explore official resources", "查看官方資源")}
                  <ArrowRight size={16} />
                </button>
              </>
            )}
          </>
        )}
        {page === "questionnaire" && (
          <>
            <Back onClick={() => go("home")} label={t("Home", "首頁")} />
            {warning}
            {review ? (
              <>
                <PageHeading title={t("Your responses", "你的回答")} />
                <aside className="review-boundary">
                  <ShieldCheck size={20} />
                  {t(
                    "Caregiver observations only. No score, diagnosis or inferred stage.",
                    "只整理照顧者的觀察，不作評分、診斷或推斷階段。",
                  )}
                </aside>
                <button className="primary full" onClick={() => go("home")}>
                  {t("Enter Home", "進入首頁")}
                  <ArrowRight size={18} />
                </button>
                <div className="review-count">
                  <BookOpen />
                  <strong>{answeredCount(data.answers)} / 30</strong>
                  <span>{t("answered", "已回答")}</span>
                </div>
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
                        {q.id}. {zh ? q.zh : q.en}
                      </span>
                      <strong>
                        {data.answers[q.id]
                          ? pair(answers[data.answers[q.id]])
                          : t("Unanswered", "未回答")}
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
                  <span>{t("Everyday reflection", "日常觀察問卷")}</span>
                  <button
                    className="text-button"
                    onClick={() => setReview(true)}
                  >
                    {t("Review answers", "檢視回答")}
                  </button>
                </div>
                <div className="question-progress">
                  <div className="progress-track">
                    <i style={{ width: `${((qIndex + 1) / 30) * 100}%` }} />
                  </div>
                  <span>{qIndex + 1} / 30</span>
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
                  {(questions[qIndex].yesNo
                    ? ["yes", "no", "unsure"]
                    : ["never", "rarely", "sometimes", "often", "unsure"]
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
                {[29, 30].includes(questions[qIndex].id) &&
                  ["yes", "unsure"].includes(
                    data.answers[questions[qIndex].id],
                  ) && (
                    <label className="regression-note">
                      {t(
                        "Roughly when did this happen? (optional)",
                        "大概何時發生？（選填）",
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
                      qIndex === 29 ? setReview(true) : setQIndex((i) => i + 1)
                    }
                  >
                    {t(
                      qIndex === 29 ? "Review" : "Next",
                      qIndex === 29 ? "檢視" : "下一題",
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
                    qIndex === 29 ? setReview(true) : setQIndex((i) => i + 1);
                  }}
                >
                  {t("Skip for now", "暫時略過")}
                </button>
                <p className="fine-print centered">
                  <LockKeyhole size={12} />
                  {t(
                    "Answers save automatically on this device.",
                    "答案自動儲存在此裝置。",
                  )}
                </p>
              </>
            )}
          </>
        )}
        {page === "resources" && <Community language={data.language} />}
        {page === "profile" && (
          <>
            <PageHeading title={t("Profile", "我的")} />
            <button className="profile-summary" onClick={openProfile}>
              <span className="large-avatar">
                <Leaf size={30} />
              </span>
              <h2>
                {data.profile?.nickname ||
                  t(
                    data.profile ? "Your child" : "Create your profile",
                    data.profile ? "你的孩子" : "建立你的檔案",
                  )}
              </h2>
              <p>
                {data.profile
                  ? `${data.profile.ageMonths} ${t("months", "個月")} · ${pair(stages[data.profile.stage])}`
                  : t(
                      "A nickname is all you need to get started.",
                      "用暱稱即可開始。",
                    )}
              </p>
              <span className="text-button">
                {t(
                  data.profile ? "Edit profile" : "Get started",
                  data.profile ? "編輯檔案" : "開始使用",
                )}
                <Pencil size={14} />
              </span>
            </button>
            <div className="settings-list">
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
              <button onClick={questionnaireStart}>
                <BookOpen size={20} />
                {t("Observation questions", "觀察問卷")}
                <span>{answeredCount(data.answers)}/30</span>
                <ChevronRight size={17} />
              </button>
              <button onClick={() => go("report")}>
                <FileText size={20} />
                {t("Reports & sharing", "報告與分享")}
                <ChevronRight size={17} />
              </button>
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
              <button
                className="danger-text"
                onClick={() => setResetOpen(true)}
              >
                <Trash2 size={20} />
                {t("Delete all local data", "刪除所有本機資料")}
                <ChevronRight size={17} />
              </button>
            </div>
            <aside className="privacy-card">
              <ShieldCheck size={23} />
              <div>
                <h3>
                  {t("Your notebook stays with you", "你的記錄，由你保管")}
                </h3>
                <p>
                  {t(
                    "Records stay in this browser. No account, analytics, or cloud sync. Clearing browser data can erase them; keep a backup. Browser storage is not encrypted by CareVoice.",
                    "記錄儲存在此瀏覽器，沒有帳戶、分析追蹤或雲端同步。清除瀏覽器資料會刪除記錄，請保留備份。CareVoice 並未加密瀏覽器儲存資料。",
                  )}
                </p>
              </div>
            </aside>
            <p className="fine-print">
              {t(
                "CareVoice organises caregiver observations. It does not provide a diagnosis, score, or clinical assessment.",
                "CareVoice 協助整理照顧者的觀察，不提供診斷、評分或臨床評估。",
              )}
            </p>
          </>
        )}
        {page === "report" && (
          <>
            <Back
              onClick={() => go("records")}
              label={t("Observations", "觀察記錄")}
            />
            <PageHeading title={t("Reports", "報告")} />
            <div className="segmented">
              <button
                className={professional ? "active" : ""}
                onClick={() => setProfessional(true)}
              >
                {t("Appointment", "專業會面")}
              </button>
              <button
                className={!professional ? "active" : ""}
                onClick={() => setProfessional(false)}
              >
                {t("Family", "家庭摘要")}
              </button>
            </div>
            {warning}
            <div className="report-paper">
              <span className="report-brand">CareVoice</span>
              <pre>
                {reportText(data, questions, professional)
                  .split("\n")
                  .slice(1)
                  .join("\n")}
              </pre>
            </div>
            <button
              className="primary full"
              onClick={() =>
                void shareReport(
                  reportText(data, questions, professional),
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
            <p className="fine-print">
              {t(
                "Review before sharing. Exported reports are independent copies; deleting app data won’t remove them.",
                "分享前請先檢視。匯出的報告是獨立副本，刪除應用程式資料不會刪除這些副本。",
              )}
            </p>
          </>
        )}
      </main>
      {!["welcome", "questionnaireIntro"].includes(page) && (
        <nav
          className="bottom-nav"
          aria-label={t("Main navigation", "主要導覽")}
        >
          {(
            [
              ["home", House, "Home", "首頁"],
              ["records", BookOpen, "Records", "記錄"],
              ["resources", UsersRound, "Community", "社區"],
              ["profile", UserRound, "Profile", "我的"],
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
              <span>{t(en, cn)}</span>
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
          className="sheet"
          aria-labelledby="profile-title"
          onCancel={() => setProfileOpen(false)}
        >
          <form
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
                    "未能儲存檔案，請重試。",
                  ),
                );
              }
            }}
          >
            <div className="sheet-head">
              <h2 id="profile-title">
                {t(
                  data.profile ? "Edit profile" : "Create child profile",
                  data.profile ? "編輯檔案" : "建立孩子檔案",
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
          </form>
        </dialog>
      )}
      {record && (
        <dialog
          className="sheet"
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
                    "未能儲存觀察，請重試。",
                  ),
                );
              }
            }}
          >
            <div className="sheet-head">
              <h2 id="record-title">
                {t(
                  data.records.some((r) => r.id === record.id)
                    ? "Your observation"
                    : "A moment worth keeping",
                  data.records.some((r) => r.id === record.id)
                    ? "你的觀察"
                    : "值得記下的一刻",
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
                    {t("Use your keyboard microphone", "使用鍵盤的麥克風")}
                  </strong>
                  <p>
                    {t(
                      "Tap the observation field, then your phone keyboard’s microphone. Check the transcript before saving. CareVoice does not record or upload audio.",
                      "點選觀察欄位，再點手機鍵盤的麥克風。儲存前請核對文字，CareVoice 不會錄音或上傳音訊。",
                    )}
                  </p>
                </div>
              )}
              <label>
                {t("What happened?", "發生了甚麼？")}
                <textarea
                  className="observation-input"
                  required
                  maxLength={10000}
                  value={record.text}
                  placeholder={t("Today, I noticed…", "今天，我留意到……")}
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
              <details>
                <summary>
                  {t("Add context & what helped", "補充情境及有幫助的方法")}
                </summary>
                <label>
                  {t("What happened before?", "之前發生了甚麼？")}
                  <textarea
                    value={record.context}
                    onChange={(e) =>
                      setRecord({ ...record, context: e.target.value })
                    }
                  />
                </label>
                <label>
                  {t("What helped?", "有甚麼幫助？")}
                  <textarea
                    value={record.helped}
                    onChange={(e) =>
                      setRecord({ ...record, helped: e.target.value })
                    }
                  />
                </label>
              </details>
              <p className="fine-print">
                <AudioLines size={14} />
                {t(
                  "Prefer speaking? Use the microphone on your phone’s keyboard.",
                  "喜歡用說話記錄？可使用手機鍵盤的語音輸入。",
                )}
              </p>
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
            {t("Delete this observation?", "刪除此觀察？")}
          </h2>
          <p>
            {t(
              "This removes it from this browser. Exported copies won’t be affected.",
              "這會從此瀏覽器刪除觀察，已匯出的副本不受影響。",
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
            {t("Delete all local data?", "刪除所有本機資料？")}
          </h2>
          <p>
            {t(
              "Your profile, observations and answers will be removed from this browser. Download a backup first if you want to keep them.",
              "你的檔案、觀察和回答將從此瀏覽器刪除。如需保留，請先下載備份。",
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
                    "未能刪除資料，請重試。",
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
