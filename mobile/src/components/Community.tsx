import { ArrowUpRight, Heart, ShieldCheck } from "lucide-react";
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
  const zh = language === "zh",
    t = (en: string, tc: string) => (zh ? tc : en);
  const link = (en: string, tc: string, url: string, source: string) => (
    <a
      className="community-link"
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      key={en}
    >
      <span>
        <strong>{t(en, tc)}</strong>
        <small>{source}</small>
      </span>
      <ArrowUpRight size={18} />
    </a>
  );
  return (
    <>
      <div className="page-heading">
        <h1>{t("Community", "社區")}</h1>
      </div>
      <h2 className="community-section">
        <ShieldCheck size={19} />
        {t("Official resources & support", "官方資源與支援")}
      </h2>
      <div className="community-group">
        {resources.map(([en, tc, url, tcUrl, dept]) =>
          link(
            en,
            tc,
            zh ? tcUrl : url,
            dept === "DH"
              ? t("Department of Health", "衛生署")
              : t("Social Welfare Department", "社會福利署"),
          ),
        )}
      </div>
      <h2 className="community-section">
        <Heart size={19} />
        {t("Support for parents", "家長資源")}
      </h2>
      <div className="community-group">
        {link(
          "Maternal & Child Health Centres",
          "母嬰健康院",
          "https://www.dh.gov.hk/english/main/main_fhs/main_fhs.html",
          t("Department of Health", "衛生署"),
        )}
        {link(
          "On-site pre-school support",
          "到校學前支援",
          "https://www.swd.gov.hk/oprs/index_en.htm",
          t("Social Welfare Department", "社會福利署"),
        )}
      </div>
      <h2 className="community-section">{t("Common questions", "常見問題")}</h2>
      <div className="community-questions">
        <details>
          <summary>
            {t("Where can I discuss my concerns?", "可以向誰提出疑問？")}
          </summary>
          <p>
            {t(
              "Start with your family doctor or Maternal & Child Health Centre. They can discuss your observations and whether a referral is needed.",
              "可先與家庭醫生或母嬰健康院討論你的觀察及轉介需要。",
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
          <summary>
            {t(
              "Does this questionnaire assess my child?",
              "這份問卷會評估孩子嗎？",
            )}
          </summary>
          <p>
            {t(
              "No. It records your observations without scores, diagnosis or a suggested clinical level. Only you choose your journey stage.",
              "不會。問卷只記錄你的觀察，不評分、不作診斷，亦不建議臨床程度。旅程階段只由你選擇。",
            )}
          </p>
        </details>
        <details>
          <summary>
            {t("What can I prepare while waiting?", "輪候期間可以準備甚麼？")}
          </summary>
          <p>
            {t(
              "Keep your observations and questions together. Use your personal checklist and bring a report to your next professional appointment. Confirm service arrangements with your referring professional.",
              "整理日常觀察及問題，使用個人清單，並於會面時帶同記錄報告。服務安排請向轉介專業人士確認。",
            )}
          </p>
        </details>
      </div>
      <p className="fine-print">
        {t(
          "Official links reviewed 15 October 2026. Service providers confirm eligibility and arrangements. External links open in your browser.",
          "官方連結於 2026 年 10 月 15 日核對。服務資格及安排由機構確認，外部連結在瀏覽器開啟。",
        )}
      </p>
    </>
  );
}
