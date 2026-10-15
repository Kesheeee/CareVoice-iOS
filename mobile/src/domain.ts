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
}
export interface Question {
  id: number;
  en: string;
  zh: string;
  categoryEN: string;
  categoryZH: string;
  yesNo: boolean;
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
  noticed: ["Just noticing differences", "剛留意到一些不同"],
  professionalFollowUp: [
    "A professional suggested follow-up",
    "專業人士建議跟進",
  ],
  awaitingAssessment: ["Referred / awaiting assessment", "已轉介／等候評估"],
  assessed: ["Assessed, with a report", "已完成評估並取得報告"],
  diagnosed: ["Already diagnosed", "已有診斷"],
  registered: ["Registered for services", "已登記輪候服務"],
};
export const categories: Record<Category, [string, string]> = {
  observation: ["Observation", "日常觀察"],
  distress: ["Emotions", "情緒困擾"],
  progress: ["Little wins", "小小進步"],
  communication: ["Communication", "溝通"],
  sensory: ["Sensory", "感官"],
  play: ["Play", "遊戲"],
  eating: ["Eating", "飲食"],
};
export const answers: Record<Answer, [string, string]> = {
  never: ["Never", "從不"],
  rarely: ["Rarely", "少見"],
  sometimes: ["Sometimes", "有時"],
  often: ["Often", "經常"],
  yes: ["Yes", "是"],
  no: ["No", "否"],
  unsure: ["Not sure", "不確定"],
  skipped: ["Skipped", "已略過"],
};
export const needsFollowUp = (a: AppData["answers"]) =>
  [29, 30].some((id) => a[id] === "yes" || a[id] === "unsure");
export const answeredCount = (a: AppData["answers"]) =>
  Object.values(a).filter((v) => v !== "skipped").length;
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
    if (professional) lines.push(p.firstConcernDate, p.concernNotes);
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
  for (const q of qs) {
    const a = data.answers[q.id];
    if (a && a !== "skipped")
      lines.push(`${q.id}. ${zh ? q.zh : q.en}`, answers[a][zh ? 1 : 0]);
  }
  if (needsFollowUp(data.answers))
    lines.push(
      t(
        "A loss-of-skills response was Yes or Not sure. Discuss this promptly with a qualified professional.",
        "技能退步題目回答為「是」或「不確定」，請盡快與合資格專業人士討論。",
      ),
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
