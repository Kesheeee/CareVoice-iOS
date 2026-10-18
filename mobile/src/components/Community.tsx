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
  const zh = language !== "en",
    t = translator(language);
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
      <h2 className="community-section">
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
