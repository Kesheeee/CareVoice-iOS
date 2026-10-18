import { Check, Circle } from "lucide-react";
import { translator } from "../i18n";
import type { Language } from "../domain";
import { passwordRequirements } from "../platform/password";

export function PasswordRequirements({ password, language }: { password: string; language: Language }) {
  const t = translator(language);
  const rules = passwordRequirements(password);
  const labels = {
    length: t("At least 8 characters", "最少 8 個字元", "至少 8 个字符"),
    uppercase: t("Uppercase letter (A–Z)", "大寫字母 (A–Z)", "大写字母 (A–Z)"),
    lowercase: t("Lowercase letter (a–z)", "小寫字母 (a–z)", "小写字母 (a–z)"),
    number: t("Number (0–9)", "數字 (0–9)", "数字 (0–9)"),
    symbol: t("Symbol (e.g. ! @ #)", "符號（例如 ! @ #）", "符号（例如 ! @ #）"),
  };
  const met = Object.values(rules).filter(Boolean).length;
  return <div id="password-hint" className="password-requirements">
    <ul aria-label={t("Password requirements", "密碼要求", "密码要求")}>
      {(Object.keys(rules) as Array<keyof typeof rules>).map(key => <li key={key} data-met={rules[key]}>
        {rules[key] ? <Check size={15} aria-hidden="true" /> : <Circle size={15} aria-hidden="true" />}
        <span>{labels[key]}<span className="sr-only"> — {rules[key] ? t("Met", "已符合") : t("Not yet met", "未符合")}</span></span>
      </li>)}
    </ul>
    <span className="sr-only" role="status">{t(`${met} of 5 password requirements met.`, `已符合 ${met} 項密碼要求，共 5 項。`, `已符合 ${met} 项密码要求，共 5 项。`)}</span>
  </div>;
}
