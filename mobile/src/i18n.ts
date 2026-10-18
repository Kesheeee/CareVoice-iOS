import { Converter } from "opencc-js/t2cn";
import type { Language } from "./domain.ts";

let simplify: ((text: string) => string) | undefined;
// Convert interface copy only. Never convert saved caregiver notes or names.
export function translator(language: Language) {
  return (en: string, traditional: string, simplified?: string): string => {
    if (language === "en") return en;
    if (language === "zh") return traditional;
    if (simplified !== undefined) return simplified;
    simplify ??= Converter({ from: "hk", to: "cn" });
    return simplify(traditional);
  };
}

export const languageNames: Record<Language, string> = {
  en: "English", zh: "繁體中文", "zh-Hans": "简体中文",
};
export const languageLocale = (language: Language) =>
  language === "en" ? "en-HK" : language === "zh" ? "zh-HK" : "zh-CN";
