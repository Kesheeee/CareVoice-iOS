export type Language = "en" | "zh";
export type Stage =
  | "noticed"
  | "professionalFollowUp"
  | "awaitingAssessment"
  | "assessed"
  | "diagnosed"
  | "registered";
export type Category =
  | "observation"
  | "distress"
  | "progress"
  | "communication"
  | "sensory"
  | "play"
  | "eating";
export type Answer =
  | "varied"
  | "limited"
  | "never"
  | "rarely"
  | "sometimes"
  | "often"
  | "yes"
  | "no"
  | "unsure"
  | "skipped";
export interface Profile {
  nickname: string;
  ageMonths: number;
  stage: Stage;
  concernNotes: string;
  firstConcernDate: string;
  diagnosingBody?: string;
  diagnosisDate?: string;
  reportedSupportLevel?: string;
}
export interface Observation {
  id: string;
  date: string;
  text: string;
  category: Category;
  location: string;
  durationMinutes: number | null;
  context: string;
  helped: string;
}
export interface AppData {
  version: 1;
  language: Language;
  profile: Profile | null;
  records: Observation[];
  answers: Record<number, Answer>;
  completedSteps: string[];
  regressionWhen?: Record<number, string>;
}
export interface Question {
  id: number;
  en: string;
  zh: string;
  categoryEN: string;
  categoryZH: string;
  yesNo: boolean;
  options?: string[];
  safety?: string;
}
export const emptyData = (): AppData => ({
  version: 1,
  language: "en",
  profile: null,
  records: [],
  answers: {},
  completedSteps: [],
});
export const stages: Record<Stage, [string, string]> = {
  noticed: ["Just noticing differences", "我只是覺得有啲唔對路"],
  professionalFollowUp: [
    "A professional suggested follow-up",
    "母嬰健康院/醫生提過要跟進",
  ],
  awaitingAssessment: ["Referred / awaiting assessment", "已轉介/等緊評估"],
  assessed: ["Assessed, with a report", "已評估，有報告"],
  diagnosed: ["Already diagnosed", "已確診 ASD"],
  registered: ["Registered for services", "已經喺中央轉介系統輪候"],
};
export const categories: Record<Category, [string, string]> = {
  observation: ["Observation", "日常觀察"],
  distress: ["Distress", "情緒困擾"],
  progress: ["Progress", "進步"],
  communication: ["Communication", "溝通"],
  sensory: ["Sensory", "感官"],
  play: ["Play", "遊戲"],
  eating: ["Eating", "飲食"],
};
export const answers: Record<Answer, [string, string]> = {
  varied: ["Several kinds", "幾種都玩"],
  limited: ["Only one or two", "淨係一兩樣"],
  never: ["Never", "從不"],
  rarely: ["Rarely", "少見"],
  sometimes: ["Sometimes", "有時"],
  often: ["Often", "經常"],
  yes: ["Yes", "有"],
  no: ["No", "冇"],
  unsure: ["Not sure", "唔肯定"],
  skipped: ["Skipped", "已略過"],
};
export const needsFollowUp = (a: AppData["answers"]) =>
  [29, 30, 131].some((id) => a[id] === "yes" || a[id] === "unsure");
export const QUESTION_COUNT = 33;
export const needsSafetyRouting = (a: AppData["answers"]) => [132, 133].some(id => a[id] === "yes" || a[id] === "unsure");
export const answeredCount = (a: AppData["answers"]) =>
  Object.entries(a).filter(([id, v]) => Number(id) >= 101 && Number(id) <= 133 && v !== "skipped").length;
export const onboardingDestination = (stage: Stage) =>
  stage === "noticed" ? "questionnaireIntro" : "home";
export function relatedRecords(
  records: Observation[],
  record: Observation,
): Observation[] {
  return records
    .filter(
      (r) =>
        r.id !== record.id &&
        r.category === record.category &&
        r.date <= record.date,
    )
    .sort((a, b) => b.date.localeCompare(a.date))
    .slice(0, 2);
}
export function nextSteps(stage: Stage): [string, string][] {
  if (stage === "noticed" || stage === "professionalFollowUp")
    return [
      ["Write down the changes you notice", "記下你留意到的變化"],
      [
        "Arrange a conversation with your doctor or MCHC",
        "安排與醫生或母嬰健康院討論",
      ],
      ["Bring your questions and observations", "準備問題和觀察記錄"],
    ];
  if (stage === "awaitingAssessment")
    return [
      ["Confirm your assessment appointment", "向中心確認評估預約安排"],
      ["Check which documents to bring", "確認需要攜帶的文件"],
      ["Prepare an observation report", "準備觀察記錄報告"],
    ];
  if (stage === "registered")
    return [
      [
        "Keep your referring professional’s details",
        "保留轉介專業人士的聯絡資料",
      ],
      ["Ask about support while waiting", "了解輪候期間的支援"],
      ["Keep recording everyday observations", "繼續記錄日常觀察"],
    ];
  return [
    ["Discuss the report with your assessment team", "與評估團隊討論報告"],
    ["Ask about suitable service referrals", "了解合適的服務轉介"],
    ["Confirm referral steps and documents", "確認轉介步驟及所需文件"],
  ];
}
export function reportText(
  data: AppData,
  qs: Question[],
  professional: boolean,
): string {
  const zh = data.language === "zh",
    t = (a: string, b: string) => (zh ? b : a),
    p = data.profile;
  const lines = [
    "CareVoice",
    t(
      professional
        ? "Appointment preparation report"
        : "Family observation summary",
      professional ? "會面準備報告" : "家庭觀察摘要",
    ),
    new Date().toLocaleString(zh ? "zh-HK" : "en-HK"),
    "",
  ];
  if (p) {
    lines.push(
      p.nickname || t("Your child", "你的孩子"),
      `${p.ageMonths} ${t("months", "個月")}`,
      t("Parent-selected stage: ", "家長選擇的階段：") +
        stages[p.stage][zh ? 1 : 0],
    );
    if (professional) {
      lines.push(p.firstConcernDate, p.concernNotes);
      if (p.stage === "diagnosed") {
        if (p.diagnosingBody)
          lines.push(
            t(
              "Diagnosing organisation (copied from report): ",
              "診斷機構（按報告填寫）：",
            ) + p.diagnosingBody,
          );
        if (p.diagnosisDate)
          lines.push(t("Report date: ", "報告日期：") + p.diagnosisDate);
        if (p.reportedSupportLevel)
          lines.push(
            t(
              "Support level (copied from report): ",
              "支援程度（按報告填寫）：",
            ) + p.reportedSupportLevel,
          );
      }
    }
  }
  lines.push(
    "",
    t(
      "Parent observations, not a diagnosis or clinical assessment.",
      "家長觀察記錄，並非診斷或臨床評估。",
    ),
    "",
    t("Questionnaire responses", "問卷回答"),
  );
  let legacyHeading = false;
  for (const [index, q] of qs.entries()) {
    if (q.id <= 30 && !legacyHeading) { lines.push("", t("Earlier questionnaire responses (original wording)", "舊版問卷回答（原有題目）")); legacyHeading = true; }
    const a = data.answers[q.id];
    if (a && a !== "skipped")
      lines.push(`${q.id <= 30 ? q.id : index + 1}. ${zh ? q.zh : q.en}`, answers[a][zh ? 1 : 0]);
  }
  if (needsSafetyRouting(data.answers)) lines.push(t("A seizure or self-injury response was Yes or Not sure. Seek medical advice promptly; for immediate danger in Hong Kong call 999 or attend A&E.", "抽搐或傷害自己題目回答為「有」或「唔肯定」。請盡快求醫；如在香港有即時危險，致電 999 或前往急症室。"));
  if (needsFollowUp(data.answers))
    lines.push(
      t(
        "A loss-of-skills response was Yes or Not sure. Discuss this promptly with a qualified professional.",
        "技能退步題目回答為「是」或「不確定」，請盡快與合資格專業人士討論。",
      ),
    );
  for (const id of [29, 30, 131])
    if (
      (data.answers[id] === "yes" || data.answers[id] === "unsure") &&
      data.regressionWhen?.[id]
    )
      lines.push(
        t(`Q${id} — roughly when: `, `第 ${id} 題 — 大約何時：`) +
          data.regressionWhen[id],
      );
  lines.push("", t("Observations", "觀察記錄"));
  for (const r of [...data.records].sort((a, b) =>
    a.date.localeCompare(b.date),
  ))
    lines.push(
      "",
      new Date(r.date).toLocaleString(zh ? "zh-HK" : "en-HK"),
      categories[r.category][zh ? 1 : 0],
      r.text,
      ...[
        [t("Place", "地點"), r.location],
        [t("Duration (min)", "持續（分鐘）"), r.durationMinutes],
        [t("What happened before", "之前發生了甚麼"), r.context],
        [t("What helped", "有幫助的方法"), r.helped],
      ]
        .filter(([, v]) => v !== null && v !== "")
        .map(([k, v]) => `${k}: ${v}`),
    );
  if (!data.records.length)
    lines.push(t("No observations recorded.", "暫無觀察記錄。"));
  if (professional)
    lines.push(
      "",
      t("Questions for the appointment", "會面時希望討論的問題"),
      "_______________________________",
      "_______________________________",
    );
  return lines.join("\n");
}
