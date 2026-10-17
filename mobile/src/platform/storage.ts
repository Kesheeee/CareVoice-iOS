import {
  emptyData,
  type AppData,
  stages,
  categories,
  answers,
  supportGoals,
} from "../domain.ts";
// Keep platform persistence behind this interface. Native secure storage can replace it without UI changes.
export interface DataStore {
  load(): AppData;
  save(data: AppData): void;
  clear(): void;
}
const KEY = "carevoice.mobile.v1";
export function validateData(raw: unknown): AppData {
  const d = raw as AppData;
  if (
    !d ||
    d.version !== 1 ||
    !["en", "zh"].includes(d.language) ||
    !Array.isArray(d.records) ||
    !Array.isArray(d.completedSteps) ||
    !d.completedSteps.every((s) => typeof s === "string") ||
    !d.answers ||
    typeof d.answers !== "object" ||
    Array.isArray(d.answers)
  )
    throw new Error("Invalid CareVoice backup");
  if (
    d.profile &&
    (!Object.hasOwn(stages, d.profile.stage) ||
      typeof d.profile.nickname !== "string" ||
      !Number.isInteger(d.profile.ageMonths) ||
      d.profile.ageMonths < 0 ||
      d.profile.ageMonths > 83 ||
      typeof d.profile.concernNotes !== "string" ||
      !Number.isFinite(Date.parse(d.profile.firstConcernDate)))
  )
    throw new Error("Invalid profile");
  if (d.profile?.supportGoals !== undefined && (!Array.isArray(d.profile.supportGoals) || d.profile.supportGoals.some(goal => typeof goal !== "string" || !Object.hasOwn(supportGoals, goal))))
    throw new Error("Invalid support goals");
  if (
    d.records.some(
      (r) =>
        !r ||
        typeof r.id !== "string" ||
        typeof r.text !== "string" ||
        !Object.hasOwn(categories, r.category) ||
        !Number.isFinite(Date.parse(r.date)) ||
        ![r.location, r.context, r.helped].every(
          (v) => typeof v === "string",
        ) ||
        (r.durationMinutes !== null &&
          (!Number.isFinite(r.durationMinutes) || r.durationMinutes < 0)),
    )
  )
    throw new Error("Invalid observations");
  if (new Set(d.records.map((r) => r.id)).size !== d.records.length)
    throw new Error("Duplicate observation IDs");
  if (
    d.regressionWhen !== undefined &&
    (!d.regressionWhen ||
      typeof d.regressionWhen !== "object" ||
      Array.isArray(d.regressionWhen) ||
      Object.entries(d.regressionWhen).some(
        ([k, v]) => !["29", "30", "131"].includes(k) || typeof v !== "string",
      ))
  )
    throw new Error("Invalid regression notes");
  if (
    d.profile &&
    [
      d.profile.diagnosingBody,
      d.profile.diagnosisDate,
      d.profile.reportedSupportLevel,
    ].some((v) => v !== undefined && typeof v !== "string")
  )
    throw new Error("Invalid report details");
  if (
    Object.entries(d.answers).some(
      ([id, a]) =>
        !/^([1-9]|[12][0-9]|30|10[1-9]|1[12][0-9]|13[0-3])$/.test(id) || !Object.hasOwn(answers, a),
    )
  )
    throw new Error("Invalid answers");
  return d;
}
export const browserStore: DataStore = {
  load() {
    const raw = localStorage.getItem(KEY);
    return raw ? validateData(JSON.parse(raw)) : emptyData();
  },
  save(data) {
    localStorage.setItem(KEY, JSON.stringify(data));
  },
  clear() {
    localStorage.removeItem(KEY);
  },
};
