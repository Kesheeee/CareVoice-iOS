import { useState, type FormEvent } from "react";
import { ArrowLeft, Eye, EyeOff, Mail, LockKeyhole } from "lucide-react";
import { SignInVideo } from "./SignInVideo";
import type { Language } from "../domain";
import "../sign-in.css";

export function SignIn({ language, onBack, onContinue, embedded = false, emailOnly = false }: {
  emailOnly?: boolean;
  embedded?: boolean;
  language: Language;
  onBack: () => void;
  onContinue: () => void;
}) {
  const t = (en: string, zh: string) => language === "zh" ? zh : en;
  const [visible, setVisible] = useState(false);
  const [message, setMessage] = useState("");
  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    event.currentTarget.reset();
    setVisible(false);
    setMessage(emailOnly ? t("Account lookup is not connected yet. Your email has not been sent or saved.", "帳戶查詢暫時未連接。你嘅電郵冇被傳送或儲存。") : t(
      "Account sign-in is not available yet. Your details have not been sent or saved.",
      "帳戶登入暫時未開放。你輸入嘅資料冇被傳送或儲存。",
    ));
  }
  return (
    <>
    {!embedded && <SignInVideo />}
    <section className={`sign-in-screen${emailOnly ? " email-entry-screen" : ""}`} aria-labelledby="sign-in-title">
      <button className="sign-in-back" onClick={onBack}>
        <ArrowLeft size={20} aria-hidden="true" />{t("Back", "返回")}
      </button>
      <header className="sign-in-heading">
        <h1 id="sign-in-title">{emailOnly ? t("Enter your email", "輸入你嘅電郵") : t("Welcome back", "歡迎返嚟")}</h1>
      </header>
      <form onSubmit={submit}>
        <label className="sr-only" htmlFor="sign-in-email">{t("Email", "電郵")}</label>
        <div className="sign-in-field">
        <Mail className="sign-in-field-icon" size={20} aria-hidden="true" />
        <input id="sign-in-email" name="email" type="email" autoComplete="off" inputMode="email" autoCapitalize="none" spellCheck={false} placeholder="you@example.com" required />
        </div>
        {!emailOnly && <><label className="sr-only" htmlFor="sign-in-password">{t("Password", "密碼")}</label>
        <div className="sign-in-password sign-in-field">
          <LockKeyhole className="sign-in-field-icon" size={20} aria-hidden="true" />
          <input id="sign-in-password" name="password" type={visible ? "text" : "password"} placeholder={t("Your password", "你嘅密碼")} autoComplete="off" required />
          <button type="button" aria-label={t(visible ? "Hide password" : "Show password", visible ? "隱藏密碼" : "顯示密碼")} aria-pressed={visible} onClick={() => setVisible(!visible)}>
            {visible ? <EyeOff size={21} aria-hidden="true" /> : <Eye size={21} aria-hidden="true" />}
          </button>
        </div>
        <button className="sign-in-help" type="button" onClick={() => setMessage(t("Password reset will be available when account sign-in launches. No reset email has been sent.", "帳戶登入功能開放後，就可以重設密碼。目前冇發送重設電郵。"))}>{t("Forgot password?", "忘記密碼？")}</button>
        </>}
        <button className="primary full" type="submit">{emailOnly ? t("Continue", "繼續") : t("Sign in", "登入")}</button>
        <p className="sign-in-status" role="status" aria-live="polite">{message}</p>
      </form>
    </section>
    </>
  );
}
