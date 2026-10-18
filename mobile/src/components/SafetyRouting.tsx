import { translator } from "../i18n";
import { ShieldCheck, Phone, ArrowUpRight } from "lucide-react";
import type { Language } from "../domain";
export function SafetyRouting({ language }: { language: Language }) {
  const zh = language !== "en";
  const t = translator(language);
  return <aside className="notice safety-routing" role="alert" aria-label={t("Safety guidance", "安全指引")}>
    <ShieldCheck size={20} />
    <div>
      <strong>{t("Get medical help", "尋求醫療協助")}</strong>
      <p>{t("You answered Yes or Not sure about seizures or self-injury. If your child is in immediate danger, is seriously injured, or is having a seizure now, stop the questionnaire and seek emergency medical help. In Hong Kong, call 999 or go to A&E.", "你喺抽搐或傷害自己嘅題目揀咗「有」或「唔肯定」。如果小朋友有即時危險、嚴重受傷，或者而家正抽搐，請先停止填問卷，立即尋求緊急醫療協助。在香港，請致電 999 或去急症室。")}</p>
      <a className="safety-call" href="tel:999"><Phone size={17} />{t("Call 999 · Hong Kong emergency", "致電 999 · 香港緊急求助")}</a>
      <a href="https://www.ha.org.hk/visitor/ha_visitor_index.asp?Content_ID=200246&Lang=ENG&Parent_ID=0" target="_blank" rel="noopener noreferrer">{t("Hospital Authority · A&E departments", "醫院管理局 · 急症室")}<ArrowUpRight size={14}/></a>
      <p>{t("If there is no immediate danger, contact your child's doctor promptly to discuss what you noticed. You can leave the questionnaire and return later.", "如果冇即時危險，請盡快聯絡小朋友嘅醫生，講返你留意到嘅情況。你可以先離開問卷，之後再返嚟。")}</p>
      <a href={zh ? "https://www.dhcas.gov.hk/tc/faq.html" : "https://www.dhcas.gov.hk/en/faq.html"} target="_blank" rel="noopener noreferrer">{t("Department of Health · discussing concerns", "衛生署 · 向醫生提出關注")}</a>
      <a href="https://www.hkfsd.gov.hk/eng/source/safety/uambu.htm" target="_blank" rel="noopener noreferrer">{t("Fire Services Department · emergency ambulance", "消防處 · 緊急救護服務")}</a>
      <small>{t("Official sources checked 15 October 2026. Outside Hong Kong, use your local emergency number.", "官方資料已喺 2026 年 10 月 15 日核對。如果唔喺香港，請致電當地緊急求助電話。")}</small>
    </div>
  </aside>;
}
