import { useEffect, useRef, useState } from "react";
import { Check, X } from "lucide-react";
import type { Language } from "../domain";
import { languageNames, translator } from "../i18n";

export function LanguageSettings({ language, onSave, onClose }: {
  language: Language;
  onSave: (language: Language) => boolean;
  onClose: () => void;
}) {
  const [selected, setSelected] = useState(language);
  const [failed, setFailed] = useState(false);
  const dialog = useRef<HTMLDialogElement>(null);
  const t = translator(language);
  useEffect(() => {
    const previous = document.activeElement as HTMLElement | null;
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const sheet = dialog.current!;
    sheet.showModal();
    sheet.querySelector<HTMLInputElement>("input:checked")?.focus();
    return () => {
      sheet.close();
      document.body.style.overflow = overflow;
      previous?.focus();
    };
  }, []);
  return <dialog ref={dialog} className="sheet compact language-sheet" aria-labelledby="language-title" aria-describedby="language-help" onCancel={onClose}>
    <form onSubmit={event => {
      event.preventDefault();
      if (onSave(selected)) onClose(); else setFailed(true);
    }}>
      <header className="language-heading">
        <h2 id="language-title">{t("App language", "應用程式語言", "应用语言")}</h2>
        <button type="button" className="icon-button" aria-label={t("Close", "關閉", "关闭")} onClick={onClose}><X size={22} /></button>
      </header>
      <p id="language-help">{t("Choose the language you feel most comfortable with.", "選擇你最習慣使用的語言。", "选择你最习惯使用的语言。")}</p>
      <fieldset className="language-options" aria-label={t("Choose a language", "選擇語言", "选择语言")}>
        {(["en", "zh", "zh-Hans"] as Language[]).map(value => <label key={value} className={`language-option${selected === value ? " selected" : ""}`}>
          <input type="radio" name="app-language" value={value} checked={selected === value} onChange={() => { setSelected(value); setFailed(false); }} />
          <span className="language-option-copy"><strong lang={value === "zh" ? "zh-Hant" : value}>{languageNames[value]}</strong>{value !== "en" && <small>{value === "zh" ? "Traditional Chinese" : "Simplified Chinese"}</small>}</span>
          <span className="language-choice-mark" aria-hidden="true">{selected === value && <Check size={17} />}</span>
        </label>)}
      </fieldset>
      <p className="language-note">{t("Your notes and recordings keep their original language.", "你的筆記和錄音會保留原有語言。", "你的笔记和录音会保留原有语言。")}</p>
      {failed && <p className="language-error" role="alert">{t("Could not save your language. Please try again.", "無法儲存語言設定，請再試一次。", "无法保存语言设置，请重试。")}</p>}
      <footer className="language-actions"><button type="button" className="secondary" onClick={onClose}>{t("Cancel", "取消")}</button><button className="primary" type="submit">{t("Save", "儲存", "保存")}</button></footer>
    </form>
  </dialog>;
}
