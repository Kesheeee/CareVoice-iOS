import { translator } from "../i18n";
import { useEffect, useRef, useState } from "react";
import { X } from "lucide-react";
import type { Language } from "../domain";
import { SignIn } from "./SignIn";
import { SignInVideo } from "./SignInVideo";
import "../launch.css";

export function LaunchScreen({ language, initialSignIn = false, onContinue, onCloseSignIn }: {
  language: Language;
  initialSignIn?: boolean;
  onContinue: () => void;
  onCloseSignIn: () => void;
}) {
  const t = translator(language);
  const [sheet, setSheet] = useState<"choices" | "email" | "emailEntry" | null>(initialSignIn ? "email" : null);
  const [existing, setExisting] = useState(initialSignIn);
  const [message, setMessage] = useState("");
  const dialog = useRef<HTMLDialogElement>(null);
  const trigger = useRef<HTMLElement | null>(null);
  const open = sheet !== null;
  useEffect(() => {
    if (!open) return;
    const element = dialog.current;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    element?.showModal();
    return () => {
      element?.close();
      document.body.style.overflow = previousOverflow;
      trigger.current?.focus();
    };
  }, [open]);
  useEffect(() => {
    // Announce the new screen without highlighting Back or opening the keyboard.
    dialog.current?.querySelector<HTMLElement>("h1, h2")?.focus({ preventScroll: true });
  }, [sheet]);
  function close() {
    setSheet(null);
    setMessage("");
    if (initialSignIn) onCloseSignIn();
  }
  function start(isExisting: boolean) {
    trigger.current = document.activeElement as HTMLElement;
    setExisting(isExisting);
    setMessage("");
    setSheet(isExisting ? "email" : "choices");
  }
  function continueLocal() {
    setSheet(null);
    onContinue();
  }
  return (
    <>
      <SignInVideo />
      <section className="launch-screen" aria-labelledby="launch-title">
        <div className="launch-copy">
          <h1 id="launch-title">{t("Every little moment.\nA clearer picture.", "每個小小日常，\n都值得被看見。")}</h1>
        </div>
        <div className="launch-actions">
          <button className="primary full" onClick={() => start(false)}>{t("Get started", "開始使用")}</button>
          <button className="launch-account" onClick={() => start(true)}>{t("I already have an account", "我已經有帳戶")}</button>
        </div>
      </section>
      {open && <dialog ref={dialog} className="account-sheet" aria-labelledby={sheet !== "choices" ? "sign-in-title" : "account-sheet-title"}
        onCancel={event => { event.preventDefault(); close(); }}
        onClick={event => { if (event.target === event.currentTarget) {
          const bounds = event.currentTarget.getBoundingClientRect();
          if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) close();
        } }}>
        <div className="account-sheet-handle" aria-hidden="true" />
        {sheet === "choices" && <button className="account-sheet-close" onClick={close} aria-label={t("Close", "關閉")}><X size={20} /></button>}
        {sheet !== "choices" ? <SignIn key={sheet} embedded createAccount={sheet === "emailEntry"} language={language} onBack={() => { setSheet("choices"); setMessage(""); }} onContinue={continueLocal} /> : <div className="account-sheet-content">
          <h2 id="account-sheet-title" tabIndex={-1}>{existing ? t("Welcome back", "歡迎返嚟") : t("Let’s get started", "一齊開始")}</h2>
          <div className="account-providers">
            <button className="account-provider" onClick={() => setMessage(t("Google sign-in is a preview and is not connected yet.", "Google 登入目前只供預覽，暫時未連接。"))}><img className="provider-google" src="/media/google-g.png" width="22" height="22" alt="" />{t("Continue with Google", "使用 Google 繼續")}</button>
            <button className="account-provider" onClick={() => setMessage(t("Apple sign-in is a preview and is not connected yet.", "Apple 登入目前只供預覽，暫時未連接。"))}><svg viewBox="5 3 15 18" width="22" height="22" fill="currentColor" aria-hidden="true"><path d="M17.1 12.3c0-2 1.6-3 1.7-3.1-1-1.4-2.5-1.6-3-1.6-1.3-.1-2.5.8-3.2.8-.6 0-1.6-.8-2.7-.8-1.4 0-2.7.9-3.4 2.1-1.5 2.6-.4 6.5 1 8.6.7 1 1.5 2.1 2.6 2 1-.1 1.5-.7 2.8-.7s1.7.7 2.8.7c1.2 0 1.9-1 2.6-2 .8-1.2 1.2-2.3 1.2-2.4-.1 0-2.4-.9-2.4-3.6ZM15 6.2c.6-.8 1.1-1.8 1-2.9-.9 0-2.1.6-2.7 1.4-.6.6-1.1 1.7-1 2.7 1 .1 2.1-.5 2.7-1.2Z" /></svg>{t("Continue with Apple", "使用 Apple 繼續")}</button>
            <button className="primary full" onClick={() => setSheet("emailEntry")}>{t("Continue with email", "使用電郵繼續")}</button>
          </div>
          {message && <p className="account-provider-status" role="status">{message}</p>}
          <button className="launch-account" onClick={() => { setExisting(true); setSheet("email"); setMessage(""); }}>{t("I already have an account", "我已經有帳戶")}</button>
        </div>}
      </dialog>}
    </>
  );
}
